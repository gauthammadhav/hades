import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'dashboard_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _launchDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _launchDashboard();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            // Decorative background glowing geometry
            Positioned(
              left: -80,
              top: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.heroDecorativeShape,
                ),
              ),
            ),
            Positioned(
              right: -60,
              bottom: -60,
              child: Container(
                width: 360,
                height: 360,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.heroDecorativeShape,
                ),
              ),
            ),

            // Main center content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Concentric Logo Core
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.logoRing,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.heroProgressGreen.withValues(
                                  alpha: 0.3,
                                ),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Version pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.heroPillBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'HADES v1.0.4 · HARDWARE SANDBOX',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.heroProgressGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Big Title
                          const Text(
                            'Control Plane',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: AppColors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle description
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 540),
                            child: const Text(
                              'Hardware-aware sandbox orchestration for microcontrollers and embedded devices with zero host pollution.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: AppColors.heroSubtext,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Pre-Flight Diagnostic Status Card
                          Container(
                            width: 680,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardRadius,
                              ),
                              border: Border.all(
                                color: AppColors.border,
                                width: AppTheme.borderWidth,
                              ),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Expanded(
                                      child: Text(
                                        'Pre-Flight System Status',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'ALL SUBSYSTEMS NOMINAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AppColors.ok,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  color: AppColors.border,
                                  height: 20,
                                ),
                                Row(
                                  children: const [
                                    Expanded(
                                      child: _PreflightItem(
                                        label: 'pyudev Monitor',
                                        status: 'ONLINE',
                                        color: AppColors.ok,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: _PreflightItem(
                                        label: 'Container Broker',
                                        status: 'CGROUPS V2',
                                        color: AppColors.info,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: _PreflightItem(
                                        label: 'VM Hypervisor',
                                        status: 'KVM/QEMU',
                                        color: AppColors.vmPurple,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: _PreflightItem(
                                        label: 'Security Policy',
                                        status: 'STRICT GUARD',
                                        color: AppColors.ok,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Primary Action Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _launchDashboard,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Launch Control Plane',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ok,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Keyboard tip
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.keyboard_outlined,
                                size: 14,
                                color: AppColors.heroSubtext,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Press Enter or Space to launch',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.heroSubtext,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreflightItem extends StatelessWidget {
  final String label;
  final String status;
  final Color color;

  const _PreflightItem({
    required this.label,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
