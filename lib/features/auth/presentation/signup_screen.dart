import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}
class _SignupScreenState extends State<SignupScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController(), _confirm = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _email.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _signup() async {
    if (!_key.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _auth.signUp(email: _email.text, password: _password.text);
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = switch (e.code) {
        'email-already-in-use' => 'An account already exists for this email.',
        'weak-password' => 'Choose a stronger password.',
        'invalid-email' => 'Enter a valid email address.',
        'operation-not-allowed' => 'Enable Email/Password in Firebase Console.',
        _ => e.message ?? 'Account creation failed.',
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Account creation failed. Please try again.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Form(key: _key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.health_and_safety_outlined, size: 58, color: Color(0xFF0F766E)),
          const SizedBox(height: 12),
          const Text('Create your BloodSenz account', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => v == null || !v.trim().contains('@') ? 'Enter a valid email.' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _password, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (minimum 6 characters)', prefixIcon: Icon(Icons.lock_outline)),
            validator: (v) => v == null || v.length < 6 ? 'Use at least 6 characters.' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _confirm, obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_outlined)),
            validator: (v) => v != _password.text ? 'Passwords do not match.' : null),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
          const SizedBox(height: 22),
          FilledButton(onPressed: _busy ? null : _signup,
            child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account')),
        ])),
      ),
    ))),
  );
}
