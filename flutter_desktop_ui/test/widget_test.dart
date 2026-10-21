import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_desktop_ui/main.dart';
import 'package:flutter_desktop_ui/models/scenario.dart';
import 'package:flutter_desktop_ui/models/stage.dart';
import 'package:flutter_desktop_ui/screens/dashboard_screen.dart';
import 'package:flutter_desktop_ui/state/control_plane_controller.dart';

void main() {
  group('HADES Control Plane Comprehensive Tests', () {
    testWidgets('StartupScreen pre-flight checks and launch to dashboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const HadesApp());
      await tester.pumpAndSettle();

      // Verify Startup Screen elements
      expect(find.text('HADES v1.0.4 · HARDWARE SANDBOX'), findsOneWidget);
      expect(find.text('Pre-Flight System Status'), findsOneWidget);
      expect(find.text('ALL SUBSYSTEMS NOMINAL'), findsOneWidget);
      expect(find.text('pyudev Monitor'), findsOneWidget);
      expect(find.text('Container Broker'), findsOneWidget);
      expect(find.text('VM Hypervisor'), findsOneWidget);
      expect(find.text('Launch Control Plane'), findsOneWidget);

      // Tap Launch Control Plane
      await tester.tap(find.text('Launch Control Plane'));
      await tester.pumpAndSettle();

      // Verify Dashboard Screen is now active
      expect(find.text('Control Plane'), findsOneWidget);
      expect(find.text('Hardware-aware sandbox orchestration'), findsOneWidget);
      expect(find.text('Workflow pipeline'), findsOneWidget);
    });

    testWidgets('Reference 1: ESP32-S3 at Stage 5 SESSION_ACTIVE', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const HadesApp(home: DashboardScreen()));
      await tester.pump();

      // Top bar
      expect(find.text('Control Plane'), findsOneWidget);
      expect(find.text('pyudev UP'), findsOneWidget);
      expect(find.text('WebSocket simulated'), findsOneWidget);

      // Hero Card for ESP32-S3 Stage 5
      expect(find.text('DOCKER_CONTAINER'), findsWidgets);
      expect(find.text('ESP32-S3 Serial Flash'), findsNWidgets(2));
      expect(find.text('usb 1-2.1 · 303A:1001 · /dev/ttyACM0'), findsOneWidget);
      expect(find.text('Session active'), findsWidgets);
      expect(find.text('Stage 5/5'), findsOneWidget);

      // Isolation Boundary
      expect(find.text('Isolation boundary'), findsOneWidget);
      expect(find.text('Host USB port'), findsOneWidget);
      expect(find.text('HADES broker'), findsOneWidget);
      expect(find.text('Isolated sandbox'), findsOneWidget);
      expect(find.text('/workspace overlay'), findsOneWidget);
      expect(
        find.text('Broker: cgroup device allow, no --privileged'),
        findsOneWidget,
      );

      // Workflow pipeline
      expect(find.text('Workflow pipeline'), findsOneWidget);
      expect(find.text('DEVICE_DETECTED'), findsOneWidget);
      expect(find.text('SESSION_ACTIVE'), findsOneWidget);

      // Stage Detail Card
      expect(find.text('Stage 5'), findsOneWidget);
      expect(
        find.text('Terminal / IDE attached via hades attach'),
        findsOneWidget,
      );
      expect(find.text('Overlay discarded, device released'), findsOneWidget);
      expect(find.text('0% host pollution verified'), findsWidgets);
      expect(find.text('Attach IDE'), findsOneWidget);
      expect(find.text('Trigger teardown'), findsOneWidget);

      // Policy Matrix
      expect(find.text('Policy matrix'), findsOneWidget);
      expect(find.text('Allow-listed class'), findsOneWidget);
      expect(find.text('Kernel module required'), findsOneWidget);
      expect(find.text('Serial / JTAG only'), findsOneWidget);
      expect(find.text('HID / mass-storage class'), findsOneWidget);

      // Event Stream
      expect(find.text('Event stream'), findsOneWidget);
      expect(find.text('[policy] ALLOW -> DOCKER_CONTAINER'), findsOneWidget);
      expect(
        find.text('[broker] cgroup device allow, no --privileged'),
        findsOneWidget,
      );
      expect(find.text('[fs] overlay mounted /workspace'), findsOneWidget);
      expect(find.text('[session] IDE attached'), findsOneWidget);
      expect(find.text('[teardown] overlay discarded'), findsOneWidget);
      expect(find.text('[audit] host pollution: 0%'), findsOneWidget);
    });

    testWidgets('Reference 2: CAN Module at Stage 3 POLICY_EVALUATED', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = ControlPlaneController(
        initialScenario: Scenario.mockScenarios[1], // Custom CAN Kernel Module
        initialStage: Stage.policyEvaluated,
      );

      await tester.pumpWidget(
        HadesApp(controller: controller, home: const DashboardScreen()),
      );
      await tester.pump();

      // Hero Card for CAN Module Stage 3
      expect(find.text('QEMU_KVM_VM'), findsWidgets);
      expect(find.text('Custom CAN Kernel Module'), findsNWidgets(2));
      expect(
        find.text('usb 1-4 · 1D50:606F · /dev/bus/usb/001/007'),
        findsOneWidget,
      );
      expect(find.text('Policy evaluated'), findsWidgets);
      expect(find.text('Stage 3/5'), findsOneWidget);

      // Isolation Boundary
      expect(
        find.text('Broker: libvirt hostdev hotplug, CoW qcow2 VM'),
        findsOneWidget,
      );

      // Stage Detail Card
      expect(find.text('Stage 3'), findsOneWidget);
      expect(
        find.text('Proprietary .ko driver needs guest kernel'),
        findsOneWidget,
      );

      // Event Stream lines
      expect(
        find.text('[netlink] add usb 1-4 1D50:606F /dev/bus/usb/001/007'),
        findsOneWidget,
      );
      expect(
        find.text('[pyudev] class: Vendor specific (0xFF)'),
        findsOneWidget,
      );
      expect(
        find.text('[manifest] .hades.yaml matched, arch=arm-none-eabi'),
        findsOneWidget,
      );
      expect(find.text('[policy] ALLOW -> QEMU_KVM_VM'), findsOneWidget);
    });

    testWidgets('Reference 3: Unauthorized USB Attack at Stage 3 BLOCKED', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = ControlPlaneController(
        initialScenario: Scenario.mockScenarios[2], // Unauthorized USB Attack
        initialStage: Stage.policyEvaluated,
      );

      await tester.pumpWidget(
        HadesApp(controller: controller, home: const DashboardScreen()),
      );
      await tester.pump();

      // Hero Card for Blocked HID
      expect(find.text('BLOCKED'), findsWidgets);
      expect(find.text('Unauthorized USB Attack'), findsNWidgets(2));
      expect(
        find.text('usb 1-3 · 0951:1666 · /dev/input/event7'),
        findsOneWidget,
      );
      expect(find.text('Blocked by policy'), findsOneWidget);
      expect(find.text('Stage 3/5'), findsOneWidget);

      // Isolation Boundary
      expect(find.text('Access denied'), findsWidgets);
      expect(find.text('no session'), findsOneWidget);
      expect(find.text('Broker: none, access denied'), findsOneWidget);

      // Stage Detail Card has alert box instead of buttons
      expect(
        find.text('Least-privilege policy blocked this device class.'),
        findsOneWidget,
      );
      expect(find.text('Attach IDE'), findsNothing);
      expect(find.text('Trigger teardown'), findsNothing);

      // Event Stream DENY line
      expect(
        find.text('[policy] DENY HID (0x03): HID/mass storage not approved'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Responsive resizing: 1280x800 up to 1920x1080 without overflow',
      (tester) async {
        const testSizes = [
          Size(1280, 800),
          Size(1366, 768),
          Size(1440, 900),
          Size(1600, 900),
          Size(1920, 1080),
        ];

        for (final size in testSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(const HadesApp(home: DashboardScreen()));
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Failed at size $size',
          );
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets('Keyboard navigation and auto-run test', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const HadesApp(home: DashboardScreen()));
      await tester.pump();

      // Select CAN module (resets to Stage 1)
      await tester.tap(find.text('Custom CAN Kernel Module').last);
      await tester.pump();

      expect(find.text('Stage 1/5'), findsOneWidget);

      // Press Right Arrow key to advance to Stage 2
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('Stage 2/5'), findsOneWidget);

      // Press Right Arrow key to advance to Stage 3
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('Stage 3/5'), findsOneWidget);
      expect(find.text('Policy evaluated'), findsWidgets);

      // Press Left Arrow key to go back to Stage 2
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(find.text('Stage 2/5'), findsOneWidget);
    });
  });
}
