import 'package:flutter/material.dart';
import 'features/auth/presentation/auth_gate.dart';

class BloodSenzApp extends StatelessWidget {
  const BloodSenzApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BloodSenz',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
      scaffoldBackgroundColor: const Color(0xFFF7FAFA),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    home: const AuthGate(),
  );
}
