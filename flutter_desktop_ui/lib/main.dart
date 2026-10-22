import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/startup_screen.dart';
import 'state/dashboard_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HadesApp());
}

class HadesApp extends StatelessWidget {
  final DashboardController? controller;
  final Widget? home;

  const HadesApp({super.key, this.controller, this.home});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'HADES Hardware Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: home ?? const StartupScreen(),
    );

    if (controller != null) {
      return ChangeNotifierProvider<DashboardController>.value(
        value: controller!,
        child: app,
      );
    }

    return ChangeNotifierProvider<DashboardController>(
      create: (_) => DashboardController(),
      child: app,
    );
  }
}
