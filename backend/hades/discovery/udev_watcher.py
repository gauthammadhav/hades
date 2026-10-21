"""Asynchronous cold-plug and hot-plug udev discovery."""

import asyncio
from dataclasses import dataclass
from pathlib import Path
from typing import Any, AsyncIterator, Optional

try:
    import pyudev
except ImportError:
    pyudev = None

from hades.discovery.udev_scanner import scan_usb_devices
from hades.models.device import DiscoveredDevice
from hades.models.manifest import HadesManifest
from hades.resolver.manifest import load_manifest


@dataclass(frozen=True)
class UdevEvent:
    action: str
    device: Optional[DiscoveredDevice]


class UdevWatcher:
    """Run pyudev's monitor in an asyncio worker thread."""

    def __init__(
        self,
        workspace: Optional[Path] = None,
        context: Any = None,
        monitor: Any = None,
    ):
        if context is not None:
            self.context = context
        elif pyudev is not None:
            self.context = pyudev.Context()
        else:
            self.context = None

        self.workspace = workspace
        self.manifest, manifest_error = load_manifest(workspace_dir=workspace)
        if manifest_error and workspace is not None:
            raise ValueError(manifest_error)
        self._stopped = False
        self._active_devices: dict[str, DiscoveredDevice] = {}
        if monitor is not None:
            self._monitor = monitor
        elif self.context is not None and pyudev is not None:
            self._monitor = pyudev.Monitor.from_netlink(self.context)
            self._monitor.filter_by(subsystem="usb")
            self._monitor.filter_by(subsystem="tty")
            self._monitor.start()
        else:
            self._monitor = None

    def cold_plug(self) -> list[UdevEvent]:
        """Scan devices already present when the watcher starts."""
        devices = scan_usb_devices(manifest=self.manifest, context=self.context)
        events = []
        for dev in devices:
            self._active_devices[dev.sys_path] = dev
            events.append(UdevEvent("add", dev))
        return events

    def _monitor_once(self) -> Optional[UdevEvent]:
        device = self._monitor.poll(timeout=0.5)
        if device is None:
            return None
        action = getattr(device, "action", None)
        if action not in {"add", "remove", "change"}:
            return UdevEvent(str(action), None)
        if action == "remove":
            cached = self._active_devices.pop(device.sys_path, None)
            return UdevEvent(action, cached)
        devices = scan_usb_devices(manifest=self.manifest, context=self.context)
        matching = next((item for item in devices if item.sys_path == device.sys_path), None)
        if matching:
            self._active_devices[matching.sys_path] = matching
        return UdevEvent(action, matching)

    async def events(self) -> AsyncIterator[UdevEvent]:
        """Yield cold-plug events followed by add/remove/change events."""
        for event in self.cold_plug():
            yield event
        while not self._stopped:
            event = await asyncio.to_thread(self._monitor_once)
            if event is not None and (event.device is not None or event.action == "remove"):
                yield event

    def stop(self) -> None:
        self._stopped = True
