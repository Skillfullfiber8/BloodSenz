import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../scanning/presentation/report_home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snapshot.hasData ? const ReportHomeScreen() : const LoginScreen();
    },
  );
}
