import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../state/dashboard_controller.dart';

/// Top header bar: HADES branding + live daemon connection status.
class HadesTopBar extends StatelessWidget {
  const HadesTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: const _TopBarContent(),
    );
  }
}

class _TopBarContent extends StatelessWidget {
  const _TopBarContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Brand emblem in dark spruce
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F103031),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'H',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'HADES',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.accentBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CORE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            const Text(
              'Hardware Topology & Live Device Broker',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const Spacer(),
        const _BackendStatusChip(),
      ],
    );
  }
}

class _BackendStatusChip extends StatelessWidget {
  const _BackendStatusChip();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final (dotColor, bgColor, textColor, label) = switch (ctrl.status) {
      BackendStatus.online => (
        AppColors.statusOnline,
        AppColors.chipMintBg,
        AppColors.ok,
        'Daemon Online',
      ),
      BackendStatus.offline => (
        AppColors.statusOffline,
        AppColors.alertRedBg,
        AppColors.danger,
        'Daemon Offline',
      ),
      BackendStatus.connecting => (
        AppColors.statusConnecting,
        AppColors.chipBlueBg,
        AppColors.info,
        'Connecting…',
      ),
      BackendStatus.authRequired => (
        AppColors.statusWarning,
        AppColors.chipAmberBg,
        AppColors.warning,
        'Auth Required',
      ),
      BackendStatus.discoveryUnavailable => (
        AppColors.statusWarning,
        AppColors.chipAmberBg,
        AppColors.warning,
        'Discovery Idle',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
