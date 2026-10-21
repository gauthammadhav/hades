import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/runtime.dart';
import '../models/scenario.dart';

class PolicyMatrixCard extends StatelessWidget {
  final Scenario scenario;

  const PolicyMatrixCard({super.key, required this.scenario});

  @override
  Widget build(BuildContext context) {
    Color chipBg;
    Color chipTextColor;
    Color chipDotColor;
    String chipLabel;

    switch (scenario.runtime) {
      case Runtime.docker:
        chipBg = AppColors.chipBlueBg;
        chipTextColor = AppColors.info;
        chipDotColor = AppColors.info;
        chipLabel = 'DOCKER_CONTAINER';
        break;
      case Runtime.qemu:
        chipBg = AppColors.chipPurpleBg;
        chipTextColor = AppColors.vmPurple;
        chipDotColor = AppColors.vmPurple;
        chipLabel = 'QEMU_KVM_VM';
        break;
      case Runtime.blocked:
        chipBg = AppColors.chipRedBg;
        chipTextColor = AppColors.danger;
        chipDotColor = AppColors.danger;
        chipLabel = 'BLOCKED';
        break;
    }

    final ruleLabels = [
      'Allow-listed class',
      'Kernel module required',
      'Serial / JTAG only',
      'HID / mass-storage class',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppColors.border,
          width: AppTheme.borderWidth,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header with runtime pill
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Policy matrix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: chipDotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      chipLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: chipTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 4 Toggle switch rows
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) {
              final isEnabled = scenario.rules[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    _ReadOnlySwitch(value: isEnabled),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ruleLabels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlySwitch extends StatelessWidget {
  final bool value;

  const _ReadOnlySwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 16,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value
            ? AppColors.switchTrackActive
            : AppColors.switchTrackInactive,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
