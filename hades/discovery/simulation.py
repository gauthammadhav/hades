"""Hardware simulation presets for testing, automated validation, and demos."""

from typing import List, Optional
from hades.models.device import DiscoveredDevice
from hades.models.manifest import HadesManifest
from hades.resolver.manifest import generate_preset_manifest
from hades.resolver.two_stage import TwoStageResolver


SIMULATION_PRESETS = {
    "esp32-native": {
        "vendor_id": "303a",
        "product_id": "1001",
        "vendor_name": "Espressif Systems",
        "product_name": "USB JTAG/serial debug unit",
        "bus_num": 1,
        "dev_num": 4,
        "port_topology": "1-2.1",
        "sys_path": "/sys/devices/pci0000:00/.../usb1/1-2/1-2.1",
        "sys_name": "1-2.1",
        "dev_node": "/dev/bus/usb/001/004",
        "serial_number": "303A1001ESPS3",
        "tty_nodes": ["/dev/ttyACM0"],
        "manifest": None,
    },
    "esp32-cp2102-ambiguous": {
        "vendor_id": "10c4",
        "product_id": "ea60",
        "vendor_name": "Silicon Labs",
        "product_name": "CP2102 USB to UART Bridge Controller",
        "bus_num": 1,
        "dev_num": 5,
        "port_topology": "1-4",
        "sys_path": "/sys/devices/pci0000:00/.../usb1/1-4",
        "sys_name": "1-4",
        "dev_node": "/dev/bus/usb/001/005",
        "serial_number": "0001",
        "tty_nodes": ["/dev/ttyUSB0"],
        "manifest": None,  # No manifest -> Triggers Stage 2 Ambiguous notice
    },
    "esp32-cp2102-resolved": {
        "vendor_id": "10c4",
        "product_id": "ea60",
        "vendor_name": "Silicon Labs",
        "product_name": "CP2102 USB to UART Bridge Controller",
        "bus_num": 1,
        "dev_num": 5,
        "port_topology": "1-4",
        "sys_path": "/sys/devices/pci0000:00/.../usb1/1-4",
        "sys_name": "1-4",
        "dev_node": "/dev/bus/usb/001/005",
        "serial_number": "0001",
        "tty_nodes": ["/dev/ttyUSB0"],
        "manifest": generate_preset_manifest("esp32", "smart-sensor-esp32"),
    },
    "stlink-v2": {
        "vendor_id": "0483",
        "product_id": "3748",
        "vendor_name": "STMicroelectronics",
        "product_name": "ST-LINK/V2",
        "bus_num": 3,
        "dev_num": 6,
        "port_topology": "3-2",
        "sys_path": "/sys/devices/pci0000:00/.../usb3/3-2",
        "sys_name": "3-2",
        "dev_node": "/dev/bus/usb/003/006",
        "serial_number": "54FF6E067289515131451267",
        "tty_nodes": [],
        "manifest": None,
    },
    "rp2040-pico": {
        "vendor_id": "2e8a",
        "product_id": "0003",
        "vendor_name": "Raspberry Pi",
        "product_name": "Pico RP2040 Microcontroller",
        "bus_num": 1,
        "dev_num": 7,
        "port_topology": "1-1.3",
        "sys_path": "/sys/devices/pci0000:00/.../usb1/1-1/1-1.3",
        "sys_name": "1-1.3",
        "dev_node": "/dev/bus/usb/001/007",
        "serial_number": "E6614103E72B7029",
        "tty_nodes": ["/dev/ttyACM1"],
        "manifest": None,
    },
    "custom-kernel-device": {
        "vendor_id": "10c4",
        "product_id": "ea60",
        "vendor_name": "Silicon Labs",
        "product_name": "CP2102 Bridge with Custom Driver",
        "bus_num": 2,
        "dev_num": 8,
        "port_topology": "2-1",
        "sys_path": "/sys/devices/pci0000:00/.../usb2/2-1",
        "sys_name": "2-1",
        "dev_node": "/dev/bus/usb/002/008",
        "serial_number": "CUSTOM001",
        "tty_nodes": ["/dev/ttyUSB1"],
        "manifest": generate_preset_manifest("kernel", "custom-kernel-module-project"),
    },
}


def get_simulated_devices(preset_name: str, manifest: Optional[HadesManifest] = None) -> List[DiscoveredDevice]:
    """Generate simulated DiscoveredDevice for a given preset name."""
    preset = SIMULATION_PRESETS.get(preset_name.lower())
    if not preset:
        # If user passed "all" or unrecognized, return all test fixtures
        return [
            TwoStageResolver(manifest=p["manifest"] or manifest).resolve(
                vendor_id=p["vendor_id"],
                product_id=p["product_id"],
                vendor_name=p["vendor_name"],
                product_name=p["product_name"],
                bus_num=p["bus_num"],
                dev_num=p["dev_num"],
                port_topology=p["port_topology"],
                sys_path=p["sys_path"],
                sys_name=p["sys_name"],
                dev_node=p["dev_node"],
                serial_number=p["serial_number"],
                tty_nodes=p["tty_nodes"],
            )
            for p in [
                SIMULATION_PRESETS["esp32-native"],
                SIMULATION_PRESETS["esp32-cp2102-resolved"],
                SIMULATION_PRESETS["stlink-v2"],
            ]
        ]

    active_manifest = manifest or preset["manifest"]
    resolver = TwoStageResolver(manifest=active_manifest)
    device = resolver.resolve(
        vendor_id=preset["vendor_id"],
        product_id=preset["product_id"],
        vendor_name=preset["vendor_name"],
        product_name=preset["product_name"],
        bus_num=preset["bus_num"],
        dev_num=preset["dev_num"],
        port_topology=preset["port_topology"],
        sys_path=preset["sys_path"],
        sys_name=preset["sys_name"],
        dev_node=preset["dev_node"],
        serial_number=preset["serial_number"],
        tty_nodes=preset["tty_nodes"],
    )
    return [device]

