import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/runtime.dart';
import '../models/scenario.dart';
import '../models/stage.dart';

class IsolationBoundaryCard extends StatelessWidget {
  final Scenario scenario;
  final Stage currentStage;

  const IsolationBoundaryCard({
    super.key,
    required this.scenario,
    required this.currentStage,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = scenario.isBlocked && currentStage.number >= 3;

    // Node 2 (Broker) styling
    Color brokerBorderColor;
    Color brokerDotColor;
    String brokerLabel;
    switch (scenario.runtime) {
      case Runtime.docker:
        brokerBorderColor = AppColors.info;
        brokerDotColor = AppColors.info;
        brokerLabel = 'DOCKER_CONTAINER';
        break;
      case Runtime.qemu:
        brokerBorderColor = AppColors.vmPurple;
        brokerDotColor = AppColors.vmPurple;
        brokerLabel = 'QEMU_KVM_VM';
        break;
      case Runtime.blocked:
        brokerBorderColor = AppColors.danger;
        brokerDotColor = AppColors.danger;
        brokerLabel = 'BLOCKED';
        break;
    }

    // Connector 2 styling
    Color connector2Color;
    if (isBlocked) {
      connector2Color = AppColors.danger;
    } else if (scenario.runtime == Runtime.docker && currentStage.number >= 4) {
      connector2Color = AppColors.info;
    } else if (scenario.runtime == Runtime.qemu) {
      connector2Color = currentStage.number >= 4
          ? AppColors.vmPurple
          : AppColors.vmPurple.withValues(alpha: 0.5);
    } else {
      connector2Color = AppColors.border;
    }

    // Node 3 (Sandbox / Access Denied) styling
    Color sandboxBorderColor;
    Color sandboxDotColor;
    String sandboxTitle;
    String sandboxSubtext;

    if (isBlocked) {
      sandboxBorderColor = AppColors.danger;
      sandboxDotColor = AppColors.danger;
      sandboxTitle = 'Access denied';
      sandboxSubtext = 'no session';
    } else if (currentStage.number >= 5) {
      sandboxBorderColor = AppColors.ok;
      sandboxDotColor = AppColors.ok;
      sandboxTitle = 'Isolated sandbox';
      sandboxSubtext = '/workspace overlay';
    } else {
      sandboxBorderColor = AppColors.border;
      sandboxDotColor = AppColors.textSecondary;
      sandboxTitle = 'Isolated sandbox';
      sandboxSubtext = 'pending';
    }

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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Isolation boundary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Host → Broker → Sandbox',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),

          // 3 Connected Nodes
          Row(
            children: [
              // Node 1: Host USB Port
              Expanded(
                child: _BoundaryNode(
                  borderColor: AppColors.primary,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.usb_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Host USB port',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        scenario.busPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dashed Connector 1
              _DashedLineConnector(color: AppColors.primary),

              // Node 2: HADES Broker
              Expanded(
                child: _BoundaryNode(
                  borderColor: brokerBorderColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: brokerDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'HADES broker',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        brokerLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dashed Connector 2
              _DashedLineConnector(color: connector2Color),

              // Node 3: Isolated Sandbox / Access Denied
              Expanded(
                child: _BoundaryNode(
                  borderColor: sandboxBorderColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sandboxDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sandboxTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        sandboxSubtext,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Broker Description Line
          Text(
            'Broker: ${scenario.broker}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoundaryNode extends StatelessWidget {
  final Color borderColor;
  final Widget child;

  const _BoundaryNode({required this.borderColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.innerTileRadius),
        border: Border.all(color: borderColor, width: AppTheme.borderWidth),
      ),
      child: child,
    );
  }
}

class _DashedLineConnector extends StatelessWidget {
  final Color color;

  const _DashedLineConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 2,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(
          startX + dashWidth > size.width ? size.width : startX + dashWidth,
          size.height / 2,
        ),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
