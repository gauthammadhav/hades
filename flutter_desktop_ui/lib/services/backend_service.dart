import 'dart:async';
import 'dart:io';
import '../models/scenario.dart';
import '../models/stage.dart';
import 'hades_repository.dart';

abstract class BackendService {
  Stream<String> get eventStream;
  List<Scenario> getScenarios();
  List<String> getLogsForStage(Scenario scenario, Stage stage);
  List<String> getCumulativeLogs(Scenario scenario, Stage stage);
  Future<void> connectWebSocket({String url = 'ws://127.0.0.1:8000/ws/events'});
  Future<void> disconnectWebSocket();
  bool get isConnected;
  void dispose();
}

class MockBackendService implements BackendService {
  final StreamController<String> _eventController =
      StreamController<String>.broadcast();
  WebSocket? _webSocket;
  bool _isConnected = false;

  @override
  Stream<String> get eventStream => _eventController.stream;

  @override
  List<Scenario> getScenarios() => Scenario.mockScenarios;

  @override
  bool get isConnected => _isConnected;

  @override
  List<String> getLogsForStage(Scenario scenario, Stage stage) {
    if (scenario.id == 'esp32_s3') {
      switch (stage) {
        case Stage.deviceDetected:
          return [
            '[netlink] add ${scenario.busPath} ${scenario.vidPid} ${scenario.node}',
            '[pyudev] class: ${scenario.usbClass}',
          ];
        case Stage.requirementsResolved:
          return [
            '[manifest] .hades.yaml matched, arch=${scenario.arch}',
            '[toolchain] resolved: ${scenario.toolchains.join(', ')}',
          ];
        case Stage.policyEvaluated:
          return [
            '[policy] ALLOW -> DOCKER_CONTAINER',
            '[broker] ${scenario.broker}',
          ];
        case Stage.sandboxProvisioned:
          return ['[fs] overlay mounted /workspace'];
        case Stage.sessionActive:
          return [
            '[session] IDE attached',
            '[teardown] overlay discarded',
            '[audit] host pollution: 0%',
          ];
        case Stage.teardownVerified:
          return [
            '[teardown] container stopped, overlay discarded',
            '[audit] 0% host pollution verified',
          ];
      }
    } else if (scenario.id == 'can_module') {
      switch (stage) {
        case Stage.deviceDetected:
          return [
            '[netlink] add ${scenario.busPath} ${scenario.vidPid} ${scenario.node}',
          ];
        case Stage.requirementsResolved:
          return [
            '[pyudev] class: ${scenario.usbClass}',
            '[manifest] .hades.yaml matched, arch=${scenario.arch}',
          ];
        case Stage.policyEvaluated:
          return ['[policy] ALLOW -> QEMU_KVM_VM'];
        case Stage.sandboxProvisioned:
          return [
            '[broker] libvirt hostdev hotplug attached',
            '[qemu] booting guest kernel',
          ];
        case Stage.sessionActive:
          return [
            '[session] IDE attached via hades attach',
            '[teardown] overlay discarded, device released',
            '[audit] host pollution: 0%',
          ];
        case Stage.teardownVerified:
          return [
            '[teardown] VM stopped, overlay discarded',
            '[audit] 0% host pollution verified',
          ];
      }
    } else {
      // Unauthorized USB Attack
      switch (stage) {
        case Stage.deviceDetected:
          return [
            '[netlink] add ${scenario.busPath} ${scenario.vidPid} ${scenario.node}',
          ];
        case Stage.requirementsResolved:
          return [
            '[pyudev] class: ${scenario.usbClass}',
            '[manifest] .hades.yaml matched, arch=-',
          ];
        case Stage.policyEvaluated:
          return ['[policy] DENY HID (0x03): ${scenario.reason}'];
        default:
          return [];
      }
    }
  }

  @override
  List<String> getCumulativeLogs(Scenario scenario, Stage stage) {
    if (scenario.id == 'esp32_s3' && stage == Stage.sessionActive) {
      return [
        '[policy] ALLOW -> DOCKER_CONTAINER',
        '[broker] cgroup device allow, no --privileged',
        '[fs] overlay mounted /workspace',
        '[session] IDE attached',
        '[teardown] overlay discarded',
        '[audit] host pollution: 0%',
      ];
    }

    if (scenario.id == 'can_module' && stage == Stage.policyEvaluated) {
      return [
        '[netlink] add usb 1-4 1D50:606F /dev/bus/usb/001/007',
        '[pyudev] class: Vendor specific (0xFF)',
        '[manifest] .hades.yaml matched, arch=arm-none-eabi',
        '[policy] ALLOW -> QEMU_KVM_VM',
      ];
    }

    if (scenario.id == 'unauthorized_hid' && stage == Stage.policyEvaluated) {
      return [
        '[netlink] add usb 1-3 0951:1666 /dev/input/event7',
        '[pyudev] class: HID (0x03)',
        '[manifest] .hades.yaml matched, arch=-',
        '[policy] DENY HID (0x03): HID/mass storage not approved',
      ];
    }

    final logs = <String>[];
    for (final s in Stage.values) {
      if (s.number > stage.number) break;
      logs.addAll(getLogsForStage(scenario, s));
    }
    return logs;
  }

  @override
  Future<void> connectWebSocket({
    String url = 'ws://127.0.0.1:8000/ws/events',
  }) async {
    try {
      _webSocket = await WebSocket.connect(
        url,
      ).timeout(const Duration(seconds: 4));
      _isConnected = true;
      _eventController.add('[websocket] Connected to $url');

      _webSocket!.listen(
        (data) {
          _eventController.add(data.toString());
        },
        onError: (error) {
          _isConnected = false;
          _eventController.add('[websocket] Connection error: $error');
        },
        onDone: () {
          _isConnected = false;
          _eventController.add('[websocket] Disconnected from server');
        },
      );
    } catch (e) {
      _isConnected = false;
      _eventController.add('[websocket] Could not connect to $url ($e)');
    }
  }

  @override
  Future<void> disconnectWebSocket() async {
    await _webSocket?.close();
    _webSocket = null;
    _isConnected = false;
    _eventController.add('[websocket] Disconnected by user');
  }

  @override
  void dispose() {
    _webSocket?.close();
    _eventController.close();
  }
}

class HadesBackendService implements BackendService {
  final HadesRepository repository;

  HadesBackendService({HadesRepository? repository})
    : repository = repository ?? HadesRepository();

  @override
  Stream<String> get eventStream => repository.logStream;

  @override
  List<Scenario> getScenarios() => repository.toScenarios();

  @override
  bool get isConnected => repository.wsClient.isConnected;

  @override
  List<String> getLogsForStage(Scenario scenario, Stage stage) {
    final audits = repository.getCachedAudit(scenario.id);
    if (audits.isNotEmpty) {
      return audits.map((a) => a.toFormattedLog()).toList();
    }
    return MockBackendService().getLogsForStage(scenario, stage);
  }

  @override
  List<String> getCumulativeLogs(Scenario scenario, Stage stage) {
    final audits = repository.getCachedAudit(scenario.id);
    if (audits.isNotEmpty) {
      return audits.map((a) => a.toFormattedLog()).toList();
    }
    return MockBackendService().getCumulativeLogs(scenario, stage);
  }

  @override
  Future<void> connectWebSocket({
    String url = 'ws://127.0.0.1:8080/v1/ws/*',
  }) async {
    await repository.wsClient.connect(customUrl: url);
  }

  @override
  Future<void> disconnectWebSocket() async {
    await repository.wsClient.disconnect();
  }

  @override
  void dispose() {
    repository.dispose();
  }
}
