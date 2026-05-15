// App entrypoint.
//
// Wires AppTheme into MaterialApp, applies the system-chrome recipe so
// the status bar matches the aurora gradient on first paint, and boots
// straight into the splash screen which then routes to home.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiLight);
  runApp(const GrowUpMoreApp());
}

class GrowUpMoreApp extends StatelessWidget {
  const GrowUpMoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grow Up More',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
