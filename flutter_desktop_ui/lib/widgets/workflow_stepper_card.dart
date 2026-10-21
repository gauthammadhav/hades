import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/scenario.dart';
import '../models/stage.dart';

class WorkflowStepperCard extends StatelessWidget {
  final Scenario scenario;
  final Stage currentStage;

  const WorkflowStepperCard({
    super.key,
    required this.scenario,
    required this.currentStage,
  });

  @override
  Widget build(BuildContext context) {
    const totalSteps = 5;
    final isBlocked = scenario.isBlocked;
    final currentStageNum = currentStage.number;

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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Workflow pipeline',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Stepper layout
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: List.generate(totalSteps * 2 - 1, (index) {
                  if (index.isEven) {
                    // Node
                    final stepIndex = index ~/ 2;
                    final stepNumber = stepIndex + 1;
                    final stageItem = Stage.values[stepIndex];

                    return Expanded(
                      flex: 4,
                      child: _StepNode(
                        stepNumber: stepNumber,
                        stage: stageItem,
                        currentStageNumber: currentStageNum,
                        isBlocked: isBlocked,
                      ),
                    );
                  } else {
                    // Line connector between step i and step i+1
                    final stepBefore = index ~/ 2 + 1;
                    final isLineCompleted = _isLineGreen(
                      stepBefore,
                      currentStageNum,
                      isBlocked,
                    );

                    return Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 34),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          height: 2,
                          color: isLineCompleted
                              ? AppColors.ok
                              : AppColors.border,
                        ),
                      ),
                    );
                  }
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isLineGreen(int stepBefore, int currentStageNum, bool isBlocked) {
    if (isBlocked) {
      // For blocked device, lines leading up to stage 3 are green
      if (stepBefore < 3 && currentStageNum >= stepBefore + 1) {
        return true;
      }
      return false;
    }
    return currentStageNum >= stepBefore + 1;
  }
}

class _StepNode extends StatelessWidget {
  final int stepNumber;
  final Stage stage;
  final int currentStageNumber;
  final bool isBlocked;

  const _StepNode({
    required this.stepNumber,
    required this.stage,
    required this.currentStageNumber,
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = stepNumber == currentStageNumber;
    final isPast = stepNumber < currentStageNumber;
    final isBlockedAtThisStep =
        isBlocked && stepNumber == 3 && currentStageNumber >= 3;
    final isSkipped = isBlocked && stepNumber > 3;

    Widget circleContent;
    Color circleBgColor;
    Border? circleBorder;

    if (isBlockedAtThisStep) {
      // Blocked state: Red circle with X
      circleBgColor = AppColors.danger;
      circleBorder = null;
      circleContent = const Icon(
        Icons.close_rounded,
        size: 18,
        color: AppColors.white,
      );
    } else if (isPast) {
      // Done state: Green circle with check
      circleBgColor = AppColors.ok;
      circleBorder = null;
      circleContent = const Icon(
        Icons.check_rounded,
        size: 18,
        color: AppColors.white,
      );
    } else if (isCurrent) {
      // Active state: Primary dark circle with number
      circleBgColor = AppColors.primary;
      circleBorder = null;
      circleContent = Text(
        '$stepNumber',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      // Pending / Skipped state: Outlined circle
      circleBgColor = AppColors.background;
      circleBorder = Border.all(color: AppColors.border, width: 1.5);
      circleContent = Text(
        '$stepNumber',
        style: TextStyle(
          color: isSkipped
              ? AppColors.textSecondary.withValues(alpha: 0.5)
              : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // Node labels
    final shortLabel = stage.getDisplayLabel(
      isBlocked: isBlocked && stepNumber == 3,
    );
    final rawName = stage.rawName;
    final isMuted = !isPast && !isCurrent && !isBlockedAtThisStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular Indicator with animated fill
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleBgColor,
            shape: BoxShape.circle,
            border: circleBorder,
          ),
          alignment: Alignment.center,
          child: circleContent,
        ),
        const SizedBox(height: 6),

        // Short Label
        Text(
          shortLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isMuted
                ? AppColors.textSecondary.withValues(alpha: 0.6)
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),

        // Raw State Name in monospace
        Text(
          rawName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier New', 'Courier', 'monospace'],
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: isMuted
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
