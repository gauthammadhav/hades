"""Udev USB and TTY scanner for hardware discovery.

Discovers connected physical devices, maps associated serial TTY nodes,
and passes raw descriptor data to the TwoStageResolver.
"""

from collections import defaultdict
from typing import Any, Dict, List, Optional
try:
    import pyudev
except ImportError:
    pyudev = None

from hades.discovery.topology import extract_port_topology
from hades.models.device import (
    DeviceClassification,
    DiscoveredDevice,
    ResolutionStage,
)
from hades.models.manifest import HadesManifest
from hades.resolver.two_stage import TwoStageResolver


def _safe_attr(device: Any, attr: str, default: str = "") -> str:
    """Safely retrieve a sysfs attribute string without raising exceptions."""
    try:
        val = device.attributes.asstring(attr)
        return val.strip() if val else default
    except Exception:
        # Fallback to properties dict
        prop_val = device.properties.get(attr) or device.properties.get(attr.upper())
        return str(prop_val).strip() if prop_val else default


def get_usb_tty_mapping(context: Any) -> Dict[str, List[str]]:
    """
    Build a map of USB sysfs paths to their child TTY device nodes.
    
    Returns:
        Dict mapping USB device sys_path -> list of /dev/tty* nodes (e.g. ['/dev/ttyUSB0'])
    """
    mapping: Dict[str, List[str]] = defaultdict(list)
    if context is None:
        return mapping
    try:
        for tty_dev in context.list_devices(subsystem="tty"):
            parent_usb = tty_dev.find_parent("usb", "usb_device")
            if parent_usb and tty_dev.device_node:
                mapping[parent_usb.sys_path].append(tty_dev.device_node)
    except Exception:
        pass
    return mapping


def scan_usb_devices(
    manifest: Optional[HadesManifest] = None,
    include_all: bool = False,
    context: Any = None,
) -> List[DiscoveredDevice]:
    """
    Scan all connected USB devices and resolve them using Two-Stage Discovery.
    
    Args:
        manifest: Optional project manifest (.hades.yaml) to resolve generic UART bridges.
        include_all: If True, includes internal USB root hubs and system peripherals.
        context: Optional existing pyudev Context.
        
    Returns:
        List of resolved DiscoveredDevice instances.
    """
    if context is None and pyudev is None:
        import sys
        if sys.platform == "win32":
            try:
                from hades.discovery.windows_scanner import scan_windows_usb_devices
                return scan_windows_usb_devices(manifest=manifest, include_all=include_all)
            except Exception:
                pass
        return []
    ctx = context or (pyudev.Context() if pyudev is not None else None)
    if ctx is None:
        return []
    tty_map = get_usb_tty_mapping(ctx)
    resolver = TwoStageResolver(manifest=manifest)
    discovered: List[DiscoveredDevice] = []

    for dev in ctx.list_devices(subsystem="usb"):
        if dev.properties.get("DEVTYPE") != "usb_device":
            continue

        vendor_id = _safe_attr(dev, "idVendor", "0000").zfill(4).lower()
        product_id = _safe_attr(dev, "idProduct", "0000").zfill(4).lower()
        vendor_name = _safe_attr(dev, "manufacturer") or dev.properties.get("ID_VENDOR", "")
        product_name = _safe_attr(dev, "product") or dev.properties.get("ID_MODEL", "")
        serial_no = _safe_attr(dev, "serial") or dev.properties.get("ID_SERIAL_SHORT", None)

        bus_num = int(_safe_attr(dev, "busnum", str(dev.properties.get("BUSNUM", 0))))
        dev_num = int(_safe_attr(dev, "devnum", str(dev.properties.get("DEVNUM", 0))))
        sys_name = dev.sys_name
        sys_path = dev.sys_path
        dev_node = dev.device_node
        port_topology = extract_port_topology(sys_name, dev.device_path)
        ttys = sorted(list(set(tty_map.get(sys_path, []))))

        # Read USB interfaces
        interfaces = []
        try:
            for child in dev.children:
                if child.properties.get("DEVTYPE") == "usb_interface":
                    driver = child.properties.get("DRIVER") or "unbound"
                    interfaces.append(f"{child.sys_name} ({driver})")
        except Exception:
            pass

        device = resolver.resolve(
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
            usb_interfaces=interfaces,
        )

        # Filtering logic:
        # If include_all is False, ignore root hubs and generic peripherals WITHOUT serial nodes
        if not include_all:
            if device.classification == DeviceClassification.HOST_HUB:
                continue
            if device.classification == DeviceClassification.PERIPHERAL and not device.tty_nodes:
                continue

        discovered.append(device)

    # Sort so development boards and bridges appear first
    priority = {
        ResolutionStage.STAGE_1_PASSIVE: 0,
        ResolutionStage.STAGE_2_MANIFEST: 1,
        ResolutionStage.STAGE_2_AMBIGUOUS: 2,
        ResolutionStage.SYSTEM_IGNORED: 3,
    }
    discovered.sort(key=lambda d: (priority.get(d.resolution_stage, 9), d.port_topology))
    return discovered

