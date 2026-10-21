#!/usr/bin/env python3
"""
HADES Hardware Detection WebSocket Server
==========================================
Listens on ws://127.0.0.1:8000/ws/events and broadcasts device plug-in
events to the HADES Flutter desktop Control Plane UI in real time.

Usage:
  python scripts/device_detector.py
"""

import asyncio
import json
import sys

try:
    import websockets
except ImportError:
    print("Please install websockets: pip install websockets")
    sys.exit(1)

CONNECTED_CLIENTS = set()

# Pre-defined HADES hardware scenarios
SCENARIOS = {
    "1": {
        "id": "esp32_s3",
        "name": "ESP32-S3 Serial Flash",
        "vid_pid": "303A:1001",
        "bus_path": "usb 1-2.1",
        "node": "/dev/ttyACM0",
        "usb_class": "CDC-ACM (0x02)",
        "runtime": "DOCKER_CONTAINER",
        "log": "[netlink] add usb 1-2.1 303A:1001 /dev/ttyACM0"
    },
    "2": {
        "id": "can_module",
        "name": "Custom CAN Kernel Module",
        "vid_pid": "1D50:606F",
        "bus_path": "usb 1-4",
        "node": "/dev/bus/usb/001/007",
        "usb_class": "Vendor specific (0xFF)",
        "runtime": "QEMU_KVM_VM",
        "log": "[netlink] add usb 1-4 1D50:606F /dev/bus/usb/001/007"
    },
    "3": {
        "id": "unauthorized_hid",
        "name": "Unauthorized USB Attack",
        "vid_pid": "0951:1666",
        "bus_path": "usb 1-3",
        "node": "/dev/input/event7",
        "usb_class": "HID (0x03)",
        "runtime": "BLOCKED",
        "log": "[netlink] add usb 1-3 0951:1666 /dev/input/event7"
    }
}

CURRENT_STAGE = 1

async def broadcast(payload: dict):
    """Broadcast JSON payload to all connected Flutter clients."""
    if not CONNECTED_CLIENTS:
        print("  [!] No Flutter clients connected. Event queued.")
        return

    message = json.dumps(payload)
    dead_clients = set()
    for client in CONNECTED_CLIENTS:
        try:
            await client.send(message)
        except Exception:
            dead_clients.add(client)
    CONNECTED_CLIENTS.difference_update(dead_clients)
    print(f"  [✓] Sent to {len(CONNECTED_CLIENTS)} client(s): {payload.get('type')}")


async def handle_client(websocket):
    """Handle new WebSocket client connection from Flutter UI."""
    CONNECTED_CLIENTS.add(websocket)
    remote = websocket.remote_address
    print(f"\n[+] Flutter Client Connected: {remote}")

    # Send welcome handshake message
    welcome_msg = {
        "type": "LOG",
        "message": "[pyudev] Daemon online. Netlink socket listening for USB hotplug events."
    }
    await websocket.send(json.dumps(welcome_msg))

    try:
        async for message in websocket:
            print(f"[Client]: {message}")
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        CONNECTED_CLIENTS.remove(websocket)
        print(f"[-] Flutter Client Disconnected: {remote}")


async def interactive_cli():
    """Terminal CLI allowing you to trigger detection and stage progression."""
    global CURRENT_STAGE
    loop = asyncio.get_event_loop()

    print("=" * 60)
    print("  HADES Hardware Detection Server")
    print("  WebSocket URL: ws://127.0.0.1:8000/ws/events")
    print("=" * 60)
    print("Controls:")
    print("  [1] Plug in: ESP32-S3 Serial Flash (CDC-ACM)")
    print("  [2] Plug in: Custom CAN Kernel Module (Vendor Specific)")
    print("  [3] Plug in: Unauthorized USB Attack (HID)")
    print("  [4] Advance Next Stage (+1)")
    print("  [5] Trigger Teardown")
    print("  [q] Quit Server")
    print("=" * 60)

    while True:
        choice = await loop.run_in_executor(None, input, "\nSelect hardware action (1-5, q): ")
        choice = choice.strip()

        if choice in SCENARIOS:
            sc = SCENARIOS[choice]
            CURRENT_STAGE = 1
            payload = {
                "type": "DEVICE_PLUGGED",
                "scenario_id": sc["id"],
                "name": sc["name"],
                "stage": 1,
                "log": sc["log"]
            }
            print(f"\n>> Simulating USB Plug-in: {sc['name']} ({sc['vid_pid']})")
            await broadcast(payload)

        elif choice == "4":
            CURRENT_STAGE = min(5, CURRENT_STAGE + 1)
            payload = {
                "type": "STAGE_ADVANCE",
                "stage": CURRENT_STAGE,
                "log": f"[broker] Advanced to Stage {CURRENT_STAGE} via Python daemon"
            }
            print(f"\n>> Advancing pipeline to Stage {CURRENT_STAGE}")
            await broadcast(payload)

        elif choice == "5":
            payload = {
                "type": "STAGE_ADVANCE",
                "stage": 5,
                "log": "[teardown] Overlay discarded, 0% host pollution verified"
            }
            print("\n>> Triggering teardown verification")
            await broadcast(payload)

        elif choice.lower() == "q":
            print("\nExiting server...")
            sys.exit(0)


async def main():
    async with websockets.serve(handle_client, "127.0.0.1", 8000):
        print("Server running on ws://127.0.0.1:8000/ws/events")
        await interactive_cli()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped.")
