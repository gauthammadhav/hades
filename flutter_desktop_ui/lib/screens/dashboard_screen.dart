import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../state/control_plane_controller.dart';
import '../widgets/devices_card.dart';
import '../widgets/event_console_card.dart';
import '../widgets/hero_card.dart';
import '../widgets/isolation_boundary_card.dart';
import '../widgets/nav_rail.dart';
import '../widgets/policy_matrix_card.dart';
import '../widgets/stage_detail_card.dart';
import '../widgets/top_bar.dart';
import '../widgets/workflow_stepper_card.dart';
import 'policies_view.dart';
import 'settings_view.dart';
import 'terminal_view.dart';
import 'topology_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FocusNode _focusNode = FocusNode();
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final controller = context.read<ControlPlaneController>();
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        controller.nextStage();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        controller.prevStage();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        controller.toggleAutoRun();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Row(
          children: [
            // Left 80px navigation rail
            HadesNavRail(
              activeIndex: _selectedNavIndex,
              onIndexChanged: (index) {
                setState(() => _selectedNavIndex = index);
              },
            ),

            // Main inset rounded panel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Consumer<ControlPlaneController>(
                      builder: (context, controller, child) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 22,
                                  ),
                                  child: _buildCurrentView(controller),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView(ControlPlaneController controller) {
    switch (_selectedNavIndex) {
      case 1:
        return const TopologyView();
      case 2:
        return const PoliciesView();
      case 3:
        return const TerminalView();
      case 4:
        return const SettingsView();
      case 0:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top bar
            const HadesTopBar(),
            const SizedBox(height: 18),

            // Row 1: Hero Card + Isolation Boundary Card
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 46,
                    child: HeroCard(
                      scenario: controller.selectedScenario,
                      currentStage: controller.currentStage,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 54,
                    child: IsolationBoundaryCard(
                      scenario: controller.selectedScenario,
                      currentStage: controller.currentStage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Row 2: Workflow Pipeline Stepper Card
            WorkflowStepperCard(
              scenario: controller.selectedScenario,
              currentStage: controller.currentStage,
            ),
            const SizedBox(height: 18),

            // Row 3: Bento Columns
            SizedBox(
              height: 320,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Devices Card
                  Expanded(
                    flex: 28,
                    child: DevicesCard(
                      scenarios: controller.scenarios,
                      selectedScenario: controller.selectedScenario,
                      onSelectScenario: (scenario) {
                        controller.selectScenario(
                          scenario,
                          resetToStage1: true,
                        );
                      },
                      onSimulatePlugin: () {
                        controller.startAutoRun();
                      },
                      onSelectPreset: (preset) {
                        controller.loadSimulatedPreset(preset);
                      },
                      onRefreshHardware: () {
                        controller.refreshFromBackend();
                      },
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Stage Detail Card
                  Expanded(
                    flex: 34,
                    child: StageDetailCard(
                      scenario: controller.selectedScenario,
                      currentStage: controller.currentStage,
                      onAttachIde: controller.attachIde,
                      onTriggerTeardown: controller.triggerTeardown,
                      onResolveBridge: () {
                        controller.resolveSelectedDevice();
                      },
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column: Policy Matrix + Event Stream
                  Expanded(
                    flex: 38,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 48,
                          child: PolicyMatrixCard(
                            scenario: controller.selectedScenario,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 52,
                          child: EventConsoleCard(
                            eventLogs: controller.eventLogs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
