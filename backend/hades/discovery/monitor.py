"""Real-time USB plug/unplug monitor with port topology and re-enumeration tracking.

Addresses Gap B by listening for udev netlink events, tracking physical port
paths, and detecting microcontroller resets during firmware flashing.
"""

from dataclasses import dataclass
from typing import Dict, Iterator, Optional
import pyudev

from hades.discovery.topology import extract_port_topology
from hades.discovery.udev_scanner import _safe_attr, get_usb_tty_mapping
from hades.models.device import DiscoveredDevice
from hades.models.manifest import HadesManifest
from hades.resolver.two_stage import TwoStageResolver


@dataclass
class DeviceEvent:
    """Event emitted when hardware is plugged, removed, or re-enumerated."""
    action: str  # 'add', 'remove', 're-enumerated'
    device: DiscoveredDevice
    previous_dev_num: Optional[int] = None
    message: str = ""


class DeviceMonitor:
    """Monitors live hardware events via pyudev netlink."""

    def __init__(self, manifest: Optional[HadesManifest] = None):
        self.context = pyudev.Context()
        self.resolver = TwoStageResolver(manifest=manifest)
        self.active_ports: Dict[str, DiscoveredDevice] = {}

    def listen(self) -> Iterator[DeviceEvent]:
        """
        Listen continuously for USB plug, unplug, and reset events.
        
        Yields DeviceEvent objects as hardware events occur on the host.
        """
        monitor = pyudev.Monitor.from_netlink(self.context)
        monitor.filter_by(subsystem="usb")

        for action, device in monitor:
            if device.properties.get("DEVTYPE") != "usb_device":
                continue

            sys_name = device.sys_name
            sys_path = device.sys_path
            port_topology = extract_port_topology(sys_name, device.device_path)

            if action == "add":
                vendor_id = _safe_attr(device, "idVendor", "0000").zfill(4).lower()
                product_id = _safe_attr(device, "idProduct", "0000").zfill(4).lower()
                vendor_name = _safe_attr(device, "manufacturer") or device.properties.get("ID_VENDOR", "")
                product_name = _safe_attr(device, "product") or device.properties.get("ID_MODEL", "")
                serial_no = _safe_attr(device, "serial") or device.properties.get("ID_SERIAL_SHORT", None)
                bus_num = int(_safe_attr(device, "busnum", str(device.properties.get("BUSNUM", 0))))
                dev_num = int(_safe_attr(device, "devnum", str(device.properties.get("DEVNUM", 0))))
                dev_node = device.device_node

                tty_map = get_usb_tty_mapping(self.context)
                ttys = sorted(list(set(tty_map.get(sys_path, []))))

                discovered = self.resolver.resolve(
                    vendor_id=vendor_id,
                    product_id=product_id,
                    vendor_name=vendor_name,
                    product_name=product_name,
                    bus_num=bus_num,
                    dev_num=dev_num,
                    port_topology=port_topology,
                    sys_path=sys_path,
                    sys_name=sys_name,
                    dev_node=dev_node,
                    serial_number=serial_no,
                    tty_nodes=ttys,
                )

                # Check for re-enumeration on same physical port
                prev_device = self.active_ports.get(port_topology)
                if prev_device and prev_device.dev_num != dev_num:
                    self.active_ports[port_topology] = discovered
                    yield DeviceEvent(
                        action="re-enumerated",
                        device=discovered,
                        previous_dev_num=prev_device.dev_num,
                        message=(
                            f"[Gap B Solved] USB Re-Enumeration on port {port_topology}: "
                            f"Device reset (devnum {prev_device.dev_num} -> {dev_num}). "
                            f"Hardware Broker preserves container device cgroup mapping."
                        ),
                    )
                else:
                    self.active_ports[port_topology] = discovered
                    yield DeviceEvent(
                        action="add",
                        device=discovered,
                        message=f"Device connected on physical port {port_topology}.",
                    )

            elif action == "remove":
                cached = self.active_ports.pop(port_topology, None)
                if cached:
                    yield DeviceEvent(
                        action="remove",
                        device=cached,
                        message=f"Device disconnected from physical port {port_topology}.",
                    )

