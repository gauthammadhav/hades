import 'runtime.dart';

class Scenario {
  final String id;
  final String name;
  final String vidPid;
  final String busPath;
  final String node;
  final String usbClass;
  final Runtime runtime;
  final String arch;
  final List<String> toolchains;
  final String broker;
  final String reason;
  final List<bool>
  rules; // [Allow-listed class, Kernel module required, Serial / JTAG only, HID / mass-storage class]

  const Scenario({
    required this.id,
    required this.name,
    required this.vidPid,
    required this.busPath,
    required this.node,
    required this.usbClass,
    required this.runtime,
    required this.arch,
    required this.toolchains,
    required this.broker,
    required this.reason,
    required this.rules,
  });

  bool get isBlocked => runtime.isBlocked;

  int get maxStageNumber => isBlocked ? 3 : 5;

  static const List<Scenario> mockScenarios = [
    Scenario(
      id: 'esp32_s3',
      name: 'ESP32-S3 Serial Flash',
      vidPid: '303A:1001',
      busPath: 'usb 1-2.1',
      node: '/dev/ttyACM0',
      usbClass: 'CDC-ACM (0x02)',
      runtime: Runtime.docker,
      arch: 'xtensa-esp32s3-elf',
      toolchains: ['idf.py', 'openocd'],
      broker: 'cgroup device allow, no --privileged',
      reason: 'CDC-ACM class approved for container isolation',
      rules: [true, false, true, false],
    ),
    Scenario(
      id: 'can_module',
      name: 'Custom CAN Kernel Module',
      vidPid: '1D50:606F',
      busPath: 'usb 1-4',
      node: '/dev/bus/usb/001/007',
      usbClass: 'Vendor specific (0xFF)',
      runtime: Runtime.qemu,
      arch: 'arm-none-eabi',
      toolchains: ['openocd', 'make'],
      broker: 'libvirt hostdev hotplug, CoW qcow2 VM',
      reason: 'Proprietary .ko driver needs guest kernel',
      rules: [true, true, false, false],
    ),
    Scenario(
      id: 'unauthorized_hid',
      name: 'Unauthorized USB Attack',
      vidPid: '0951:1666',
      busPath: 'usb 1-3',
      node: '/dev/input/event7',
      usbClass: 'HID (0x03)',
      runtime: Runtime.blocked,
      arch: '-',
      toolchains: [],
      broker: 'none, access denied',
      reason: 'HID/mass storage not approved',
      rules: [false, false, false, true],
    ),
  ];
}
