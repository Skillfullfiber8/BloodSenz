import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  final _auth = AuthService();
  bool _busy = false, _obscure = true;
  String? _error;
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_key.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _auth.signIn(email: _email.text, password: _password.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Email or password is incorrect.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        _ => e.message ?? 'Sign-in failed.',
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Sign-in failed. Please try again.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Form(key: _key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.health_and_safety_outlined, size: 64, color: Color(0xFF0F766E)),
          const SizedBox(height: 12),
          const Text('BloodSenz', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Understand your blood reports better.', textAlign: TextAlign.center),
          const SizedBox(height: 30),
          const Text('Welcome back', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => v == null || !v.trim().contains('@') ? 'Enter a valid email.' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _password, obscureText: _obscure,
            decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (v) => v == null || v.isEmpty ? 'Enter your password.' : null,
            onFieldSubmitted: (_) => _login()),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
          const SizedBox(height: 22),
          FilledButton(onPressed: _busy ? null : _login,
            child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in')),
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
            child: const Text('Create an account')),
        ])),
      ),
    ))),
  );
}
