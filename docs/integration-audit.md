# HADES Desktop — Comprehensive Workspace Audit and Backend Integration Specification

**Document Version:** 2.0.0  
**Date:** October 2026  
**Author:** Senior Software Architect & Implementation Engineer  
**Workspace:** `c:\Users\gauth\Desktop\Projects\Flutter UI`  
**Subprojects Audited:**
- Flutter Desktop Application: `flutter_desktop_ui/`
- HADES Core Python Implementation: `backend/`
- Workspace Root Manifest: `.hades.yaml`

---

## 1. Executive Summary

This architecture assessment documents the verified state of the HADES desktop workspace, establishes the exact boundary between the Flutter desktop client and the HADES Core Python daemon, and specifies the complete integration plan to make the desktop application a fully functional graphical interface.

The workspace consists of two primary subprojects:
1. **`flutter_desktop_ui/`**: A modern desktop application built with Flutter 3.41+ and Dart 3.11+, featuring a custom dark-teal design system, pipeline stepper, bento-grid layout, topology visualizer, policy matrix, terminal view, and settings management.
2. **`backend/` (`hades-core`)**: A Python-based hardware discovery, two-stage resolution, deterministic policy engine, and sandbox orchestration system (`hades`).

Prior to this integration, the Flutter UI operated primarily against static mock data (`Scenario.mockScenarios`), simulated stage timers, and canned log strings. Concurrently, the Python backend provided pure domain models, topology tracking, two-stage hardware resolution, CLI commands (`hades detect`, `watch`, `init`, `up`, `list`, `shell`, `down`), and unit tests, but lacked an active HTTP REST and WebSocket API service (`hades.api`) to expose these capabilities over the network to the desktop UI.

This audit establishes the concrete contracts, schema mappings, security boundaries, and phased implementation steps required to bridge these components into a unified, secure system.

---

## 2. Actual Workspace Structure

```
c:\Users\gauth\Desktop\Projects\Flutter UI\
├── .git/
├── .gitignore
├── .hades.yaml                           # Authoritative root workspace manifest
├── backend/                              # HADES Core Python package & tests
│   ├── README.md                         # Architecture, CLI commands, and simulation presets
│   ├── pyproject.toml                    # Build metadata & dependencies (Python >=3.10)
│   ├── hades/                            # Python package source
│   │   ├── __init__.py
│   │   ├── models/                       # Pydantic v2 schemas
│   │   │   ├── __init__.py
│   │   │   ├── device.py                 # DiscoveredDevice, DeviceClassification, ResolutionStage, IsolationRecommendation
│   │   │   └── manifest.py               # HadesManifest, ProjectConfig, TargetConfig, HardwareConfig, IsolationConfig
│   │   ├── policy/                       # Deterministic sandbox policy engine
│   │   │   ├── __init__.py
│   │   │   └── engine.py                 # PolicyTarget, HardwareRequirements, PolicyDecision, select_target
│   │   ├── discovery/                    # Hardware discovery, topology tracking & udev
│   │   │   ├── __init__.py
│   │   │   ├── topology.py               # extract_port_topology, is_same_physical_port
│   │   │   ├── udev_scanner.py           # scan_usb_devices, get_usb_tty_mapping, _safe_attr
│   │   │   ├── udev_watcher.py           # UdevWatcher, UdevEvent (async udev monitoring)
│   │   │   ├── monitor.py                # DeviceMonitor, DeviceEvent (re-enumeration tracking)
│   │   │   └── simulation.py             # Hardware presets for demo & cross-platform testing
│   │   ├── resolver/                     # Two-Stage Hardware Resolution Engine
│   │   │   ├── __init__.py
│   │   │   ├── database.py               # VID:PID database for MCUs, probes, and generic bridges
│   │   │   ├── manifest.py               # load_manifest, validate_manifest, generate_preset_manifest
│   │   │   └── two_stage.py              # TwoStageResolver (Stage 1 Passive & Stage 2 Manifest Match)
│   │   └── cli/                          # Typer + Rich terminal interface
│   │       ├── __init__.py
│   │       ├── main.py                   # CLI entry point (detect, watch, init, up, shell, list, down)
│   │       ├── formatters.py             # Rich console tables and status badges
│   │       ├── sandbox.py                # SandboxSession persistent registry
│   │       └── commands/                 # Modular command handlers
│   │           ├── __init__.py
│   │           ├── detect.py             # hades detect / scan
│   │           ├── init.py               # hades init (.hades.yaml generator)
│   │           ├── sandbox.py            # hades up, list, shell, down
│   │           └── watch.py              # hades watch (real-time udev events)
│   └── tests/                            # Pytest test suite (50 tests passing)
│       ├── test_cli.py                   # CLI invocation & argument tests
│       ├── test_hades.py                 # Topology extraction, stage 1 & stage 2 resolution tests
│       ├── test_policy.py                # Policy engine tree & isolation tests
│       ├── test_sandbox.py               # Sandbox registry & command tests
│       └── test_watcher.py               # Async udev watcher & cold-plug tests
├── docs/                                 # Documentation & audits
│   └── integration-audit.md              # This document
└── flutter_desktop_ui/                   # Flutter desktop presentation client
    ├── pubspec.yaml                      # Flutter dependencies (provider, cupertino_icons)
    ├── analysis_options.yaml             # Dart lint rules
    ├── lib/
    │   ├── main.dart                     # App entry point with Provider setup
    │   ├── core/theme/
    │   │   ├── app_colors.dart           # 40+ atomic color tokens
    │   │   └── app_theme.dart            # Typography, borders, shadows, elevation
    │   ├── models/
    │   │   ├── runtime.dart              # Runtime enum (docker, qemu, blocked)
    │   │   ├── scenario.dart             # Scenario presentation model & mockScenarios fallback
    │   │   ├── stage.dart                # Pipeline Stage enum (1 to 6)
    │   │   └── dto/                      # Data Transfer Objects
    │   │       ├── audit_record.dart     # AuditRecord DTO & log line formatter
    │   │       ├── device_descriptor.dart# DeviceDescriptor DTO
    │   │       ├── device_event.dart     # DeviceEvent DTO
    │   │       ├── session_record.dart   # SessionRecord DTO
    │   │       └── telemetry_sample.dart # TelemetrySample DTO
    │   ├── screens/
    │   │   ├── startup_screen.dart       # Pre-flight diagnostic screen
    │   │   ├── dashboard_screen.dart     # Primary desktop dashboard layout
    │   │   ├── topology_view.dart        # Physical USB bus topology & VBUS visualization
    │   │   ├── policies_view.dart        # Policy matrix & YAML manifest preview
    │   │   ├── terminal_view.dart        # Diagnostic serial console & CLI attachment guidance
    │   │   └── settings_view.dart        # Backend connection URL, token, and status test
    │   ├── widgets/
    │   │   ├── nav_rail.dart             # Left 80px navigation rail
    │   │   ├── top_bar.dart              # Search pill, live status chips, operator avatar
    │   │   ├── hero_card.dart            # Active device hero, status, animated progress
    │   │   ├── isolation_boundary_card.dart # 3-node Host -> Broker -> Sandbox diagram
    │   │   ├── workflow_stepper_card.dart# 5-step animated pipeline stepper
    │   │   ├── devices_card.dart         # Connected hardware selector list & add action
    │   │   ├── stage_detail_card.dart    # Two-column metadata & stage action buttons
    │   │   ├── policy_matrix_card.dart   # Read-only policy evaluation switches
    │   │   └── event_console_card.dart   # Dark monospace real-time audit log stream
    │   ├── api/
    │   │   ├── api_config.dart           # Base URL, API token, WebSocket URL, timeout config
    │   │   ├── api_exception.dart        # Typed API exceptions & error details
    │   │   ├── hades_api_client.dart     # Typed REST HTTP client
    │   │   └── hades_ws_client.dart      # Auto-reconnecting WebSocket client
    │   ├── services/
    │   │   ├── backend_service.dart      # BackendService interface & HadesBackendService
    │   │   └── hades_repository.dart     # Repository uniting DTOs, cache, and Scenario mapping
    │   └── state/
    │       └── control_plane_controller.dart # Central ChangeNotifier controller
    └── test/
        ├── widget_test.dart              # 6 Flutter widget tests
        └── api_test.dart                 # DTO serialization & logic tests
```

---

## 3. Flutter Application Architecture

### 3.1 Framework & Core Dependencies
- **SDK:** Dart 3.11+, Flutter 3.41+ (channel stable).
- **Core Dependencies:**
  - `provider: ^6.1.5+1` for application state management and dependency injection.
  - `cupertino_icons: ^1.0.8` for icon assets.
  - Standard library `dart:io`, `dart:async`, `dart:convert`.
- **Target OS:** Native Windows x64 desktop runner (`windows/runner/`), with cross-platform targets available for macOS, Linux, and Web.

### 3.2 State Management & Presentation Flow
The presentation layer strictly decouples UI widgets from backend networking:
1. **Widgets** (`DashboardScreen`, `HeroCard`, `DevicesCard`, `StageDetailCard`, etc.) observe `ControlPlaneController` via `Consumer` or `Provider.of`.
2. **`ControlPlaneController` (`ChangeNotifier`)**:
   - Manages selected scenario/device, active stage, and aggregated log entries.
   - Provides clean operator actions: `selectScenario`, `nextStage`, `prevStage`, `triggerTeardown`, `connectToBackend`, `refreshFromBackend`.
   - Delegates hardware discovery and session queries to `HadesRepository`.
3. **`HadesRepository`**:
   - Bridges DTO models (`DeviceDescriptor`, `SessionRecord`, `AuditRecord`) to the presentation model `Scenario`.
   - Maintains cached inventory and audit records.
   - Subscribes to `HadesWebSocketClient` for real-time events (`add`, `remove`, `re-enumerated`).
4. **`HadesApiClient` & `HadesWebSocketClient`**:
   - Transport layer handling HTTP requests (`GET`, `POST`, `DELETE`) and persistent WebSocket connection with auto-reconnection and authentication.

---

## 4. HADES Core Architecture

### 4.1 Domain Components
1. **Hardware Discovery (`hades.discovery`)**:
   - `udev_scanner.py`: Enumerates USB devices using sysfs and `pyudev`, maps serial TTY device nodes (`/dev/ttyUSB*`, `/dev/ttyACM*`), and resolves hardware descriptors.
   - `topology.py`: Extracts physical port paths (e.g., `1-2.1`, `1-4`) independent of mutable USB bus numbers or device addresses.
   - `monitor.py`: Listens to kernel netlink udev events. Distinguishes hot-plug additions, removals, and bootloader re-enumerations on the same physical port path.
   - `simulation.py`: Provides 6 standardized hardware simulation presets for hardware-independent development and demo verification:
     - `esp32-native`: Native ESP32-S3 USB-JTAG/Serial (`303a:1001`).
     - `esp32-cp2102-ambiguous`: Silicon Labs CP2102 (`10c4:ea60`) without workspace manifest.
     - `esp32-cp2102-resolved`: Silicon Labs CP2102 resolved via `.hades.yaml`.
     - `stlink-v2`: STMicroelectronics ST-LINK/V2 SWD debugger (`0483:3748`).
     - `rp2040-pico`: Raspberry Pi Pico RP2040 (`2e8a:0003`).
     - `custom-kernel-device`: Device requiring kernel driver isolation (triggers QEMU/KVM VM).
2. **Two-Stage Resolver (`hades.resolver`)**:
   - `database.py`: Built-in database of known MCUs, debug probes, and generic UART bridges.
   - `two_stage.py`:
     - **Stage 1 (Passive Native Match)**: Identifies native devices (ESP32-S3, RP2040, STM32, ST-Link) directly from descriptors.
     - **Stage 2 (Manifest-Assisted Match)**: When a generic UART bridge (CP2102, CH340, FTDI) is detected, inspects `.hades.yaml` to resolve the true target board, chip family, and SDK toolchain. If no manifest is present, designates the device as `stage_2_ambiguous`.
   - `manifest.py`: Validates `.hades.yaml` files and generates presets (`esp32`, `stm32`, `pico`, `arduino`, `kernel`).
3. **Policy Engine (`hades.policy`)**:
   - `engine.py`: Deterministic decision tree selecting execution sandbox:
     - `QEMU_VM`: Required if `kernel_driver_required` or `kernel_module_required` is true.
     - `RESTRICTED_CONTAINER`: Required if `privileged_hw_access` is true.
     - `CONTAINER_WITH_BROKER`: Required if `usb_jtag_required` or `standard_serial_flashing` is true.
     - `CONTAINER`: Standard unprivileged container.
4. **Sandbox Management (`hades.cli.sandbox`)**:
   - `load_sessions` / `save_sessions`: Persistent JSON registry storing `session_id`, `workspace`, `target`, `isolation`, `hardware`, and `runtime_id`.
   - Lifecycle operations: `up_command`, `list_command`, `shell_command`, `down_command`.

---

## 5. Screen Responsibilities & Capabilities Mapping

| Screen / Widget | Current State | Intended Backend Responsibility | Integration Plan |
|---|---|---|---|
| **`StartupScreen`** | Hardcoded pre-flight cards: "ALL SUBSYSTEMS NOMINAL" | Pre-flight health check query to `GET /v1/health` | Ping backend health endpoint; reflect live daemon reachability, runtime availability, and udev status. |
| **`TopBar`** | Static chips: "pyudev UP", "WebSocket simulated" | Dynamic daemon status and live WebSocket connection state | Bind status chips to `HadesRepository.isDaemonOnline` and `wsClient.isConnected`. |
| **`HeroCard`** | Displays active `Scenario` name, runtime chip, animated progress bar | Real active session state, target board name, resolved isolation mode | Map active `SessionRecord` and `DiscoveredDevice` to hero display. |
| **`IsolationBoundaryCard`** | 3-node Host -> Broker -> Sandbox diagram with static text | Runtime isolation visualization (`container` vs `vm`), dynamic cgroup broker configuration | Display actual runtime parameters and character device node bindings. |
| **`WorkflowStepperCard`** | 5-step stepper (Detected, Resolved, Policy, Provisioned, Active) | Authoritative session lifecycle progression: `pending` -> `starting` -> `running` -> `teardown` | Synchronize stage indicator with backend session state. |
| **`DevicesCard`** | Lists 3 hardcoded `Scenario.mockScenarios` | Real connected USB hardware inventory | Populate from `GET /v1/devices` and real-time WebSocket `device` events. Support manual refresh and preset simulation selector. |
| **`StageDetailCard`** | Static key-value pairs; mock Attach IDE & Teardown buttons | Real session metadata, project workspace, target board, SDK, and teardown execution | Wire "Trigger teardown" button directly to `DELETE /v1/sessions/{id}`; wire "Attach IDE" to show exact `hades shell <session-id>` command. |
| **`PolicyMatrixCard`** | Read-only switches for policy flags | Authoritative policy decision reasons from `PolicyDecision` and manifest flags | Bind switches to active device policy flags (`allowlisted`, `kernel_module_required`, `serial_flashing`, `hid_blocked`). |
| **`EventConsoleCard`** | Monospace log card with hardcoded strings | Real-time audit log stream from `AuditRecord` and WebSocket telemetry | Stream real backend audit records (`policy_decision`, `session_started`, `cleanup_audit`) and netlink discovery events. |
| **`TopologyView`** | Static tree with toggleable VBUS switches | USB bus/address hierarchy and physical port paths | Render detected physical port paths (e.g. `1-2.1`, `1-4`) from `DiscoveredDevice.port_topology`. Mark VBUS power switching as host hardware dependent. |
| **`PoliciesView`** | Static rule matrix and YAML preview | Authoritative policy engine rules and workspace `.hades.yaml` preview | Load and display actual `.hades.yaml` from workspace root and authoritative policy rule table. |
| **`TerminalView`** | Simulated ESP-ROM serial prompt | Host-isolated firmware UART monitor / diagnostic console | Clarify that host interactive shells run via `hades shell` on the host, while providing a functional serial monitor interface. |
| **`SettingsView`** | Text inputs for API base URL and token | Configurable backend connection settings | Allow operator to configure API URL (e.g., `http://127.0.0.1:8080`), API token, and verify connectivity with a live test button. |

---

## 6. Existing Mock Data and Placeholders to Replace

1. **`Scenario.mockScenarios` (`lib/models/scenario.dart`)**:
   - Contains 3 static scenarios (`esp32_s3`, `can_module`, `unauthorized_hid`).
   - *Resolution:* Preserved as fallback for offline demo / unit testing; dynamically superseded by real `DiscoveredDevice` inventory and active sessions from `HadesRepository`.
2. **`MockBackendService` (`lib/services/backend_service.dart`)**:
   - Contains canned log lists for each stage.
   - *Resolution:* Replaced by `HadesBackendService` which retrieves real `AuditRecord` logs and WebSocket events from `HadesRepository`.
3. **Auto-Run Timer (`_autoRunTimer` in `ControlPlaneController`)**:
   - 1400ms interval timer that simulated stage progression.
   - *Resolution:* Stage progression is driven by real backend operations (`createSession`, `stopSession`, WebSocket event updates).
4. **Static Status Chips in `TopBar`**:
   - Displayed static "pyudev UP" and "WebSocket simulated".
   - *Resolution:* Updated to dynamically reflect live daemon health and WebSocket status.

---

## 7. Actual Backend APIs and Schemas

### 7.1 Backend Pydantic Schemas (`backend/hades/models/device.py`)
```python
class DiscoveredDevice(BaseModel):
    device_id: str                      # e.g. "usb:10c4:ea60:1-4"
    vendor_id: str                      # 4-digit lowercase hex
    product_id: str                     # 4-digit lowercase hex
    vendor_name: str                    # Manufacturer name
    product_name: str                   # Product name
    serial_number: Optional[str]        # USB serial descriptor
    bus_num: int                        # USB Bus Number
    dev_num: int                        # USB Device Number on the bus
    port_topology: str                  # Physical port hierarchy (e.g. "1-2.1")
    dev_node: Optional[str]             # Linux character device node (/dev/bus/usb/001/004)
    sys_path: str                       # Linux sysfs path
    sys_name: str                       # Kernel sysfs name (e.g. "1-4")
    tty_nodes: List[str]                # Serial nodes (e.g. ["/dev/ttyUSB0"])
    classification: DeviceClassification# native_mcu, debug_probe, generic_uart_bridge, etc.
    target_board: Optional[str]         # Identified board (e.g. "ESP32-S3-DevKitC-1")
    target_chip: Optional[str]          # Identified chip family (e.g. "ESP32-S3")
    recommended_sdk: Optional[str]      # Default toolchain (e.g. "esp-idf")
    resolution_stage: ResolutionStage   # stage_1_passive, stage_2_manifest, stage_2_ambiguous
    isolation_recommendation: IsolationRecommendation # container_broker, qemu_vm, reject_policy
    resolution_notes: str               # Human-readable explanation
    kernel_module_required: bool        # Host kernel module flag
    kernel_driver_required: bool        # Host kernel driver isolation flag
    privileged_hw_access: bool          # Privileged hardware access flag
    usb_jtag_required: bool             # USB JTAG flag
    usb_interfaces: List[str]           # USB interfaces
```

### 7.2 Manifest Schemas (`backend/hades/models/manifest.py`)
```python
class HadesManifest(BaseModel):
    version: str = "1.0"
    project: ProjectConfig              # name, version, description
    target: TargetConfig                # board, chip, arch, sdk, sdk_version
    hardware: HardwareConfig            # interface, baud_rate, bridge_hint, kernel_module_required...
    isolation: IsolationConfig          # preferred_mode, ephemeral, base_image
```

### 7.3 Sandbox Session Schema (`backend/hades/cli/sandbox.py`)
```python
class SandboxSession:
    session_id: str                     # 12-char hex string
    workspace: str                      # Absolute directory path
    target: str                         # Board identifier
    isolation: str                      # "container" or "vm"
    hardware: list[str]                 # Bound device_ids
    runtime_id: Optional[str]           # Container ID or domain name
```

---

## 8. Backend Capabilities Exposed to Flutter via HADES API Service

Because `backend/` was previously structured as a CLI and library, we implement the lightweight, secure FastAPI application (`hades/api/`) exposing the following endpoints:

1. **`GET /v1/health`**:
   - Returns daemon health, udev status, runtime availability (`docker`, `qemu`), and version.
2. **`GET /v1/devices`**:
   - Query parameters: `all: bool = False`, `workspace: Optional[str] = None`, `simulate: Optional[str] = None`.
   - Returns `list[DiscoveredDevice]`. Supports querying live devices or returning simulation presets for testing.
3. **`POST /v1/devices/resolve`**:
   - Body: `DiscoveredDevice` + optional workspace path.
   - Re-evaluates two-stage resolution against the workspace `.hades.yaml`.
4. **`GET /v1/manifest`**:
   - Query parameter: `workspace: Optional[str] = None`.
   - Returns loaded `HadesManifest` or null with validation error details.
5. **`POST /v1/manifest/init`**:
   - Body: `preset: str`, `workspace: Optional[str] = None`, `force: bool = False`.
   - Initializes a valid `.hades.yaml` manifest.
6. **`GET /v1/sessions`**:
   - Returns `list[SandboxSession]`.
7. **`POST /v1/sessions`**:
   - Body: `manifest_path: str`, `device: DiscoveredDevice`.
   - Evaluates policy, provisions sandbox, registers session, and records audit entry.
8. **`GET /v1/sessions/{id}`**:
   - Returns `SandboxSession` with lifecycle status.
9. **`DELETE /v1/sessions/{id}`**:
   - Terminates sandbox, releases hardware cgroup mappings, audits host cleanup, and returns audit report.
10. **`GET /v1/sessions/{id}/audit`**:
    - Returns list of `AuditRecord` entries for the session.
11. **`WS /v1/ws/*` & `WS /v1/ws/{session_id}`**:
    - Streams live udev events (`add`, `remove`, `re-enumerated`), stage transitions, and telemetry.

---

## 9. Device Identity and Re-Enumeration Design

### 9.1 Identity Separation
We enforce strict separation between:
1. **Physical Identity**: Represented by `stable_id` = `usb:{vendor_id}:{product_id}:{port_topology}` or `serial_number`. Physical identity never changes during device resets.
2. **Connection State**: Mutable properties (`bus_num`, `dev_num`, `dev_node`, `tty_nodes`).
3. **Hardware Resolution**: Target board and toolchain identity (`target_board`, `target_chip`, `recommended_sdk`, `resolution_stage`).
4. **Authorization State**: Evaluated against `.hades.yaml` allowlists and policy engine.
5. **Session Association**: Bound `session_id` and container/VM cgroup device access.

### 9.2 Topology-Aware Re-Enumeration
When microcontrollers reset into bootloader mode during firmware flashing:
- Linux kernel drops the existing device node (e.g., `/dev/bus/usb/001/004`) and assigns a new device number (e.g., `/dev/bus/usb/001/005`).
- The physical port topology path (`port_topology`, e.g. `1-2.1`) remains constant.
- The backend `DeviceMonitor` emits a `re-enumerated` event.
- The Flutter client matches the device by `port_topology` and updates connection properties without discarding active session context or generating spurious devices.

---

## 10. Cross-Platform Execution Model (Windows vs. Linux)

1. **Host Separation**:
   - **Flutter Client**: Runs on Windows desktop as the operator interface.
   - **HADES Core Daemon**: Runs on a Linux host (or WSL2 / Linux VM) where Linux kernel netlink, `/dev/` character nodes, cgroups, and Docker/KVM runtimes exist.
2. **Safe Fallback & Simulation**:
   - Python code includes safe fallback imports for `pyudev` (`try: import pyudev except ImportError: pyudev = None`) to allow unit testing, CLI help, simulation presets, and FastAPI service execution on non-Linux development machines.
   - Flutter client includes configurable API endpoints (`SettingsView`) with defaults for local testing (`http://127.0.0.1:8080`) and offline demo modes.

---

## 11. Security and Reliability Requirements

HADES is a security-sensitive developer tool:
- **No Remote Shell Endpoint**: The API explicitly forbids arbitrary shell commands or remote bash execution over HTTP/WebSocket. For interactive shell access, the operator must execute `hades shell <session-id>` locally on the host.
- **Strict Least Privilege**: Containers run with unprivileged user, read-only root, dropped capabilities, no Docker socket mounts, and explicit character device cgroup allow rules.
- **Deterministic Isolation Policy**: Kernel drivers or privileged requests strictly escalate to QEMU/KVM virtual machine isolation.
- **Append-Only Auditing**: Every policy evaluation, session launch, and teardown cleanup is recorded in an audit trail.

---

## 12. Implementation Plan and Acceptance Criteria

1. **Phase 1: Workspace Audit (Complete)**:
   - Comprehensive audit of both codebases documented in `docs/integration-audit.md`.
2. **Phase 2: Backend API Layer (`hades.api`)**:
   - Implement FastAPI application exposing health, devices, manifest, session lifecycle, and WebSocket event hub.
   - Run unit and integration tests.
3. **Phase 3: Flutter DTO and Model Alignment**:
   - Align Dart DTOs (`DeviceDescriptor`, `SessionRecord`, `AuditRecord`, `DeviceEvent`) with the backend schemas.
4. **Phase 4: Flutter API Client & Repository**:
   - Ensure `HadesApiClient` and `HadesWebSocketClient` interact with verified backend routes.
   - Implement scenario mapping, caching, and stream updates in `HadesRepository`.
5. **Phase 5: UI Integration**:
   - Connect `ControlPlaneController` to live discovery, manifest resolution, session creation, teardown, and telemetry.
   - Preserve all existing widgets, layouts, styling, and navigation.
6. **Phase 6: Testing & Verification**:
   - Execute all Flutter widget tests (`flutter test`).
   - Execute all Python backend tests (`pytest tests/`).
   - Run static analysis (`flutter analyze`).
