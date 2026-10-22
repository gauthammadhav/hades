import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/scenario.dart';
import '../models/stage.dart';

class HeroCard extends StatelessWidget {
  final Scenario scenario;
  final Stage currentStage;

  const HeroCard({
    super.key,
    required this.scenario,
    required this.currentStage,
  });

  @override
  Widget build(BuildContext context) {
    final isStandby = scenario.isStandby;
    final isBlocked =
        scenario.isBlocked && currentStage == Stage.policyEvaluated;
    final displayStageNumber = isStandby
        ? 0
        : (currentStage.number > 5 ? 5 : currentStage.number);
    final progressFraction = isStandby ? 0.0 : (displayStageNumber / 5.0).clamp(0.0, 1.0);

    final statusText = isStandby
        ? 'Awaiting USB connection...'
        : (scenario.isBlocked && currentStage.number >= 3
            ? 'Blocked by policy'
            : currentStage.getHeroStatusText(isBlocked: false));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Stack(
          children: [
            // Decorative background shapes
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(85),
                  color: AppColors.heroDecorativeShape,
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -50,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(70),
                  color: AppColors.heroDecorativeShape,
                ),
              ),
            ),

            // Main card content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Runtime pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.heroPillBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isStandby ? 'STANDBY' : scenario.runtime.label,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Device Name
                      Text(
                        scenario.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Bus · VID:PID · Node
                      Text(
                        isStandby
                            ? 'Netlink listener online · Ready for physical or simulated plug-in'
                            : '${scenario.busPath} · ${scenario.vidPid} · ${scenario.node}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.heroSubtext,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  // Bottom stage status & progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isBlocked
                                        ? AppColors.heroProgressRed
                                        : AppColors.heroProgressGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    statusText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isStandby
                                ? 'Stage 0/5'
                                : 'Stage $displayStageNumber/5',
                            style: const TextStyle(
                              color: AppColors.heroSubtext,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Progress bar with smooth easeInOut animation
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          color: AppColors.heroProgressTrack,
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(
                              begin: 0.0,
                              end: progressFraction,
                            ),
                            builder: (context, value, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isBlocked
                                        ? AppColors.heroProgressRed
                                        : AppColors.heroProgressGreen,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
