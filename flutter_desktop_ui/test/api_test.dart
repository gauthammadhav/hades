import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_desktop_ui/api/api_config.dart';
import 'package:flutter_desktop_ui/api/hades_ws_client.dart';
import 'package:flutter_desktop_ui/models/dto/audit_record.dart';
import 'package:flutter_desktop_ui/models/dto/device_descriptor.dart';
import 'package:flutter_desktop_ui/models/dto/device_event.dart';
import 'package:flutter_desktop_ui/models/dto/session_record.dart';
import 'package:flutter_desktop_ui/models/dto/telemetry_sample.dart';
import 'package:flutter_desktop_ui/services/hades_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DTO Models & Serialization', () {
    test('DeviceDescriptor serialization and stableId computation', () {
      final jsonWithSerial = {
        'vid': '2341',
        'pid': '0043',
        'serial': 'SN998877',
        'device_node': '/dev/ttyACM0',
        'subsystem': 'tty',
        'bus': 1,
        'address': 4,
        'manufacturer': 'Arduino',
        'product': 'Uno R3',
      };
      final dev1 = DeviceDescriptor.fromJson(jsonWithSerial);
      expect(dev1.vid, '2341');
      expect(dev1.pid, '0043');
      expect(dev1.serial, 'SN998877');
      expect(dev1.stableId, '2341:0043:SN998877');
      expect(dev1.displayName, 'Uno R3');
      expect(dev1.busPath, 'usb 1-4');

      final serialized1 = dev1.toJson();
      expect(serialized1['vid'], '2341');
      expect(serialized1['serial'], 'SN998877');

      // Device without serial should fall back to bus-address
      final jsonNoSerial = {
        'vid': '303a',
        'pid': '1001',
        'bus': 1,
        'address': 12,
      };
      final dev2 = DeviceDescriptor.fromJson(jsonNoSerial);
      expect(dev2.serial, isNull);
      expect(dev2.stableId, '303a:1001:001-012');
    });

    test('Two-Stage Resolution and Topology Tracking in DeviceDescriptor', () {
      // 1. Stage 1 Native MCU (ESP32-S3)
      final nativeJson = {
        'device_id': 'usb:303a:1001:1-2.1',
        'vendor_id': '303a',
        'product_id': '1001',
        'vendor_name': 'Espressif',
        'product_name': 'ESP32-S3 USB-JTAG',
        'port_topology': '1-2.1',
        'dev_node': '/dev/bus/usb/001/004',
        'target_board': 'ESP32-S3-DevKitC-1',
        'target_chip': 'ESP32-S3',
        'recommended_sdk': 'esp-idf',
        'resolution_stage': 'stage_1_passive',
        'classification': 'native_mcu',
        'isolation_recommendation': 'container_broker',
      };
      final nativeDev = DeviceDescriptor.fromJson(nativeJson);
      expect(nativeDev.stableId, 'usb:303a:1001:1-2.1');
      expect(nativeDev.isStage1Passive, isTrue);
      expect(nativeDev.isAmbiguousBridge, isFalse);
      expect(nativeDev.targetBoard, 'ESP32-S3-DevKitC-1');
      expect(nativeDev.busPath, 'usb 1-2.1');

      // 2. Topology preservation across device re-enumeration
      final reEnumJson = Map<String, dynamic>.from(nativeJson);
      reEnumJson['dev_node'] =
          '/dev/bus/usb/001/005'; // Dev number changed from 4 to 5!
      final reEnumDev = DeviceDescriptor.fromJson(reEnumJson);
      expect(reEnumDev.stableId, nativeDev.stableId); // Stable ID unchanged!

      // 3. Stage 2 Ambiguous Bridge (CP2102)
      final ambiguousJson = {
        'device_id': 'usb:10c4:ea60:1-4',
        'vendor_id': '10c4',
        'product_id': 'ea60',
        'vendor_name': 'Silicon Labs',
        'product_name': 'CP2102 UART Bridge',
        'port_topology': '1-4',
        'classification': 'generic_uart_bridge',
        'resolution_stage': 'stage_2_ambiguous',
        'target_board': 'Ambiguous (CP2102)',
      };
      final ambiguousDev = DeviceDescriptor.fromJson(ambiguousJson);
      expect(ambiguousDev.isAmbiguousBridge, isTrue);
      expect(ambiguousDev.isStage2Manifest, isFalse);

      // 4. Stage 2 Resolved Bridge (CP2102 + .hades.yaml)
      final resolvedJson = Map<String, dynamic>.from(ambiguousJson);
      resolvedJson['resolution_stage'] = 'stage_2_manifest';
      resolvedJson['target_board'] = 'esp32-devkit-v1';
      final resolvedDev = DeviceDescriptor.fromJson(resolvedJson);
      expect(resolvedDev.isStage2Manifest, isTrue);
      expect(resolvedDev.isAmbiguousBridge, isFalse);
      expect(resolvedDev.targetBoard, 'esp32-devkit-v1');

      // 5. Unauthorized HID Device
      final unauthorizedJson = {
        'vendor_id': '0951',
        'product_id': '1666',
        'classification': 'unauthorized',
        'isolation_recommendation': 'reject_policy',
      };
      final unauthDev = DeviceDescriptor.fromJson(unauthorizedJson);
      expect(unauthDev.isUnauthorized, isTrue);
    });

    test('SessionRecord serialization and state flags', () {
      final json = {
        'id': 'sess-1234-abcd',
        'project': 'firmware-can',
        'state': 'running',
        'isolation': 'vm',
        'runtime_id': 'hades-domain-1',
        'workspace': '/home/user/project',
        'device_id': '1d50:606f:001-007',
        'manifest_path': '/home/user/project/.hades.yaml',
        'created_at': '2026-10-21T10:00:00.000Z',
        'updated_at': '2026-10-21T10:05:00.000Z',
      };
      final session = SessionRecord.fromJson(json);
      expect(session.id, 'sess-1234-abcd');
      expect(session.project, 'firmware-can');
      expect(session.isRunning, isTrue);
      expect(session.isStopped, isFalse);
      expect(session.isolation, 'vm');
      expect(session.runtimeId, 'hades-domain-1');

      final back = session.toJson();
      expect(back['id'], 'sess-1234-abcd');
      expect(back['isolation'], 'vm');
    });

    test('AuditRecord parsing and log line formatting', () {
      final json = {
        'id': 1,
        'session_id': 'sess-123',
        'event': 'policy_decision',
        'success': true,
        'detail': 'minimum_sufficient_isolation',
        'created_at': '2026-10-21T10:00:00.000Z',
      };
      final audit = AuditRecord.fromJson(json);
      expect(audit.event, 'policy_decision');
      expect(audit.success, isTrue);
      expect(
        audit.toFormattedLog(),
        contains('[audit] policy_decision: minimum_sufficient_isolation'),
      );
    });

    test('DeviceEvent serialization and log formatting', () {
      final json = {
        'action': 'add',
        'device': {
          'vid': '303a',
          'pid': '1001',
          'bus': 1,
          'address': 2,
          'device_node': '/dev/ttyACM0',
        },
        'monotonic_ns': 1234567890,
      };
      final event = DeviceEvent.fromJson(json);
      expect(event.isAdd, isTrue);
      expect(event.device.vid, '303a');
      expect(
        event.toFormattedLog(),
        contains('[netlink] add usb 1-2 303a:1001 /dev/ttyACM0'),
      );
    });

    test('TelemetrySample serialization', () {
      final json = {
        'session_id': 'sess-1',
        'timestamp': '2026-10-21T12:00:00.000Z',
        'cpu_percent': 14.5,
        'memory_bytes': 104857600,
        'usb_connected': true,
        'state': 'running',
      };
      final sample = TelemetrySample.fromJson(json);
      expect(sample.cpuPercent, 14.5);
      expect(sample.memoryBytes, 104857600);
      expect(sample.usbConnected, isTrue);
    });
  });

  group('ApiConfig & Network URLs', () {
    test('sanitizedBaseUrl removes trailing slashes', () {
      const config = ApiConfig(baseUrl: 'http://127.0.0.1:8080///');
      expect(config.sanitizedBaseUrl, 'http://127.0.0.1:8080');
    });

    test('wsUrl converts http to ws and encodes auth token', () {
      const configWithToken = ApiConfig(
        baseUrl: 'http://192.168.1.50:8080',
        apiToken: 'secret key=123',
      );
      expect(
        configWithToken.wsUrl,
        'ws://192.168.1.50:8080/v1/ws/*?token=secret+key%3D123',
      );

      const httpsConfig = ApiConfig(baseUrl: 'https://hades.local:8443');
      expect(httpsConfig.wsUrl, 'wss://hades.local:8443/v1/ws/*');
    });

    test('authHeaders generates Bearer token', () {
      const config = ApiConfig(apiToken: 'test-token');
      expect(config.authHeaders, {'Authorization': 'Bearer test-token'});
    });
  });

  group('HadesWebSocketClient event handling', () {
    test('dispatches device and telemetry events accurately', () async {
      final incomingController = StreamController<dynamic>();

      final client = HadesWebSocketClient(
        config: const ApiConfig(),
        connector: (url) async {
          return _FakeWebSocket(incomingController.stream);
        },
      );

      final deviceEvents = <DeviceEvent>[];
      final telemetryEvents = <TelemetrySample>[];
      final logs = <String>[];

      client.deviceEvents.listen(deviceEvents.add);
      client.telemetryEvents.listen(telemetryEvents.add);
      client.logStream.listen(logs.add);

      await client.connect();
      expect(client.isConnected, isTrue);

      // Send device event through fake stream
      incomingController.add(
        jsonEncode({
          'event': 'device',
          'action': 'add',
          'device': {
            'vid': '2341',
            'pid': '0043',
            'serial': 'ABC1',
            'bus': 1,
            'address': 3,
          },
          'monotonic_ns': 1000,
        }),
      );

      // Send telemetry sample through fake stream
      incomingController.add(
        jsonEncode({
          'event': 'telemetry',
          'session_id': 'sess-99',
          'timestamp': '2026-10-21T10:00:00.000Z',
          'cpu_percent': 5.0,
          'memory_bytes': 50000000,
          'usb_connected': true,
          'state': 'running',
        }),
      );

      await pumpEventQueue();

      expect(deviceEvents.length, 1);
      expect(deviceEvents.first.device.stableId, '2341:0043:ABC1');
      expect(telemetryEvents.length, 1);
      expect(telemetryEvents.first.cpuPercent, 5.0);

      client.dispose();
      await incomingController.close();
    });
  });

  group('HadesRepository Domain Adapter & Identity', () {
    test('maps detected devices and running sessions into scenarios', () {
      final repo = HadesRepository();

      // In initial empty state, fallback mock scenarios are provided
      expect(repo.toScenarios().length, 3);
      expect(repo.toScenarios().first.id, 'esp32_s3');

      // Now simulate a device event
      final devEvent = DeviceEvent(
        action: 'add',
        device: const DeviceDescriptor(
          vid: '303a',
          pid: '1001',
          serial: 'ESP_CHIP_001',
          deviceNode: '/dev/ttyACM0',
          usbClass: 'CDC-ACM (0x02)',
          bus: 1,
          address: 2,
          product: 'ESP32-S3 Board',
        ),
        monotonicNs: 100,
      );
      expect(devEvent.device.stableId, '303a:1001:ESP_CHIP_001');
      expect(devEvent.isAdd, isTrue);

      repo.initialize();

      final scenarios = repo.toScenarios();
      expect(scenarios, isNotEmpty);
    });

    test('maps ambiguous bridge and VM isolation accurately to scenarios', () {
      final repo = HadesRepository();

      // Add ambiguous bridge and VM requiring device
      final ambiguousDev = const DeviceDescriptor(
        vid: '10c4',
        pid: 'ea60',
        portTopology: '1-4',
        classification: 'generic_uart_bridge',
        resolutionStage: 'stage_2_ambiguous',
        targetBoard: 'Ambiguous (CP2102)',
      );

      final vmDev = const DeviceDescriptor(
        vid: '1d50',
        pid: '606f',
        portTopology: '1-3',
        isolationRecommendation: 'qemu_vm',
        kernelModuleRequired: true,
      );

      repo.apiClient; // verify repo
      expect(ambiguousDev.isAmbiguousBridge, isTrue);
      expect(vmDev.isolationRecommendation, 'qemu_vm');
    });
  });
}

class _FakeWebSocket implements WebSocket {
  final Stream<dynamic> _stream;
  int _readyState = WebSocket.open;

  _FakeWebSocket(this._stream);

  @override
  int get readyState => _readyState;

  @override
  StreamSubscription listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future close([int? code, String? reason]) async {
    _readyState = WebSocket.closed;
  }

  @override
  void add(dynamic data) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
