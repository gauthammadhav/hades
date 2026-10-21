# HADES Control Plane — Desktop UI & Backend Integration

HADES (Hardware-Aware Ephemeral Development Sandbox) is a security-conscious framework for hardware developers. It maps explicitly approved physical USB development boards into ephemeral Docker containers or transient libvirt/KVM virtual machines with zero host pollution.

This repository houses the Flutter Desktop application providing real-time device visualization, pipeline orchestration, policy matrix inspection, and session management.

---

## 1. System Architecture

The desktop application integrates directly with the HADES Core daemon over typed HTTP REST and WebSocket connections:

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter Desktop Application               │
│  [StartupScreen]  [DashboardScreen]  [Topology]  [Settings] │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│             ControlPlaneController (Provider)               │
│  State machine, device selection, active session, logs      │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      Repository Layer                       │
│    HadesRepository:                                         │
│    - Authoritative device inventory & live event stream     │
│    - Active & persisted session management                  │
│    - Teardown & audit trail inspection                      │
│    - Seamless fallback to reference models when offline     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      Typed API Clients                      │
│    HadesApiClient (HTTP)        HadesWebSocketClient (WS)   │
│    - Configurable base URL      - Auto-reconnect            │
│    - Bearer authorization       - Live netlink & telemetry  │
│    - DTO serialization          - Session/all topics        │
└──────────────────────────────┬──────────────────────────────┘
                               │ TCP/IP Network (HTTP / WS)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 HADES Core Daemon (Linux Host)              │
│  FastAPI /v1/routes             /v1/ws/{topic}              │
│  - GET /v1/health               - WS /v1/ws/{session_id}    │
│  - GET /v1/devices              - WS /v1/ws/*               │
│  - GET /v1/sessions                                         │
│  - POST /v1/sessions                                        │
│  - DELETE /v1/sessions/{id}                                 │
│  - GET /v1/sessions/{id}/audit                              │
│                                                             │
│  Core Services:                                             │
│  pyudev Monitor → Resolver → PolicyEngine → Docker / KVM   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure

```
flutter_desktop_ui/
├── docs/
│   └── integration-audit.md           # Full architectural assessment & integration audit
├── lib/
│   ├── api/
│   │   ├── api_config.dart            # Base URL, token, and WS URL generator
│   │   ├── api_exception.dart         # Typed HTTP status & network exceptions
│   │   ├── hades_api_client.dart      # Strongly-typed HTTP client
│   │   └── hades_ws_client.dart       # Live WebSocket event & telemetry client
│   ├── core/
│   │   └── theme/
│   │       ├── app_colors.dart        # Mint, teal, lavender atomic color tokens
│   │       └── app_theme.dart         # Radius, spacing, and elevation tokens
│   ├── models/
│   │   ├── dto/
│   │   │   ├── audit_record.dart      # AuditRecord DTO
│   │   │   ├── device_descriptor.dart # HardwareDescriptor DTO (VID, PID, serial, node)
│   │   │   ├── device_event.dart      # Netlink DeviceEvent DTO (add, remove, change)
│   │   │   ├── session_record.dart    # SessionRecord DTO
│   │   │   └── telemetry_sample.dart  # TelemetrySample DTO
│   │   ├── runtime.dart               # Runtime enum (docker, qemu, blocked)
│   │   ├── scenario.dart              # UI Scenario domain entity
│   │   └── stage.dart                 # Pipeline Stage enum (1 to 6)
│   ├── screens/
│   │   ├── dashboard_screen.dart      # Bento grid control plane view
│   │   ├── policies_view.dart         # Policy matrix & YAML preview
│   │   ├── settings_view.dart         # Daemon connection & telemetry settings
│   │   ├── startup_screen.dart        # Pre-flight diagnostic & animated launch
│   │   ├── terminal_view.dart         # Local UART console & security guidance
│   │   └── topology_view.dart         # USB root hub tree & port power states
│   ├── services/
│   │   ├── backend_service.dart       # BackendService & HadesBackendService
│   │   └── hades_repository.dart      # Repository with domain adapters
│   ├── state/
│   │   └── control_plane_controller.dart # Central ChangeNotifier controller
│   ├── widgets/
│   │   ├── devices_card.dart          # Device selector card
│   │   ├── event_console_card.dart    # Monospace auto-scrolling log console
│   │   ├── hero_card.dart             # Status gradient card & progress bar
│   │   ├── isolation_boundary_card.dart # 3-node Host -> Broker -> Sandbox diagram
│   │   ├── nav_rail.dart              # Left navigation rail
│   │   ├── policy_matrix_card.dart    # Security switches
│   │   ├── stage_detail_card.dart     # Key-value metadata & action buttons
│   │   ├── top_bar.dart               # Top bar with live status indicators
│   │   └── workflow_stepper_card.dart # 5-step pipeline stepper
│   └── main.dart                      # App entry point
└── test/
    ├── api_test.dart                  # DTO serialization, API & WS unit tests
    └── widget_test.dart               # 6 comprehensive UI widget tests
```

---

## 3. Supported Execution Environments

| Component | Platform | Requirements |
|---|---|---|
| **Flutter Desktop App** | Windows 10/11, macOS, Linux | Flutter 3.20+, Dart 3.11+ |
| **HADES Core Daemon** | Linux Host / VM / WSL2 | Python 3.12+, Linux kernel, Docker engine, libvirt/KVM, udev |

### Cross-Environment Networking
- When running Flutter on Windows and HADES Core in WSL2 or a separate Linux VM:
  1. Determine the Linux IP: `ip addr show eth0` (e.g. `172.x.x.x` or `192.168.x.x`).
  2. If using WSL2 with mirrored networking or loopback: `http://127.0.0.1:8080`.
  3. Ensure HADES daemon listens on all interfaces: `hadesd --host 0.0.0.0 --port 8080`.
  4. In the Flutter app, open **Settings** (gear/adjust icon in the nav rail), enter the Base URL, and click **Connect to Backend Daemon**.

---

## 4. Starting HADES Core on Linux

1. Clone and install `hades-core`:
   ```bash
   cd hades-core
   python3.12 -m venv .venv
   source .venv/bin/activate
   pip install -e '.[test,usb]'
   ```
2. Configure environment:
   ```bash
   export HADES_ALLOWED_WORKSPACE_ROOTS='["/home/user/workspace"]'
   export HADES_API_TOKEN="my-secure-token"
   export HADES_API_HOST="0.0.0.0"
   export HADES_API_PORT="8080"
   ```
3. Run the daemon:
   ```bash
   hadesd
   # Or using uvicorn directly:
   uvicorn hades.main:app --host 0.0.0.0 --port 8080
   ```

---

## 5. Device Identification & Security Boundaries

1. **Physical Identity:**
   - Identification uses `stable_id` formatted as `vid:pid:serial` (when serial is present) or `vid:pid:bus-address` (when serial is absent).
   - Identical boards on different USB ports are assigned unique topology IDs.
2. **Authorization Enforcement:**
   - Hardware detection alone does NOT authorize a device.
   - HADES Core checks `.hades.yaml` `hardware.allow` selectors before creating any session.
3. **Least-Privilege Isolation:**
   - Standard CDC-ACM serial boards run in unprivileged Docker containers (read-only root, capabilities dropped, single character device node).
   - Untrusted projects, kernel modules, privileged flags, or raw USB escalate to KVM virtual machines.
4. **No Remote Arbitrary Shell:**
   - The REST and WebSocket APIs intentionally have NO remote shell endpoint.
   - For an interactive shell, run `hades shell <session-id>` locally on the Linux host.

---

## 6. Running Tests

### Flutter Tests:
```bash
cd flutter_desktop_ui
flutter test
flutter analyze
```

### Python Backend Tests:
```bash
cd hades-core
.\.venv\Scripts\pytest -v
```

---

## 7. Current Limitations & Production Readiness

- **cgroup v2 Dynamic Re-enumeration:** Docker engine cannot dynamically attach new device nodes under cgroup v2 without restarting the container or using a VM.
- **TLS Configuration:** For remote daemon deployments, TLS termination (via reverse proxy or Unix domain socket) is recommended to protect bearer tokens.
- **Hardware-dependent tests:** Tests requiring live physical USB boards or active libvirt QEMU domains require a native Linux host with appropriate hardware connected. All other unit tests run completely hardware-free.
