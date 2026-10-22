"""Windows native USB hardware scanner and real-time plug/unplug monitor.

Enables HADES to discover physical USB development boards, UART bridges,
microcontrollers, and peripherals directly on Windows hosts without requiring Linux/udev.
"""

from __future__ import annotations

import asyncio
from dataclasses import dataclass
import logging
import re
import sys
from typing import Any, AsyncIterator, Dict, List, Optional, Set
import winreg

from hades.discovery.topology import extract_port_topology
from hades.models.device import (
    DeviceClassification,
    DiscoveredDevice,
    ResolutionStage,
)
from hades.models.manifest import HadesManifest
from hades.resolver.two_stage import TwoStageResolver

logger = logging.getLogger(__name__)


def _get_wmi_client() -> Any:
    """Return a win32com WMI client object if available."""
    try:
        try:
            import pythoncom
            pythoncom.CoInitialize()
        except Exception:
            pass
        import win32com.client
        return win32com.client.GetObject("winmgmts:")
    except Exception as e:
        logger.warning(f"win32com WMI client not available: {e}")
        return None


def get_windows_com_ports() -> Dict[str, str]:
    """
    Find active COM ports and map device IDs/names to COM port names (e.g. 'COM3').
    
    Returns:
        Dict mapping uppercase identifier substring or DeviceID to COM port string.
    """
    com_map: Dict[str, str] = {}
    
    # 1. Query registry for active serial communication ports
    try:
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"HARDWARE\DEVICEMAP\SERIALCOMM")
        idx = 0
        while True:
            try:
                name, val, _ = winreg.EnumValue(key, idx)
                if val:
                    com_map[str(name).upper()] = str(val).strip()
                idx += 1
            except OSError:
                break
        winreg.CloseKey(key)
    except Exception:
        pass

    # 2. Query WMI Win32_PnPEntity for Ports
    wmi = _get_wmi_client()
    if wmi is not None:
        try:
            port_entities = wmi.ExecQuery(
                "SELECT Caption, DeviceID, PNPClass FROM Win32_PnPEntity WHERE PNPClass = 'Ports'"
            )
            for pe in port_entities:
                caption = str(getattr(pe, "Caption", "") or "")
                dev_id = str(getattr(pe, "DeviceID", "") or "").upper()
                m = re.search(r"\((COM\d+)\)", caption, re.IGNORECASE)
                if m:
                    com_name = m.group(1).upper()
                    com_map[dev_id] = com_name
                    # Also map VID:PID substring if present
                    vid_pid_match = re.search(r"VID_[0-9A-F]{4}&PID_[0-9A-F]{4}", dev_id)
                    if vid_pid_match:
                        com_map[vid_pid_match.group(0)] = com_name
        except Exception:
            pass

    return com_map


def scan_windows_usb_devices(
    manifest: Optional[HadesManifest] = None,
    include_all: bool = False,
) -> List[DiscoveredDevice]:
    """
    Scan all physical USB devices connected to this Windows machine.
    
    Resolves each device through TwoStageResolver using VID:PID, reported
    product name, manufacturer, and detected COM port.
    """
    if sys.platform != "win32":
        return []

    wmi = _get_wmi_client()
    if wmi is None:
        logger.warning("WMI client unavailable; cannot scan Windows USB devices.")
        return []

    try:
        raw_devices = list(
            wmi.ExecQuery(
                "SELECT Caption, DeviceID, Manufacturer, Description, Service, PNPClass "
                "FROM Win32_PnPEntity WHERE DeviceID LIKE 'USB\\\\VID_%'"
            )
        )
    except Exception as e:
        logger.warning(f"Error querying Win32_PnPEntity: {e}")
        return []

    com_ports = get_windows_com_ports()
    resolver = TwoStageResolver(manifest=manifest)

    # Filter to top-level USB device containers (avoid duplicate multi-interface entries)
    # Child interfaces on Windows contain &MI_ (e.g. USB\VID_...&MI_00)
    top_level = [d for d in raw_devices if "&MI_" not in getattr(d, "DeviceID", "")]
    if not top_level:
        # Fallback: if no non-MI devices found, take all unique VID:PID combos
        seen_keys: Set[str] = set()
        unique_devs = []
        for d in raw_devices:
            dev_id = getattr(d, "DeviceID", "")
            base_key = dev_id.split("&MI_")[0]
            if base_key not in seen_keys:
                seen_keys.add(base_key)
                unique_devs.append(d)
        top_level = unique_devs

    discovered: List[DiscoveredDevice] = []
    
    for idx, d in enumerate(top_level):
        dev_id = str(getattr(d, "DeviceID", "") or "")
        m = re.search(r"VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})", dev_id)
        if not m:
            continue

        vid = m.group(1).lower()
        pid = m.group(2).lower()
        mfg = str(getattr(d, "Manufacturer", "") or "")
        caption = str(getattr(d, "Caption", "") or "")
        desc = str(getattr(d, "Description", "") or "")
        product = caption or desc or "USB Device"

        # Extract serial number from 3rd segment of DeviceID if present
        parts = dev_id.split("\\")
        serial: Optional[str] = None
        if len(parts) >= 3 and "&" not in parts[-1]:
            serial = parts[-1]

        # Check for associated COM port
        tty_nodes: List[str] = []
        vid_pid_tag = f"VID_{vid.upper()}&PID_{pid.upper()}"
        if dev_id.upper() in com_ports:
            tty_nodes.append(com_ports[dev_id.upper()])
        elif vid_pid_tag in com_ports:
            tty_nodes.append(com_ports[vid_pid_tag])
        else:
            # Check if caption contains (COMx)
            com_match = re.search(r"\((COM\d+)\)", caption, re.IGNORECASE)
            if com_match:
                tty_nodes.append(com_match.group(1).upper())

        bus_num = 1
        dev_num = idx + 1
        port_topology = f"1-{dev_num}"
        sys_name = f"usb-{vid}:{pid}-{dev_num}"
        sys_path = f"\\\\?\\{dev_id}"

        resolved = resolver.resolve(
            vendor_id=vid,
            product_id=pid,
            vendor_name=mfg,
            product_name=product,
            bus_num=bus_num,
            dev_num=dev_num,
            port_topology=port_topology,
            sys_path=sys_path,
            sys_name=sys_name,
            dev_node=None,
            serial_number=serial,
            tty_nodes=tty_nodes,
            usb_interfaces=[],
        )

        # Filtering logic matching Linux udev_scanner:
        # Ignore internal hubs or system peripherals unless include_all is True
        if not include_all:
            if resolved.classification == DeviceClassification.HOST_HUB:
                continue
            if resolved.classification == DeviceClassification.PERIPHERAL and not resolved.tty_nodes:
                continue

        discovered.append(resolved)

    # Sort so development boards and bridges appear first
    priority = {
        ResolutionStage.STAGE_1_PASSIVE: 0,
        ResolutionStage.STAGE_2_MANIFEST: 1,
        ResolutionStage.STAGE_2_AMBIGUOUS: 2,
        ResolutionStage.SYSTEM_IGNORED: 3,
    }
    discovered.sort(key=lambda dev: (priority.get(dev.resolution_stage, 9), dev.port_topology))
    return discovered


@dataclass
class WindowsDeviceEvent:
    """Event emitted when a USB hardware device is connected or disconnected on Windows."""
    action: str  # 'add' or 'remove'
    device: DiscoveredDevice
    message: str = ""


async def windows_device_event_stream(poll_interval: float = 1.5) -> AsyncIterator[WindowsDeviceEvent]:
    """
    Continuously poll Windows PnP for USB connection/disconnection events.
    
    Yields WindowsDeviceEvent items when devices are plugged in or unplugged.
    """
    known_devices: Dict[str, DiscoveredDevice] = {}
    
    # Initial scan to populate baseline
    try:
        initial = scan_windows_usb_devices(include_all=True)
        for dev in initial:
            known_devices[dev.device_id] = dev
    except Exception as e:
        logger.debug(f"Initial Windows USB baseline scan error: {e}")

    while True:
        await asyncio.sleep(poll_interval)
        try:
            current_list = scan_windows_usb_devices(include_all=True)
            current_map = {dev.device_id: dev for dev in current_list}

            # Check for newly added devices
            for dev_id, dev in current_map.items():
                if dev_id not in known_devices:
                    known_devices[dev_id] = dev
                    yield WindowsDeviceEvent(
                        action="add",
                        device=dev,
                        message=f"Connected: {dev.product_name} ({dev.vendor_id}:{dev.product_id})",
                    )

            # Check for removed devices
            removed_ids = [d_id for d_id in known_devices if d_id not in current_map]
            for r_id in removed_ids:
                removed_dev = known_devices.pop(r_id)
                yield WindowsDeviceEvent(
                    action="remove",
                    device=removed_dev,
                    message=f"Disconnected: {removed_dev.product_name} ({removed_dev.vendor_id}:{removed_dev.product_id})",
                )
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.debug(f"Windows device polling error: {e}")
            await asyncio.sleep(poll_interval)
