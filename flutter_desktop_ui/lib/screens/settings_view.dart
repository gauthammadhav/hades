import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../state/control_plane_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _urlController = TextEditingController(text: 'ws://127.0.0.1:8000/ws/events');
  bool _isConnected = false;

  Future<void> _toggleConnection() async {
    final controller = context.read<ControlPlaneController>();
    if (!_isConnected) {
      setState(() => _isConnected = true);
      await controller.connectToBackend(url: _urlController.text.trim());
    } else {
      setState(() => _isConnected = false);
      await controller.disconnectFromBackend();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Daemon Telemetry & Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Backend daemon health, WebSocket event streaming, and Python detection integration',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isConnected ? AppColors.chipMintBg : AppColors.chipBlueBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: AppTheme.borderWidth),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isConnected ? AppColors.ok : AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isConnected ? 'Connected to Backend' : 'Mock Mode Active',
                    style: const TextStyle(
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

        // Bento Rows
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Daemon Status Cards
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _DaemonStatusCard(
                    title: 'pyudev Hardware Monitor',
                    subtitle: 'Kernel netlink kobject listener',
                    status: 'ONLINE',
                    statusColor: AppColors.ok,
                    icon: Icons.monitor_heart_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DaemonStatusCard(
                    title: 'Docker Container Engine',
                    subtitle: 'unix:///var/run/docker.sock',
                    status: 'ACTIVE',
                    statusColor: AppColors.ok,
                    icon: Icons.layers_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DaemonStatusCard(
                    title: 'QEMU/KVM Hypervisor',
                    subtitle: 'libvirtd hostdev IOMMU isolation',
                    status: 'ACTIVE',
                    statusColor: AppColors.vmPurple,
                    icon: Icons.memory_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Right Column: Python Backend Integration Card
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppColors.border, width: AppTheme.borderWidth),
                  boxShadow: AppTheme.softShadow,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Python Backend Connection',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Connect your Python detection script to this endpoint to push live USB plug-in events directly into this UI.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // WebSocket URL Input
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'ws://127.0.0.1:8000/ws/events',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: _toggleConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected ? AppColors.danger : AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Text(_isConnected ? 'Disconnect WebSocket' : 'Connect WebSocket'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Python Command Snippet
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '# Python Test Integration Script:',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: AppColors.logNormal,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'python scripts/device_detector.py',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.logAudit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DaemonStatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData icon;

  const _DaemonStatusCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.innerTileRadius),
        border: Border.all(color: AppColors.border, width: AppTheme.borderWidth),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
