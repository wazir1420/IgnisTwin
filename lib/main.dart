import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase start. Fail ho jaye to app OFFLINE dikhayegi (dummy data nahi).
  var firebaseReady = true;
  if (!DefaultFirebaseOptions.isConfigured) {
    firebaseReady = false;
    debugPrint(
      'Firebase config khaali hai: lib/firebase_options.dart mein apiKey, '
      'appId aur messagingSenderId bharein.',
    );
  } else {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      firebaseReady = false;
      debugPrint('Firebase init failed: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(firebaseReady: firebaseReady),
      child: const IgnisTwinApp(),
    ),
  );
}

class IgnisTwinApp extends StatelessWidget {
  const IgnisTwinApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'IgnisTwin',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const SplashScreen(),
  );
}
