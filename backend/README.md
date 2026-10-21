# HADES: Hardware-Aware Development Sandbox

**HADES** automates the pipeline from physical USB plug-in to isolated environment provisioning and verified teardown for embedded systems.

This repository implements the **Hardware Discovery Layer**, **Port Topology Tracker**, **Two-Stage Resolver**, and **Operator CLI (`hades`)** in a modular monolith architecture.

---

## 1. Architectural Highlights & Gaps Solved

### Gap A: Two-Stage Discovery for Generic USB-to-UART Bridges
* **Problem:** Many microcontroller boards (ESP32 DevKit, Arduino Nano clones, STM32 BluePill) use generic bridge chips like the Silicon Labs CP2102 (`10c4:ea60`) or WCH CH340 (`1a86:7523`). Standard `VID:PID` checks only report a generic serial converter, not the target board.
* **HADES Solution:**
  1. **Stage 1 (Passive Native Match):** Directly matches native USB devices (e.g., ESP32-S3 USB-JTAG `303a:1001`, Raspberry Pi Pico RP2040 `2e8a:0003`, ST-Link/V2 `0483:3748`) via `pyudev` USB descriptors.
  2. **Stage 2 (Project Manifest Match):** When a generic UART bridge is detected, HADES inspects the workspace for a `.hades.yaml` manifest. If present, it resolves the target board (e.g., `esp32-devkit-v1`), chip family, and SDK toolchain. If absent, it alerts the developer with a clear `⚠ Ambiguous Bridge` notice and offers 1-click initialization.

### Gap B: Physical Port Topology Tracking for USB Reset & Re-Enumeration
* **Problem:** Flashing firmware causes microcontrollers to reset into bootloader mode, disconnecting from USB and re-enumerating with a new device node number (e.g. `/dev/bus/usb/001/004` $\rightarrow$ `/dev/bus/usb/001/005`). Static container `--device` mappings break immediately.
* **HADES Solution:**
  * Tracks physical USB port topology paths (e.g. `1-2.1` or `1-4`) via sysfs hierarchy.
  * When a reset occurs on that physical port, HADES detects the re-enumeration in real-time, allowing the Hardware Broker to dynamically update container device cgroups without restarting the container or requiring `--privileged` mode.

---

## 2. CLI Usage & Commands

Activate the virtual environment:
```bash
source .venv/bin/activate
```

### One-Shot Hardware Detection
```bash
# Scan connected development hardware
hades detect

# Include internal host controllers and system peripherals
hades detect --all

# Output structured JSON for FastAPI / Flutter Desktop integration
hades detect --json
```

### Live Event Monitoring
```bash
# Monitor USB plug, unplug, and microcontroller reset events in real-time via netlink
hades watch
```

### Project Manifest Initialization
```bash
# Initialize a .hades.yaml manifest for ESP32
hades init --preset esp32

# Other supported presets: stm32, pico, arduino, kernel
hades init --preset stm32
```

### Sandbox Lifecycle Management
```bash
# Launch a sandbox container for the current workspace with mapped hardware
hades up

# List running sandbox sessions and bound hardware devices
hades list

# Connect an interactive shell to an active sandbox session
hades shell <session-id>

# Teardown a sandbox session, release hardware mappings, and display cleanup audit
hades down <session-id>
```

### Demonstration & Testing Simulation Presets
Test all architecture edge cases without physical hardware connected:
```bash
# Stage 1: Native ESP32-S3 USB-JTAG
hades detect --simulate esp32-native

# Stage 2: Generic CP2102 Bridge (Unresolved / Ambiguous)
hades detect --simulate esp32-cp2102-ambiguous -w /tmp

# Stage 2: Generic CP2102 Bridge (Resolved via .hades.yaml)
hades detect --simulate esp32-cp2102-resolved

# Stage 1: ST-LINK/V2 SWD Debugger
hades detect --simulate stlink-v2

# Policy Engine: Custom device requiring host kernel driver (QEMU/KVM VM)
hades detect --simulate custom-kernel-device
```

---

## 3. Package Structure

```
hades/
├── models/             # Pydantic schemas (DiscoveredDevice, HadesManifest, IsolationRecommendation)
├── policy/             # Deterministic sandbox target selection & policy engine
├── discovery/          # pyudev USB/TTY scanners, topology tracker, netlink monitor
│   ├── udev_scanner.py # Active system scan and TTY mapping
│   ├── udev_watcher.py # Asynchronous event monitoring and device tracking
│   ├── topology.py     # Physical port hierarchy (e.g. 1-2.1)
│   ├── monitor.py      # Real-time event monitor with re-enumeration handling
│   └── simulation.py   # Presets for tests and mentor demos
├── resolver/           # Two-stage resolution and hardware database
│   ├── database.py     # VID:PID database for MCUs, probes, and bridges
│   ├── manifest.py     # .hades.yaml loader and validator
│   └── two_stage.py    # Core Two-Stage resolution engine
└── cli/                # Typer + Rich terminal interface
    ├── main.py         # Entrypoint (`detect`, `watch`, `init`, `up`, `shell`, `list`, `down`)
    ├── formatters.py   # Rich console tables and status badges
    ├── sandbox.py      # Sandbox session registry
    └── commands/       # Modular command handlers
```

---

## 4. Running Tests

```bash
pytest tests/
```
All unit tests cover topology extraction, descriptor matching, manifest resolution, policy selection, kernel driver VM elevation, udev watcher, sandbox session lifecycle, and CLI operations.
