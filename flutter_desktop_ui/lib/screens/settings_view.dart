import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../state/dashboard_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _urlCtrl;
  late TextEditingController _tokenCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<DashboardController>();
    _urlCtrl = TextEditingController(text: ctrl.config.baseUrl);
    _tokenCtrl = TextEditingController(text: ctrl.config.apiToken ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final ctrl = context.read<DashboardController>();
    ctrl.updateConfig(
      ApiConfig(
        baseUrl: _urlCtrl.text.trim().isEmpty
            ? 'http://127.0.0.1:8080'
            : _urlCtrl.text.trim(),
        apiToken: _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
      ),
    );
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daemon & Connection Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure the HADES Core host daemon. Supports local Windows PnP or remote Linux udev backends.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Main form card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Backend URL
                _Section(
                  title: 'Backend Daemon URL',
                  subtitle:
                      'HTTP base URL of the running HADES service (default: http://127.0.0.1:8080).\n'
                      'Use a remote IP address (e.g., http://192.168.1.100:8080) if running the daemon on Linux or inside WSL.',
                  child: TextField(
                    controller: _urlCtrl,
                    style: const TextStyle(
                      color: AppColors.mono,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.monoFont,
                      fontFamilyFallback: AppTheme.monoFallbacks,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'http://127.0.0.1:8080',
                      prefixIcon: Icon(Icons.dns_rounded, size: 16, color: AppColors.primary),
                      prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // API token
                _Section(
                  title: 'Bearer Authorization Token (Optional)',
                  subtitle:
                      'Required only if API token authentication is enforced on the daemon.',
                  child: TextField(
                    controller: _tokenCtrl,
                    obscureText: true,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Leave empty for local unauthenticated access',
                      prefixIcon: Icon(Icons.key_rounded, size: 16, color: AppColors.primary),
                      prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(_saved ? '✓ Config Saved' : 'Apply & Reconnect'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        _urlCtrl.text = 'http://127.0.0.1:8080';
                        _tokenCtrl.text = '';
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Reset to Defaults'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Host Architecture notes
          _InfoCard(
            title: 'Host Daemon Command Reference',
            body: '''• Start daemon on local Windows host:
  cd backend/
  py -3.9 -m uvicorn hades.api.app:app --host 0.0.0.0 --port 8080 --reload

• Start daemon on remote Linux / WSL2 host:
  cd backend/
  uvicorn hades.api.app:app --host 0.0.0.0 --port 8080 --reload''',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontFamily: AppTheme.monoFont,
              fontFamilyFallback: AppTheme.monoFallbacks,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
