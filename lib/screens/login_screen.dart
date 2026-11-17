import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_card.dart';
import 'admin_dashboard_screen.dart';
import 'shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool isSignUp = false;
  bool submitting = false;
  String? error;
  String? message;

  @override
  void initState() {
    super.initState();
    error = widget.initialMessage;
  }

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (submitting) return;

    final userEmail = email.text.trim();
    final userPassword = password.text;
    if (!userEmail.contains('@') || userPassword.isEmpty) {
      setState(() => error = 'Enter a valid email address and password.');
      return;
    }

    if (isSignUp) {
      if (fullName.text.trim().isEmpty) {
        setState(() => error = 'Enter your name.');
        return;
      }
      if (userPassword.length < 8) {
        setState(() => error = 'Password must be at least 8 characters long.');
        return;
      }
      if (userPassword != confirmPassword.text) {
        setState(() => error = 'Passwords do not match.');
        return;
      }
    }

    setState(() {
      submitting = true;
      error = null;
      message = null;
    });

    try {
      if (isSignUp) {
        await AuthService.instance.createAccount(
          email: userEmail,
          password: userPassword,
          name: fullName.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          isSignUp = false;
          password.clear();
          confirmPassword.clear();
          message =
              'Access request submitted. You can sign in after an administrator approves your account.';
        });
        return;
      }

      final app = context.read<AppProvider>();
      final profile = await AuthService.instance.signIn(
        email: userEmail,
        password: userPassword,
      );
      app.setCurrentUser(
        role: profile['role'].toString(),
        name: profile['name']?.toString() ?? userEmail,
        email: profile['email']?.toString() ?? userEmail,
        uid: profile['uid'].toString(),
        phone: profile['phone']?.toString() ?? '',
        photoBase64: profile['photoBase64']?.toString() ?? '',
      );
      app.start();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => profile['role'] == 'admin'
              ? const AdminDashboardScreen()
              : const Shell(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = _mapFirebaseError(e.code));
    } on AuthAccessException catch (e) {
      setState(() => error = e.message);
    } on PlatformException catch (e) {
      setState(() => error = _mapAuthPlatformError(e.code));
    } on FirebaseException catch (e) {
      final detail = e.message?.toLowerCase() ?? '';
      if (e.plugin == 'firebase_database' &&
          (e.code == 'permission-denied' ||
              e.code == 'unknown' ||
              detail.contains('permission denied'))) {
        setState(
          () => error =
              'Realtime Database access denied. In Firebase Console, publish the database.rules.json rules and make sure this account UID has a users/{UID} profile with role: admin.',
        );
      } else {
        setState(
          () => error =
              'Firebase ${e.plugin} error (${e.code}): ${e.message ?? 'No additional details.'}',
        );
      }
    } catch (e) {
      setState(() => error = 'Could not complete the request: $e');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final userEmail = email.text.trim();
    if (!userEmail.contains('@')) {
      setState(() => error = 'Enter your email address first.');
      return;
    }

    try {
      await AuthService.instance.sendPasswordResetEmail(userEmail);
      if (!mounted) return;
      setState(() {
        error = null;
        message = 'Password reset link sent to $userEmail.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() => error = _mapFirebaseError(e.code));
    } on PlatformException catch (e) {
      setState(
        () => error = _mapAuthPlatformError(e.code, passwordReset: true),
      );
    } catch (e) {
      setState(() => error = 'Could not send reset email: $e');
    }
  }

  String _mapAuthPlatformError(String code, {bool passwordReset = false}) {
    if (code.toUpperCase() == 'ERROR_INVALID_CREDENTIAL') {
      if (passwordReset) {
        return 'The password reset request could not be verified. Check the email address and try again.';
      }
      return 'Email or password is incorrect, or the sign-in details have expired. Check your details or reset your password.';
    }
    final action = passwordReset ? 'send the reset link' : 'sign in';
    return 'Could not $action (${code.replaceAll('_', ' ').toLowerCase()}). Please try again.';
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect. Check your details or reset your password.';
      case 'invalid-email':
        return 'Email format is invalid.';
      case 'network-request-failed':
        return 'Network unavailable. Check your connection and try again.';
      default:
        return 'Firebase authentication error ($code). Please try again.';
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autocorrect: false,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.grey),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cyan),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.75),
          radius: 1.2,
          colors: [Color(0xFF162B3D), AppColors.bg],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppColors.cyan,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IGNISTWIN',
                                style: mono.copyWith(
                                  color: AppColors.muted,
                                  letterSpacing: 2,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Sign in to your account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      selected: {isSignUp},
                      segments: const [
                        ButtonSegment(value: false, label: Text('Sign In')),
                        ButtonSegment(
                          value: true,
                          label: Text('Request Access'),
                        ),
                      ],
                      onSelectionChanged: (value) => setState(() {
                        isSignUp = value.first;
                        error = null;
                        message = null;
                      }),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      isSignUp ? 'Create an access request' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Stay informed about smoke and fire alerts.',
                      style: TextStyle(color: AppColors.muted, fontSize: 15),
                    ),
                    const SizedBox(height: 18),
                    if (isSignUp)
                      _field('Full name', fullName, hint: 'Aisha Khan'),
                    _field(
                      'Email',
                      email,
                      hint: 'name@company.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _field(
                      'Password',
                      password,
                      hint: 'At least 8 characters',
                      obscure: true,
                    ),
                    if (isSignUp)
                      _field(
                        'Confirm password',
                        confirmPassword,
                        hint: 'Re-type password',
                        obscure: true,
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          message!,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (!isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton(
                              onPressed: submitting ? null : _sendPasswordReset,
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: submitting ? null : _submit,
                        child: Text(
                          submitting
                              ? 'Working...'
                              : isSignUp
                              ? 'Create account'
                              : 'Sign in',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'New accounts need administrator approval. Admin accounts go straight to the admin dashboard.',
                      style: mono.copyWith(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
