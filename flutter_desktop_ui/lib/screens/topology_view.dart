import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../state/control_plane_controller.dart';

class TopologyView extends StatefulWidget {
  const TopologyView({super.key});

  @override
  State<TopologyView> createState() => _TopologyViewState();
}

class _TopologyViewState extends State<TopologyView> {
  final Map<String, bool> _portPower = {
    'Port 1-2.1': true,
    'Port 1-2.2': true,
    'Port 1-3': false,
    'Port 1-4': true,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlPlaneController>(
      builder: (context, controller, child) {
        final devices = controller.repository?.devices ?? [];
        final totalCount = devices.isNotEmpty ? devices.length : 3;
        final blockedCount = devices.isNotEmpty
            ? devices.where((d) => d.isUnauthorized).length
            : 1;
        final sandboxedCount = totalCount - blockedCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Hardware Topology',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Physical USB bus hierarchy, port mapping and VBUS power switching',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.chipMintBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                      width: AppTheme.borderWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.hub_rounded, size: 14, color: AppColors.ok),
                      SizedBox(width: 6),
                      Text(
                        'uhubctl active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Stat metric row
            Row(
              children: [
                const Expanded(
                  child: _MetricCard(
                    title: 'Root Controllers',
                    value: '2 xHCI Hubs',
                    subtext: 'Bus 001 (USB 2.0) · Bus 002 (USB 3.2)',
                    icon: Icons.alt_route_rounded,
                    accentColor: AppColors.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Active Endpoints',
                    value: '$totalCount Devices',
                    subtext:
                        '$sandboxedCount Sandboxed · $blockedCount Blocked by policy',
                    icon: Icons.usb_rounded,
                    accentColor: AppColors.ok,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: _MetricCard(
                    title: 'Port Power State',
                    value: '5.0V Nominal',
                    subtext: 'Total draw: 850mA / 3000mA max',
                    icon: Icons.bolt_rounded,
                    accentColor: AppColors.vmPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bus Tree Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(
                  color: AppColors.border,
                  width: AppTheme.borderWidth,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Physical Port Tree (Bus 001 - Host Hub)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (controller.isBackendConnected)
                        const Text(
                          'Live pyudev tracking',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.ok,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (devices.isNotEmpty)
                    ...List.generate(devices.length, (index) {
                      final dev = devices[index];
                      final port =
                          dev.portTopology != null &&
                              dev.portTopology!.isNotEmpty
                          ? 'Port ${dev.portTopology}'
                          : 'Port ${dev.busPath}';
                      final isBlocked = dev.isUnauthorized;
                      final isVm = dev.isolationRecommendation == 'vm';
                      final statusBadge = isBlocked
                          ? 'BLOCKED / POWER CUT'
                          : (isVm ? 'QEMU/KVM VM' : 'DOCKER ISOLATED');
                      final badgeColor = isBlocked
                          ? AppColors.danger
                          : (isVm ? AppColors.vmPurple : AppColors.info);
                      final badgeBg = isBlocked
                          ? AppColors.chipRedBg
                          : (isVm
                                ? AppColors.chipPurpleBg
                                : AppColors.chipBlueBg);
                      final isPowerOn = _portPower[port] ?? !isBlocked;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index > 0)
                            const Divider(
                              color: AppColors.border,
                              height: 16,
                              thickness: 1,
                            ),
                          _PortTreeTile(
                            portLabel: port,
                            deviceTitle: dev.displayName,
                            details:
                                'VID:PID ${dev.usbId} · Node: ${dev.deviceNode ?? 'N/A'} · ${dev.speed != null ? 'Speed: ${dev.speed}' : 'Topology: ${dev.portTopology ?? 'root'}'}',
                            node: dev.deviceNode ?? dev.busPath,
                            statusBadge: statusBadge,
                            badgeColor: badgeColor,
                            badgeBg: badgeBg,
                            isPowerOn: isPowerOn,
                            onPowerToggle: (val) =>
                                setState(() => _portPower[port] = val),
                          ),
                        ],
                      );
                    })
                  else ...[
                    _PortTreeTile(
                      portLabel: 'Port 1-2.1',
                      deviceTitle: 'ESP32-S3 Serial Flash',
                      details:
                          'VID:PID 303A:1001 · Speed: High-Speed 480Mbps · Power: 500mA',
                      node: '/dev/ttyACM0',
                      statusBadge: 'DOCKER ISOLATED',
                      badgeColor: AppColors.info,
                      badgeBg: AppColors.chipBlueBg,
                      isPowerOn: _portPower['Port 1-2.1'] ?? true,
                      onPowerToggle: (val) =>
                          setState(() => _portPower['Port 1-2.1'] = val),
                    ),
                    const Divider(
                      color: AppColors.border,
                      height: 16,
                      thickness: 1,
                    ),
                    _PortTreeTile(
                      portLabel: 'Port 1-4',
                      deviceTitle: 'Custom CAN Kernel Module',
                      details:
                          'VID:PID 1D50:606F · Speed: Full-Speed 12Mbps · Power: 250mA',
                      node: '/dev/bus/usb/001/007',
                      statusBadge: 'QEMU/KVM VM',
                      badgeColor: AppColors.vmPurple,
                      badgeBg: AppColors.chipPurpleBg,
                      isPowerOn: _portPower['Port 1-4'] ?? true,
                      onPowerToggle: (val) =>
                          setState(() => _portPower['Port 1-4'] = val),
                    ),
                    const Divider(
                      color: AppColors.border,
                      height: 16,
                      thickness: 1,
                    ),
                    _PortTreeTile(
                      portLabel: 'Port 1-3',
                      deviceTitle: 'Unauthorized USB Attack',
                      details:
                          'VID:PID 0951:1666 · HID Class (0x03) · Power: 100mA',
                      node: '/dev/input/event7',
                      statusBadge: 'BLOCKED / POWER CUT',
                      badgeColor: AppColors.danger,
                      badgeBg: AppColors.chipRedBg,
                      isPowerOn: _portPower['Port 1-3'] ?? false,
                      onPowerToggle: (val) =>
                          setState(() => _portPower['Port 1-3'] = val),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color accentColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppColors.border,
          width: AppTheme.borderWidth,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortTreeTile extends StatelessWidget {
  final String portLabel;
  final String deviceTitle;
  final String details;
  final String node;
  final String statusBadge;
  final Color badgeColor;
  final Color badgeBg;
  final bool isPowerOn;
  final ValueChanged<bool> onPowerToggle;

  const _PortTreeTile({
    required this.portLabel,
    required this.deviceTitle,
    required this.details,
    required this.node,
    required this.statusBadge,
    required this.badgeColor,
    required this.badgeBg,
    required this.isPowerOn,
    required this.onPowerToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Text(
            portLabel,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    deviceTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusBadge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                details,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isPowerOn ? 'VBUS ON' : 'VBUS OFF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isPowerOn ? AppColors.ok : AppColors.danger,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 26,
              child: Switch(
                value: isPowerOn,
                onChanged: onPowerToggle,
                activeThumbColor: AppColors.ok,
                activeTrackColor: AppColors.chipMintBg,
                inactiveThumbColor: AppColors.danger,
                inactiveTrackColor: AppColors.chipRedBg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
