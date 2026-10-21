import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class EventConsoleCard extends StatefulWidget {
  final List<String> eventLogs;

  const EventConsoleCard({
    super.key,
    required this.eventLogs,
  });

  @override
  State<EventConsoleCard> createState() => _EventConsoleCardState();
}

class _EventConsoleCardState extends State<EventConsoleCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant EventConsoleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventLogs.length != oldWidget.eventLogs.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getLogColor(String line) {
    if (line.contains('DENY')) {
      return AppColors.logDeny;
    }
    if (line.contains('[audit]')) {
      return AppColors.logAudit;
    }
    return AppColors.logNormal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with live dot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Event stream',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.logLiveDot,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Monospace logs with auto-scroll
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final line in widget.eventLogs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: const ['Courier New', 'Courier', 'Consolas', 'monospace'],
                          fontSize: 10.5,
                          height: 1.35,
                          color: _getLogColor(line),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
