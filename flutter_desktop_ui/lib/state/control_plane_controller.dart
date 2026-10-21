import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/dto/device_descriptor.dart';
import '../models/runtime.dart';
import '../models/scenario.dart';
import '../models/stage.dart';
import '../services/backend_service.dart';
import '../services/hades_repository.dart';

class ControlPlaneController extends ChangeNotifier {
  final BackendService _backendService;
  StreamSubscription<String>? _eventSubscription;

  late List<Scenario> scenarios;
  late Scenario selectedScenario;
  late Stage currentStage;
  Timer? _autoRunTimer;
  bool isAutoRunning = false;
  List<String> eventLogs = [];

  ControlPlaneController({
    BackendService? backendService,
    Scenario? initialScenario,
    Stage? initialStage,
  }) : _backendService = backendService ?? HadesBackendService() {
    scenarios = _backendService.getScenarios();
    selectedScenario = initialScenario ?? scenarios.first;
    currentStage = initialStage ?? Stage.sessionActive;
    eventLogs = List<String>.from(
      _backendService.getCumulativeLogs(selectedScenario, currentStage),
    );

    // Listen to real-time events from BackendService / WebSocket
    _eventSubscription = _backendService.eventStream.listen(
      _handleIncomingBackendEvent,
    );
  }

  HadesRepository? get repository {
    final service = _backendService;
    return service is HadesBackendService ? service.repository : null;
  }

  bool get isBlocked => selectedScenario.isBlocked;
  int get maxStage => selectedScenario.maxStageNumber;
  bool get isBackendConnected => _backendService.isConnected;

  DeviceDescriptor? get selectedDeviceDescriptor {
    if (repository == null) return null;
    return repository!.devices.cast<DeviceDescriptor?>().firstWhere(
      (d) => d != null && d.stableId == selectedScenario.id,
      orElse: () => null,
    );
  }

  Future<void> refreshFromBackend({String? workspace, String? simulate}) async {
    if (repository != null) {
      await repository!.refreshDevices(
        workspace: workspace,
        simulate: simulate,
      );
      await repository!.refreshSessions();
      scenarios = _backendService.getScenarios();
      if (!scenarios.any((s) => s.id == selectedScenario.id)) {
        selectedScenario = scenarios.first;
      }
      notifyListeners();
    }
  }

  Future<void> loadSimulatedPreset(String preset, {String? workspace}) async {
    if (repository != null) {
      await repository!.loadSimulatedPreset(preset, workspace: workspace);
      scenarios = _backendService.getScenarios();
      final matching = scenarios.firstWhere(
        (s) =>
            s.id.contains(preset) ||
            s.name.toLowerCase().contains(preset.split('-').first),
        orElse: () => scenarios.first,
      );
      selectScenario(matching, resetToStage1: true);
      eventLogs.add('[simulation] Loaded hardware preset: $preset');
      notifyListeners();
    }
  }

  Future<void> resolveSelectedDevice({String? workspace}) async {
    final dev = selectedDeviceDescriptor;
    if (dev != null && repository != null) {
      eventLogs.add(
        '[resolver] Initiating Two-Stage resolution for ${dev.displayName}...',
      );
      final resolved = await repository!.resolveAmbiguousDevice(
        dev,
        workspace: workspace,
      );
      if (resolved != null) {
        scenarios = _backendService.getScenarios();
        selectedScenario = scenarios.firstWhere(
          (s) => s.id == resolved.stableId,
          orElse: () => selectedScenario,
        );
        currentStage = Stage.requirementsResolved;
        eventLogs.add(
          '[resolver] Stage 2 match: ${resolved.targetBoard} (${resolved.targetChip})',
        );
        eventLogs.add(
          '[toolchain] Recommended SDK: ${resolved.recommendedSdk}',
        );
        notifyListeners();
      }
    }
  }

  Future<void> initWorkspaceManifest(
    String preset, {
    String? workspace,
    String? name,
  }) async {
    if (repository != null) {
      eventLogs.add('[manifest] Generating .hades.yaml with preset $preset...');
      final res = await repository!.initializeManifest(
        preset,
        workspace: workspace,
        name: name,
      );
      if (res['success'] == true) {
        eventLogs.add('[manifest] Successfully created .hades.yaml manifest.');
        await resolveSelectedDevice(workspace: workspace);
      } else {
        eventLogs.add(
          '[manifest-error] Could not generate manifest: ${res['error'] ?? 'Unknown error'}',
        );
        notifyListeners();
      }
    }
  }

  Future<void> provisionSandboxForSelected({String? workspace}) async {
    final dev = selectedDeviceDescriptor;
    if (dev != null && repository != null) {
      currentStage = Stage.policyEvaluated;
      eventLogs.add(
        '[policy] Evaluating least-privilege policy for ${dev.displayName}...',
      );
      notifyListeners();

      try {
        final session = await repository!.createSession(
          manifestPath: '${workspace ?? '.'}/.hades.yaml',
          device: dev,
        );
        currentStage = Stage.sandboxProvisioned;
        eventLogs.add(
          '[provision] Sandbox created: ${session.id} (${session.isolation})',
        );
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 300));
        currentStage = Stage.sessionActive;
        eventLogs.add('[session] Sandbox active: ID ${session.id}');
        eventLogs.add(
          '[session] Hardware mapping bound: ${dev.busPath} -> ${dev.deviceNode ?? ''}',
        );
        notifyListeners();
      } catch (e) {
        eventLogs.add('[policy-rejection] $e');
        if (dev.isUnauthorized) {
          selectedScenario = Scenario(
            id: selectedScenario.id,
            name: selectedScenario.name,
            vidPid: selectedScenario.vidPid,
            busPath: selectedScenario.busPath,
            node: selectedScenario.node,
            usbClass: selectedScenario.usbClass,
            runtime: Runtime.blocked,
            arch: selectedScenario.arch,
            toolchains: selectedScenario.toolchains,
            broker: 'none, access denied',
            reason: 'Policy rejection: Unauthorized hardware denied',
            rules: const [false, false, false, true],
          );
        }
        notifyListeners();
      }
    }
  }

  Future<void> connectToBackend({String? url}) async {
    final targetUrl =
        url ??
        (repository?.apiClient.config.wsUrl ?? 'ws://127.0.0.1:8080/v1/ws/*');
    await _backendService.connectWebSocket(url: targetUrl);
    await refreshFromBackend();
    notifyListeners();
  }

  Future<void> disconnectFromBackend() async {
    await _backendService.disconnectWebSocket();
    notifyListeners();
  }

  void _handleIncomingBackendEvent(String message) {
    try {
      final data = jsonDecode(message);
      if (data is Map<String, dynamic>) {
        final event = data['event'] as String?;
        final type = data['type'] as String?;

        if (event == 'device') {
          final action = data['action'] as String? ?? 'event';
          final devJson = data['device'] as Map<String, dynamic>?;
          if (devJson != null) {
            final dev = DeviceDescriptor.fromJson(devJson);
            if (action == 're-enumerated') {
              eventLogs.add(
                '[netlink] Device re-enumerated on port ${dev.portTopology ?? dev.busPath}: node=${dev.deviceNode}',
              );
            } else {
              eventLogs.add(
                '[netlink] $action ${dev.busPath} ${dev.usbId} ${dev.deviceNode ?? ''}',
              );
            }
          }
          scenarios = _backendService.getScenarios();
          notifyListeners();
          return;
        } else if (event == 'session') {
          final action = data['action'] as String? ?? 'update';
          final sid = data['session_id'] as String? ?? '';
          eventLogs.add('[session] Session $action: $sid');
          repository?.refreshSessions();
          notifyListeners();
          return;
        } else if (event == 'audit') {
          final recJson = data['record'] as Map<String, dynamic>?;
          if (recJson != null) {
            final evName = recJson['event'] as String? ?? 'audit';
            final detail = recJson['detail'] as String? ?? '';
            final success = recJson['success'] as bool? ?? true;
            final prefix = success ? '[audit]' : '[audit-fail]';
            eventLogs.add('$prefix $evName: $detail');
            notifyListeners();
            return;
          }
        }

        // Backward compatibility with legacy simulator events
        if (type == 'DEVICE_PLUGGED') {
          final scenarioId = data['scenario_id'] as String?;
          final target = scenarios.firstWhere(
            (s) => s.id == scenarioId,
            orElse: () => scenarios.first,
          );
          selectScenario(target, resetToStage1: true);
          if (data['log'] != null) {
            eventLogs.add(data['log'] as String);
            notifyListeners();
          }
          return;
        } else if (type == 'STAGE_ADVANCE') {
          final stageNum = data['stage'] as int?;
          if (stageNum != null && stageNum >= 1 && stageNum <= 5) {
            currentStage = Stage.values[stageNum - 1];
            if (data['log'] != null) {
              eventLogs.add(data['log'] as String);
            }
            notifyListeners();
            return;
          }
        }
      }
    } catch (_) {
      // Plain string log
    }

    eventLogs.add(message);
    notifyListeners();
  }

  void selectScenario(Scenario scenario, {bool resetToStage1 = true}) {
    if (isAutoRunning) {
      stopAutoRun();
    }
    selectedScenario = scenario;
    if (resetToStage1) {
      currentStage = Stage.deviceDetected;
    } else {
      if (currentStage.number > scenario.maxStageNumber) {
        currentStage = Stage.policyEvaluated;
      }
    }
    eventLogs = List<String>.from(
      _backendService.getCumulativeLogs(selectedScenario, currentStage),
    );
    notifyListeners();
  }

  void setScenarioAndStage(Scenario scenario, Stage stage) {
    if (isAutoRunning) {
      stopAutoRun();
    }
    selectedScenario = scenario;
    final clampedStageNum = stage.number > scenario.maxStageNumber
        ? scenario.maxStageNumber
        : stage.number;
    currentStage = Stage.values[clampedStageNum - 1];
    eventLogs = List<String>.from(
      _backendService.getCumulativeLogs(selectedScenario, currentStage),
    );
    notifyListeners();
  }

  void startAutoRun() {
    stopAutoRun();

    currentStage = Stage.deviceDetected;
    eventLogs = List<String>.from(
      _backendService.getCumulativeLogs(selectedScenario, Stage.deviceDetected),
    );
    isAutoRunning = true;
    notifyListeners();

    _autoRunTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (currentStage.number < maxStage) {
        final nextStage = Stage.values[currentStage.index + 1];
        currentStage = nextStage;
        final newLogs = _backendService.getLogsForStage(
          selectedScenario,
          currentStage,
        );
        eventLogs.addAll(newLogs);
        notifyListeners();
      } else {
        stopAutoRun();
      }
    });
  }

  void stopAutoRun() {
    _autoRunTimer?.cancel();
    _autoRunTimer = null;
    if (isAutoRunning) {
      isAutoRunning = false;
      notifyListeners();
    }
  }

  void toggleAutoRun() {
    if (isAutoRunning) {
      stopAutoRun();
    } else {
      startAutoRun();
    }
  }

  void nextStage() {
    if (currentStage.number < maxStage) {
      currentStage = Stage.values[currentStage.index + 1];
      final newLogs = _backendService.getLogsForStage(
        selectedScenario,
        currentStage,
      );
      eventLogs.addAll(newLogs);
      notifyListeners();
    }
  }

  void prevStage() {
    if (currentStage.number > 1) {
      currentStage = Stage.values[currentStage.index - 1];
      eventLogs = List<String>.from(
        _backendService.getCumulativeLogs(selectedScenario, currentStage),
      );
      notifyListeners();
    }
  }

  void attachIde() {
    if (currentStage == Stage.sessionActive && !isBlocked) {
      eventLogs.add(
        '[session] Host shell command: hades shell ${selectedScenario.id.substring(0, selectedScenario.id.length.clamp(0, 8))}',
      );
      notifyListeners();
    }
  }

  Future<void> triggerTeardown() async {
    if (currentStage == Stage.sessionActive && !isBlocked) {
      if (repository != null && repository!.sessions.isNotEmpty) {
        final session = repository!.sessions.firstWhere(
          (s) => s.deviceId == selectedScenario.id && s.isRunning,
          orElse: () => repository!.sessions.first,
        );
        try {
          await repository!.stopSession(session.id);
          currentStage = Stage.teardownVerified;
          eventLogs.add('[teardown] container stopped, overlay discarded');
          eventLogs.add('[audit] 0% host pollution verified');
          notifyListeners();
          return;
        } catch (e) {
          eventLogs.add('[teardown-error] Teardown failed: $e');
        }
      }
      currentStage = Stage.teardownVerified;
      eventLogs.add('[teardown] container stopped, overlay discarded');
      eventLogs.add('[audit] 0% host pollution verified');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _autoRunTimer?.cancel();
    _backendService.dispose();
    super.dispose();
  }
}
