import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/startup_screen.dart';
import 'state/control_plane_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HadesApp());
}

class HadesApp extends StatelessWidget {
  final ControlPlaneController? controller;
  final Widget? home;

  const HadesApp({
    super.key,
    this.controller,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'HADES Control Plane',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home ?? const StartupScreen(),
    );

    if (controller != null) {
      return ChangeNotifierProvider<ControlPlaneController>.value(
        value: controller!,
        child: app,
      );
    }

    return ChangeNotifierProvider<ControlPlaneController>(
      create: (_) => ControlPlaneController(),
      child: app,
    );
  }
}
