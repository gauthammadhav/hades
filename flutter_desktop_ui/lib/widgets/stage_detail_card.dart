import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/runtime.dart';
import '../models/scenario.dart';
import '../models/stage.dart';

class StageDetailCard extends StatelessWidget {
  final Scenario scenario;
  final Stage currentStage;
  final VoidCallback onAttachIde;
  final VoidCallback onTriggerTeardown;

  const StageDetailCard({
    super.key,
    required this.scenario,
    required this.currentStage,
    required this.onAttachIde,
    required this.onTriggerTeardown,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = scenario.isBlocked && currentStage.number >= 3;
    final isStage5Active = currentStage == Stage.sessionActive && !scenario.isBlocked;

    final displayStageNumber = currentStage.number > 5 ? 5 : currentStage.number;
    final stageTitle = isBlocked
        ? 'Blocked'
        : currentStage.getDetailTitle(isBlocked: false);

    final titleColor = isBlocked ? AppColors.danger : AppColors.textPrimary;

    final rows = _buildStageRows();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border, width: AppTheme.borderWidth),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Stage n + Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stage $displayStageNumber',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                stageTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ),

          // Divider-separated Key-Value Rows
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppColors.border,
                  height: 14,
                  thickness: 1,
                ),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            row.key,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.value,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Action: Red Alert Box if Blocked, else Action Buttons
          if (isBlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.alertRedBg,
                borderRadius: BorderRadius.circular(AppTheme.innerTileRadius),
                border: Border.all(color: AppColors.alertRedBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Access denied',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Least-privilege policy blocked this device class.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                // Attach IDE pill button
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: isStage5Active ? onAttachIde : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isStage5Active
                            ? AppColors.primary
                            : AppColors.disabledButtonBg,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.disabledButtonBg,
                        disabledForegroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Attach IDE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Trigger teardown outlined pill button
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: isStage5Active ? onTriggerTeardown : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.border,
                          width: AppTheme.borderWidth,
                        ),
                        foregroundColor: isStage5Active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        disabledForegroundColor: AppColors.textSecondary,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Trigger teardown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _buildStageRows() {
    if (scenario.isBlocked && currentStage.number >= 3) {
      return [
        const MapEntry('Decision', 'BLOCKED'),
        MapEntry('Reason', scenario.reason),
      ];
    }

    switch (currentStage) {
      case Stage.deviceDetected:
        return [
          MapEntry('Device', scenario.name),
          MapEntry('Bus Path', scenario.busPath),
          MapEntry('VID:PID', scenario.vidPid),
          MapEntry('Node', scenario.node),
        ];
      case Stage.requirementsResolved:
        return [
          MapEntry('Class', scenario.usbClass),
          MapEntry('Arch', scenario.arch),
          MapEntry('Toolchain', scenario.toolchains.join(', ')),
        ];
      case Stage.policyEvaluated:
        return [
          MapEntry('Decision', scenario.runtime == Runtime.docker ? 'DOCKER_CONTAINER' : 'QEMU_KVM_VM'),
          MapEntry('Reason', scenario.reason),
        ];
      case Stage.sandboxProvisioned:
        return [
          MapEntry('Container', scenario.runtime.label),
          MapEntry('Broker', scenario.broker),
          const MapEntry('Mount', '/workspace overlay'),
        ];
      case Stage.sessionActive:
      case Stage.teardownVerified:
        return [
          const MapEntry('Session', 'Terminal / IDE attached via hades attach'),
          const MapEntry('Teardown', 'Overlay discarded, device released'),
          const MapEntry('Audit', '0% host pollution verified'),
        ];
    }
  }
}
