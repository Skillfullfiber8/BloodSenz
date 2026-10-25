import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      final auth = FirebaseAuth.instance;
      if (_register) {
        await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text);
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text);
      }
      // The authStateChanges stream in main.dart switches to the dashboard.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Authentication failed.');
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.health_and_safety_rounded, size: 54, color: Color(0xFF16A6A1)),
          const SizedBox(height: 14),
          const Text('BloodSenz', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_register ? 'Create your private account' : 'Sign in to your account',
            textAlign: TextAlign.center),
          const SizedBox(height: 28),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress,
            autocorrect: false, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          TextField(controller: _password, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (minimum 6 characters)', border: OutlineInputBorder())),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
          const SizedBox(height: 18),
          FilledButton(onPressed: _busy ? null : _submit,
            child: Padding(padding: const EdgeInsets.all(12), child: Text(_busy ? 'Please wait…' : (_register ? 'Create account' : 'Sign in')))),
          TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; }),
            child: Text(_register ? 'Already have an account? Sign in' : 'New to BloodSenz? Create an account')),
        ],
      )),
    ))),
  );
}
