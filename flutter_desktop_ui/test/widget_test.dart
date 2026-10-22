/// Dashboard controller and device inventory tests.
///
/// All responses use mock fixtures. No physical hardware is required.
/// Mock data is clearly separated from real device data.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_desktop_ui/models/dto/device_descriptor.dart';
import 'package:flutter_desktop_ui/state/dashboard_controller.dart';

// ---------------------------------------------------------------------------
// Mock API client helpers
// ---------------------------------------------------------------------------

/// Mock device fixtures (clearly not real hardware — for tests only).
final _mockNative = DeviceDescriptor.fromJson({
  'device_id': 'usb:303a:1001:1-2.1',
  'vendor_id': '303a',
  'product_id': '1001',
  'vendor_name': 'Espressif Systems',
  'product_name': 'USB JTAG/serial debug unit',
  'serial_number': 'MOCK_SERIAL_ESP32',
  'bus_num': 1,
  'dev_num': 4,
  'port_topology': '1-2.1',
  'sys_path': '/sys/mock/usb1/1-2.1',
  'sys_name': '1-2.1',
  'dev_node': '/dev/bus/usb/001/004',
  'tty_nodes': ['/dev/ttyACM0'],
  'classification': 'native_mcu',
  'target_board': 'ESP32-S3-DevKitC-1',
  'target_chip': 'ESP32-S3',
  'recommended_sdk': 'esp-idf',
  'resolution_stage': 'stage_1_passive',
  'isolation_recommendation': 'container_broker',
  'resolution_notes': '[MOCK] Stage 1 passive match.',
});

final _mockAmbiguous = DeviceDescriptor.fromJson({
  'device_id': 'usb:10c4:ea60:1-4',
  'vendor_id': '10c4',
  'product_id': 'ea60',
  'vendor_name': 'Silicon Labs',
  'product_name': 'CP2102 USB to UART Bridge Controller',
  'serial_number': null,
  'bus_num': 1,
  'dev_num': 5,
  'port_topology': '1-4',
  'sys_path': '/sys/mock/usb1/1-4',
  'sys_name': '1-4',
  'dev_node': '/dev/bus/usb/001/005',
  'tty_nodes': ['/dev/ttyUSB0'],
  'classification': 'generic_uart_bridge',
  'target_board': 'Ambiguous (CP2102 USB to UART Bridge Controller)',
  'target_chip': 'Unknown (Behind Serial Bridge)',
  'recommended_sdk': null,
  'resolution_stage': 'stage_2_ambiguous',
  'isolation_recommendation': 'container_broker',
  'resolution_notes': '[MOCK] Ambiguous bridge.',
});

final _mockManifestResolved = DeviceDescriptor.fromJson({
  'device_id': 'usb:10c4:ea60:2-1',
  'vendor_id': '10c4',
  'product_id': 'ea60',
  'vendor_name': 'Silicon Labs',
  'product_name': 'CP2102 USB to UART Bridge Controller',
  'serial_number': 'CUSTOM001',
  'bus_num': 2,
  'dev_num': 8,
  'port_topology': '2-1',
  'sys_path': '/sys/mock/usb2/2-1',
  'sys_name': '2-1',
  'dev_node': '/dev/bus/usb/002/008',
  'tty_nodes': ['/dev/ttyUSB1'],
  'classification': 'generic_uart_bridge',
  'target_board': 'Arduino Mega 2560',
  'target_chip': 'ATmega2560',
  'recommended_sdk': 'arduino-cli',
  'resolution_stage': 'stage_2_manifest',
  'isolation_recommendation': 'container_broker',
  'resolution_notes': '[MOCK] Stage 2 manifest resolved.',
});

// ---------------------------------------------------------------------------
// DeviceDescriptor unit tests
// ---------------------------------------------------------------------------

void main() {
  group('DeviceDescriptor', () {
    test('stableId uses device_id when present', () {
      expect(_mockNative.stableId, 'usb:303a:1001:1-2.1');
    });

    test('stableId falls back to topology-based id', () {
      final noId = DeviceDescriptor.fromJson({
        'vendor_id': 'abcd',
        'product_id': '1234',
        'bus_num': 1,
        'dev_num': 3,
        'port_topology': '1-3',
        'sys_path': '/mock',
        'sys_name': '1-3',
      });
      expect(noId.stableId, 'usb:abcd:1234:1-3');
    });

    test('displayName uses targetBoard for stage1 passive device', () {
      expect(_mockNative.displayName, 'ESP32-S3-DevKitC-1');
    });

    test('displayName uses product for ambiguous device without board', () {
      final noBoard = DeviceDescriptor.fromJson({
        'vendor_id': '10c4',
        'product_id': 'ea60',
        'product_name': 'CP2102 USB to UART Bridge',
        'bus_num': 1,
        'dev_num': 5,
        'port_topology': '1-5',
        'sys_path': '/mock',
        'sys_name': '1-5',
      });
      expect(noBoard.displayName, 'CP2102 USB to UART Bridge');
    });

    test('isStage1Passive for native MCU', () {
      expect(_mockNative.isStage1Passive, isTrue);
      expect(_mockNative.isAmbiguousBridge, isFalse);
      expect(_mockNative.isStage2Manifest, isFalse);
    });

    test('isAmbiguousBridge for unresolved bridge', () {
      expect(_mockAmbiguous.isAmbiguousBridge, isTrue);
      expect(_mockAmbiguous.isStage1Passive, isFalse);
      expect(_mockAmbiguous.isStage2Manifest, isFalse);
    });

    test('isStage2Manifest for manifest-resolved bridge', () {
      expect(_mockManifestResolved.isStage2Manifest, isTrue);
      expect(_mockManifestResolved.isAmbiguousBridge, isFalse);
    });

    test('serial number may be null without error', () {
      expect(_mockAmbiguous.serial, isNull);
      expect(_mockNative.serial, 'MOCK_SERIAL_ESP32');
    });

    test('usbId is lowercase vid:pid', () {
      expect(_mockNative.usbId, '303a:1001');
      expect(_mockAmbiguous.usbId, '10c4:ea60');
    });

    test('equality based on stableId', () {
      final dup = DeviceDescriptor.fromJson({
        'device_id': 'usb:303a:1001:1-2.1',
        'vendor_id': '303a',
        'product_id': '1001',
        'bus_num': 1,
        'dev_num': 99, // different dev_num but same device_id
        'port_topology': '1-2.1',
        'sys_path': '/mock',
        'sys_name': '1-2.1',
      });
      expect(dup, equals(_mockNative));
    });
  });

  // -------------------------------------------------------------------------
  // Count semantics (mirrors backend scanner rules)
  // -------------------------------------------------------------------------
  group('Device count semantics', () {
    final inventory = [_mockNative, _mockAmbiguous, _mockManifestResolved];

    int connectedCount(List<DeviceDescriptor> devices) => devices.length;

    int identifiedCount(List<DeviceDescriptor> devices) => devices
        .where((d) => d.isStage1Passive || d.isStage2Manifest)
        .length;

    int ambiguousCount(List<DeviceDescriptor> devices) =>
        devices.where((d) => d.isAmbiguousBridge).length;

    test('connected = total returned devices', () {
      expect(connectedCount(inventory), 3);
    });

    test('identified = stage1 + stage2_manifest', () {
      // _mockNative (stage1) + _mockManifestResolved (stage2_manifest)
      expect(identifiedCount(inventory), 2);
    });

    test('ambiguous = stage2_ambiguous only', () {
      // _mockAmbiguous only
      expect(ambiguousCount(inventory), 1);
    });

    test('identified + ambiguous does not double count', () {
      expect(
        identifiedCount(inventory) + ambiguousCount(inventory),
        lessThanOrEqualTo(connectedCount(inventory)),
      );
    });

    test('empty inventory produces zero counts', () {
      expect(connectedCount([]), 0);
      expect(identifiedCount([]), 0);
      expect(ambiguousCount([]), 0);
    });

    test('identical VID:PID devices on different ports count separately', () {
      // Two CP2102 devices on different ports — different stableIds
      final inv = [_mockAmbiguous, _mockManifestResolved];
      expect(_mockAmbiguous.usbId, _mockManifestResolved.usbId); // same VID:PID
      expect(_mockAmbiguous.stableId,
          isNot(equals(_mockManifestResolved.stableId))); // different identity
      expect(connectedCount(inv), 2);
    });
  });

  // -------------------------------------------------------------------------
  // Search filtering
  // -------------------------------------------------------------------------
  group('Search filtering', () {
    final inventory = [_mockNative, _mockAmbiguous, _mockManifestResolved];

    List<DeviceDescriptor> search(
        List<DeviceDescriptor> devices, String query) {
      final q = query.toLowerCase();
      return devices.where((d) {
        return d.displayName.toLowerCase().contains(q) ||
            d.usbId.contains(q) ||
            (d.serial?.toLowerCase().contains(q) ?? false) ||
            (d.portTopology?.toLowerCase().contains(q) ?? false) ||
            (d.manufacturer?.toLowerCase().contains(q) ?? false) ||
            (d.product?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    test('search by VID:PID finds cp2102 devices', () {
      expect(search(inventory, '10c4:ea60').length, 2);
    });

    test('search by port topology', () {
      expect(search(inventory, '1-2.1').length, 1);
      expect(search(inventory, '1-2.1').first.stableId, _mockNative.stableId);
    });

    test('search by serial number', () {
      expect(search(inventory, 'MOCK_SERIAL_ESP32').length, 1);
    });

    test('search by manufacturer', () {
      expect(search(inventory, 'espressif').length, 1);
    });

    test('empty query returns all devices', () {
      expect(search(inventory, '').length, inventory.length);
    });

    test('no match returns empty list', () {
      expect(search(inventory, 'xyzzy_notadevice'), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Status filtering
  // -------------------------------------------------------------------------
  group('Status filter', () {
    final inventory = [_mockNative, _mockAmbiguous, _mockManifestResolved];

    List<DeviceDescriptor> filterByStatus(
        List<DeviceDescriptor> devices, String? filter) {
      if (filter == null) return devices;
      return devices.where((d) {
        switch (filter) {
          case 'resolved':
            return d.isStage1Passive || d.isStage2Manifest;
          case 'ambiguous':
            return d.isAmbiguousBridge;
          default:
            return !d.isStage1Passive &&
                !d.isStage2Manifest &&
                !d.isAmbiguousBridge;
        }
      }).toList();
    }

    test('null filter returns all', () {
      expect(filterByStatus(inventory, null).length, 3);
    });

    test('resolved filter returns stage1 and stage2_manifest', () {
      final resolved = filterByStatus(inventory, 'resolved');
      expect(resolved.length, 2);
      expect(resolved.every((d) => d.isStage1Passive || d.isStage2Manifest),
          isTrue);
    });

    test('ambiguous filter returns only stage2_ambiguous', () {
      final amb = filterByStatus(inventory, 'ambiguous');
      expect(amb.length, 1);
      expect(amb.first.stableId, _mockAmbiguous.stableId);
    });
  });

  // -------------------------------------------------------------------------
  // Reconciliation (connect/disconnect)
  // -------------------------------------------------------------------------
  group('Inventory reconciliation', () {
    test('new device produces add event in _reconcileDevices logic', () {
      // Simulate: had [native], fresh scan gives [native, ambiguous]
      final prev = [_mockNative];
      final fresh = [_mockNative, _mockAmbiguous];

      final prevIds = prev.map((d) => d.stableId).toSet();
      final freshIds = fresh.map((d) => d.stableId).toSet();

      final added = freshIds.difference(prevIds);
      final removed = prevIds.difference(freshIds);

      expect(added, contains(_mockAmbiguous.stableId));
      expect(removed, isEmpty);
    });

    test('removed device produces remove event', () {
      final prev = [_mockNative, _mockAmbiguous];
      final fresh = [_mockNative];

      final prevIds = prev.map((d) => d.stableId).toSet();
      final freshIds = fresh.map((d) => d.stableId).toSet();

      final removed = prevIds.difference(freshIds);
      expect(removed, contains(_mockAmbiguous.stableId));
    });

    test('re-enumeration: same device different dev_num stays in inventory', () {
      // Device resets and gets new dev_num but same port_topology → same stableId
      final original = _mockNative;
      final reEnum = DeviceDescriptor.fromJson({
        'device_id': original.deviceId, // same ID
        'vendor_id': original.vid,
        'product_id': original.pid,
        'bus_num': original.bus ?? 1,
        'dev_num': 99, // new dev_num after reset
        'port_topology': original.portTopology,
        'sys_path': original.sysPath,
        'sys_name': original.sysName,
      });

      // stableId must be the same (device_id match)
      expect(reEnum.stableId, equals(original.stableId));

      // Inventory update: replace in place
      var inv = [original];
      final idx = inv.indexWhere((d) => d.stableId == reEnum.stableId);
      if (idx >= 0) inv[idx] = reEnum;

      expect(inv.length, 1);
      expect(inv.first.address, 99);
    });

    test('duplicate events for same device do not double-count', () {
      var inv = <DeviceDescriptor>[];

      void applyAdd(DeviceDescriptor dev) {
        if (!inv.any((d) => d.stableId == dev.stableId)) {
          inv = [...inv, dev];
        }
      }

      // Simulate receiving the same add event twice
      applyAdd(_mockNative);
      applyAdd(_mockNative);

      expect(inv.length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Backend status transitions
  // -------------------------------------------------------------------------
  group('BackendStatus', () {
    test('BackendStatus enum has expected values', () {
      expect(BackendStatus.values, containsAll([
        BackendStatus.connecting,
        BackendStatus.online,
        BackendStatus.offline,
        BackendStatus.authRequired,
        BackendStatus.discoveryUnavailable,
      ]));
    });
  });
}
