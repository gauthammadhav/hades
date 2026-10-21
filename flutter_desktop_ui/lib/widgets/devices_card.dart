import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/runtime.dart';
import '../models/scenario.dart';

class DevicesCard extends StatelessWidget {
  final List<Scenario> scenarios;
  final Scenario selectedScenario;
  final ValueChanged<Scenario> onSelectScenario;
  final VoidCallback onSimulatePlugin;

  const DevicesCard({
    super.key,
    required this.scenarios,
    required this.selectedScenario,
    required this.onSelectScenario,
    required this.onSimulatePlugin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border, width: AppTheme.borderWidth),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Devices',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Device list
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: scenarios.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                final isSelected = scenario.id == selectedScenario.id;

                Color avatarBg;
                Color avatarIconColor;
                Color statusDotColor;

                switch (scenario.runtime) {
                  case Runtime.docker:
                    avatarBg = AppColors.chipMintBg;
                    avatarIconColor = AppColors.textPrimary;
                    statusDotColor = AppColors.info;
                    break;
                  case Runtime.qemu:
                    avatarBg = AppColors.chipPurpleBg;
                    avatarIconColor = AppColors.vmPurple;
                    statusDotColor = AppColors.vmPurple;
                    break;
                  case Runtime.blocked:
                    avatarBg = AppColors.chipMintBg;
                    avatarIconColor = AppColors.textPrimary;
                    statusDotColor = AppColors.danger;
                    break;
                }

                return InkWell(
                  onTap: () => onSelectScenario(scenario),
                  borderRadius: BorderRadius.circular(AppTheme.innerTileRadius),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surface : AppColors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.innerTileRadius),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.transparent,
                        width: AppTheme.borderWidth,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar icon tile
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: avatarBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.usb_rounded,
                            size: 18,
                            color: avatarIconColor,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                scenario.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${scenario.busPath} · ${scenario.vidPid}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status color dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // + Simulate plug-in button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: onSimulatePlugin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                '+ Simulate plug-in',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
