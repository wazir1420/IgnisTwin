import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/session.dart';
import '../providers/app_provider.dart';
import '../widgets/app_card.dart';
import 'shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final org = TextEditingController(text: 'HOME001');
  final email = TextEditingController();
  final pass = TextEditingController();
  String? error;

  // Demo credentials (change as you like)
  static const _org = 'HOME001';
  static const _email = 'admin@ignistwin.com';
  static const _pass = '123456';

  Future<void> _login() async {
    if (org.text.trim().toUpperCase() == _org &&
        email.text.trim().toLowerCase() == _email &&
        pass.text == _pass) {
      final app = context.read<AppProvider>();
      await Session.setLoggedIn(true); // agli dafa seedha app khulegi
      app.start();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      setState(() => error = 'Wrong details. Demo: HOME001 / $_email / $_pass');
    }
  }

  Widget _field(String label, TextEditingController c, {String? hint, bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            obscureText: obscure,
            style: const TextStyle(fontSize: 17),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.grey),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cyan)),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 30),
              Row(children: [
                const Icon(Icons.shield_outlined, color: AppColors.muted),
                const SizedBox(width: 10),
                Text('IGNISTWIN', style: mono.copyWith(color: AppColors.muted, letterSpacing: 2)),
              ]),
              const SizedBox(height: 30),
              const Text('Sign in', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Emergency monitoring & response console', style: TextStyle(color: AppColors.muted, fontSize: 16)),
              const SizedBox(height: 30),
              _field('HOME ID', org),
              _field('EMAIL', email, hint: 'you@organization.com'),
              _field('PASSWORD', pass, obscure: true),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(error!, style: const TextStyle(color: AppColors.red)),
                ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _login,
                  child: const Text('Sign In  →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ),
              ),
              const SizedBox(height: 40),
              AppCard(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline, color: AppColors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Academic prototype. Not a certified replacement for fire alarms, sprinkler systems, or emergency services.',
                      style: mono.copyWith(color: AppColors.grey, fontSize: 13),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
}

