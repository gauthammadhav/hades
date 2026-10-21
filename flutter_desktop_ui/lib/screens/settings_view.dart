import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../state/control_plane_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _restUrlController = TextEditingController(
    text: 'http://127.0.0.1:8080',
  );
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _urlController = TextEditingController(
    text: 'ws://127.0.0.1:8080/v1/ws/*',
  );
  bool _isConnected = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ControlPlaneController>();
      if (controller.repository != null) {
        _restUrlController.text =
            controller.repository!.apiClient.config.baseUrl;
        _tokenController.text =
            controller.repository!.apiClient.config.apiToken ?? '';
        _urlController.text = controller.repository!.apiClient.config.wsUrl;
      }
      setState(() {
        _isConnected = controller.isBackendConnected;
      });
    });
  }

  Future<void> _toggleConnection() async {
    final controller = context.read<ControlPlaneController>();
    if (!_isConnected) {
      final newConfig = ApiConfig(
        baseUrl: _restUrlController.text.trim(),
        apiToken: _tokenController.text.trim().isEmpty
            ? null
            : _tokenController.text.trim(),
      );
      controller.repository?.updateConfig(newConfig);

      setState(() {
        _statusMessage = 'Connecting...';
      });

      await controller.connectToBackend(url: _urlController.text.trim());
      final isOnline = await controller.repository?.checkHealth() ?? false;
      setState(() {
        _isConnected = controller.isBackendConnected;
        _statusMessage = isOnline
            ? 'Connected (Daemon Online)'
            : 'Connected to WS (Health check pending)';
      });
    } else {
      await controller.disconnectFromBackend();
      setState(() {
        _isConnected = false;
        _statusMessage = 'Disconnected';
      });
    }
  }

  @override
  void dispose() {
    _restUrlController.dispose();
    _tokenController.dispose();
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
                color: _isConnected
                    ? AppColors.chipMintBg
                    : AppColors.chipBlueBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  width: AppTheme.borderWidth,
                ),
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
                    const SizedBox(height: 12),

                    // REST URL Label & Input
                    const Text(
                      'HADES Daemon Base URL (REST)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _restUrlController,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'http://127.0.0.1:8080',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Bearer Token Label & Input
                    const Text(
                      'API Bearer Token (optional)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _tokenController,
                        obscureText: true,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'HADES_API_TOKEN',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // WebSocket URL Label & Input
                    const Text(
                      'Event Stream Endpoint (WebSocket)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
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
                          hintText: 'ws://127.0.0.1:8080/v1/ws/*',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_statusMessage != null) ...[
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? AppColors.ok : AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: _toggleConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected
                              ? AppColors.danger
                              : AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Text(
                          _isConnected
                              ? 'Disconnect from Backend'
                              : 'Connect to Backend Daemon',
                        ),
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
                            '# Launch HADES Core Daemon on Linux Host:',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: AppColors.logNormal,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'hadesd --host 0.0.0.0 --port 8080',
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
        border: Border.all(
          color: AppColors.border,
          width: AppTheme.borderWidth,
        ),
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
