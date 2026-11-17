import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 2200), _next);
  }

  Future<void> _next() async {
    if (!mounted) return;
    try {
      final session = await AuthService.instance.restoreSession();
      if (!mounted) return;

      if (session == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      context.read<AppProvider>().setCurrentUser(
        role: session['role'].toString(),
        name: session['name']?.toString() ?? 'Operator',
        email: session['email']?.toString() ?? '',
        uid: session['uid']?.toString() ?? '',
        phone: session['phone']?.toString() ?? '',
        photoBase64: session['photoBase64']?.toString() ?? '',
      );
      context.read<AppProvider>().start();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => session['role'] == 'admin'
              ? const AdminDashboardScreen()
              : const Shell(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LoginScreen(initialMessage: 'Could not restore your session: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.9,
          colors: [Color(0xFF3A1D10), AppColors.bg],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 5),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Icon(Icons.shield_outlined, color: AppColors.muted, size: 52),
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.local_fire_department,
                      color: Colors.deepOrange,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(
                    text: 'IGNIS',
                    style: TextStyle(color: AppColors.text),
                  ),
                  TextSpan(
                    text: 'TWIN',
                    style: TextStyle(color: AppColors.cyan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'FIRE & SMOKE SAFETY MONITORING',
              style: mono.copyWith(
                color: AppColors.muted,
                letterSpacing: 2.5,
                fontSize: 12,
              ),
            ),
            const Spacer(flex: 6),
            SizedBox(
              width: 150,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 2000),
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  color: AppColors.cyan,
                  backgroundColor: AppColors.border,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'FIRE & SMOKE SAFETY',
              style: mono.copyWith(
                color: AppColors.grey,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}
