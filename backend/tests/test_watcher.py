"""Unit tests for UdevWatcher and asynchronous udev event discovery."""

import asyncio
from unittest.mock import MagicMock

import pytest

from hades.discovery.udev_watcher import UdevEvent, UdevWatcher
from hades.models.device import DiscoveredDevice


@pytest.fixture
def fake_device():
    return DiscoveredDevice(
        device_id="usb:303a:1001:1-2.1",
        vendor_id="303a",
        product_id="1001",
        vendor_name="Espressif Systems",
        product_name="USB JTAG/serial debug unit",
        bus_num=1,
        dev_num=4,
        port_topology="1-2.1",
        sys_path="/sys/devices/.../1-2.1",
        sys_name="1-2.1",
    )


def test_udev_event_representation(fake_device):
    event = UdevEvent(action="add", device=fake_device)
    assert event.action == "add"
    assert event.device == fake_device


def test_watcher_cold_plug(monkeypatch, fake_device):
    monkeypatch.setattr(
        "hades.discovery.udev_watcher.scan_usb_devices",
        lambda manifest, context: [fake_device],
    )
    mock_monitor = MagicMock()
    watcher = UdevWatcher(monitor=mock_monitor)
    events = watcher.cold_plug()
    assert len(events) == 1
    assert events[0].action == "add"
    assert events[0].device == fake_device
    assert watcher._active_devices[fake_device.sys_path] == fake_device


def test_watcher_monitor_once_timeout():
    mock_monitor = MagicMock()
    mock_monitor.poll.return_value = None
    watcher = UdevWatcher(monitor=mock_monitor)
    assert watcher._monitor_once() is None


def test_watcher_monitor_once_remove(fake_device):
    mock_monitor = MagicMock()
    mock_udev_dev = MagicMock()
    mock_udev_dev.action = "remove"
    mock_udev_dev.sys_path = fake_device.sys_path
    mock_monitor.poll.return_value = mock_udev_dev

    watcher = UdevWatcher(monitor=mock_monitor)
    watcher._active_devices[fake_device.sys_path] = fake_device

    event = watcher._monitor_once()
    assert event is not None
    assert event.action == "remove"
    assert event.device == fake_device
    assert fake_device.sys_path not in watcher._active_devices


def test_watcher_events_stream(monkeypatch, fake_device):
    monkeypatch.setattr(
        "hades.discovery.udev_watcher.scan_usb_devices",
        lambda manifest, context: [fake_device],
    )
    mock_monitor = MagicMock()
    mock_monitor.poll.return_value = None

    watcher = UdevWatcher(monitor=mock_monitor)

    collected = []

    async def run_events():
        async for ev in watcher.events():
            collected.append(ev)
            watcher.stop()

    asyncio.run(asyncio.wait_for(run_events(), timeout=2.0))
    assert len(collected) == 1
    assert collected[0].action == "add"
    assert collected[0].device == fake_device
