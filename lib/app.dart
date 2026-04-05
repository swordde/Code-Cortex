import 'package:flutter/material.dart';

import 'screens/startup_name_gate_screen.dart';

class CortexApp extends StatelessWidget {
  const CortexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cortex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4D52)),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4D52),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111315),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const StartupNameGateScreen(),
    );
  }
}
