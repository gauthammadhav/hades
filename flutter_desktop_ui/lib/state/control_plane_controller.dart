import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/scenario.dart';
import '../models/stage.dart';
import '../services/backend_service.dart';

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
  }) : _backendService = backendService ?? MockBackendService() {
    scenarios = _backendService.getScenarios();
    selectedScenario = initialScenario ?? scenarios.first;
    currentStage = initialStage ?? Stage.sessionActive;
    eventLogs = List<String>.from(
      _backendService.getCumulativeLogs(selectedScenario, currentStage),
    );

    // Listen to real-time events from BackendService / WebSocket
    _eventSubscription = _backendService.eventStream.listen(_handleIncomingBackendEvent);
  }

  bool get isBlocked => selectedScenario.isBlocked;
  int get maxStage => selectedScenario.maxStageNumber;
  bool get isBackendConnected => _backendService.isConnected;

  Future<void> connectToBackend({String url = 'ws://127.0.0.1:8000/ws/events'}) async {
    await _backendService.connectWebSocket(url: url);
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
        final type = data['type'] as String?;
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
      // Message is plain string log
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
    final clampedStageNum = stage.number > scenario.maxStageNumber ? scenario.maxStageNumber : stage.number;
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
        final newLogs = _backendService.getLogsForStage(selectedScenario, currentStage);
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
      final newLogs = _backendService.getLogsForStage(selectedScenario, currentStage);
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
      eventLogs.add('[session] Terminal / IDE attached via hades attach');
      notifyListeners();
    }
  }

  void triggerTeardown() {
    if (currentStage == Stage.sessionActive && !isBlocked) {
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
