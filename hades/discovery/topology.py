"""USB physical port topology extraction and tracking.

Solves the USB reset & re-enumeration problem (Gap B) by tracking physical
USB port paths (e.g. '1-2.1') rather than volatile device numbers (/dev/bus/usb/001/005).
"""

import re
from typing import Optional


def extract_port_topology(sys_name: str, devpath: str) -> str:
    """
    Extract the physical port topology string from a udev device.
    
    Examples:
        sys_name="1-4" -> "1-4"
        sys_name="1-2.1" -> "1-2.1"
        devpath=".../usb1/1-2/1-2.1:1.0" -> "1-2.1"
    """
    # If sys_name matches a USB device port format (e.g. "1-4", "3-2.1.4", "usb1")
    if re.match(r"^\d+-[\d\.]+$", sys_name):
        return sys_name
    
    # Check if sys_name is a root hub e.g. "usb1"
    if re.match(r"^usb\d+$", sys_name):
        return sys_name
        
    # Search backwards through path components for the USB device identifier
    parts = devpath.strip("/").split("/")
    for part in reversed(parts):
        # Match port strings like 1-2.1 or 3-4
        if re.match(r"^\d+-[\d\.]+$", part):
            return part
        if re.match(r"^usb\d+$", part):
            return part

    return sys_name or "unknown-port"


def is_same_physical_port(topology_a: str, topology_b: str) -> bool:
    """Determine if two devices reside on the exact same physical USB port."""
    if not topology_a or not topology_b:
        return False
    return topology_a.strip() == topology_b.strip()

