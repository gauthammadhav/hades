import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/device_detail_panel.dart';
import '../widgets/device_inventory_table.dart';
import '../widgets/hardware_event_feed.dart';
import '../widgets/summary_metrics_bar.dart';
import '../widgets/top_bar.dart';
import 'settings_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0; // 0 = Hardware, 1 = Settings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _NavRail(
            selectedIndex: _navIndex,
            onChanged: (i) => setState(() => _navIndex = i),
          ),
          Expanded(
            child: _navIndex == 1
                ? const _PageWrapper(child: SettingsView())
                : const _HardwareDashboard(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation rail (Deep Spruce Dark Green)
// ---------------------------------------------------------------------------

class _NavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _NavRail({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      color: AppColors.navRailBg,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo Mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x24FFFFFF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0x33FFFFFF), width: 1),
            ),
            alignment: Alignment.center,
            child: const Text(
              'H',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _NavItem(
            icon: Icons.developer_board_rounded,
            label: 'Hardware Dashboard',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.tune_rounded,
            label: 'Settings & Host Daemon',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.label,
          preferBelow: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.navActiveTile
                  : _hovered
                      ? const Color(0x14FFFFFF)
                      : AppColors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: widget.selected
                  ? Border.all(color: const Color(0x40FFFFFF), width: 1)
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.selected ? AppColors.white : AppColors.navMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main hardware dashboard layout
// ---------------------------------------------------------------------------

class _HardwareDashboard extends StatelessWidget {
  const _HardwareDashboard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Header
        const HadesTopBar(),

        // Content Area with Light Spruce Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Metrics KPI cards
                const SummaryMetricsBar(),
                const SizedBox(height: 14),

                // Middle area: Table (62%) + Inspector Panel (38%)
                Expanded(
                  flex: 64,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Expanded(
                        flex: 62,
                        child: DeviceInventoryTable(),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        flex: 38,
                        child: DeviceDetailPanel(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom: Hardware Event Feed
                const SizedBox(
                  height: 175,
                  child: HardwareEventFeed(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page wrapper for settings etc.
// ---------------------------------------------------------------------------

class _PageWrapper extends StatelessWidget {
  final Widget child;
  const _PageWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HadesTopBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
