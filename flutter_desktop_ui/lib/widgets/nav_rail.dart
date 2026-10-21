import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class HadesNavRail extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int>? onIndexChanged;

  const HadesNavRail({
    super.key,
    this.activeIndex = 0,
    this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Logo circle
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.logoRing,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Nav Icon Buttons
          _NavIconButton(
            icon: Icons.grid_view_rounded,
            isActive: activeIndex == 0,
            onTap: () => onIndexChanged?.call(0),
          ),
          const SizedBox(height: 20),
          _NavIconButton(
            icon: Icons.usb_rounded,
            isActive: activeIndex == 1,
            onTap: () => onIndexChanged?.call(1),
          ),
          const SizedBox(height: 20),
          _NavIconButton(
            icon: Icons.hexagon_outlined,
            isActive: activeIndex == 2,
            onTap: () => onIndexChanged?.call(2),
          ),
          const SizedBox(height: 20),
          _NavIconButton(
            icon: Icons.terminal_rounded,
            isActive: activeIndex == 3,
            onTap: () => onIndexChanged?.call(3),
          ),
          const SizedBox(height: 20),
          _NavIconButton(
            icon: Icons.adjust_rounded,
            isActive: activeIndex == 4,
            onTap: () => onIndexChanged?.call(4),
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.navActiveTile : AppColors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: isActive ? AppColors.white : AppColors.navMuted,
        ),
      ),
    );
  }
}
