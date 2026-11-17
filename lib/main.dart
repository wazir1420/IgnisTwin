import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'services/push_service.dart';

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
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android: google-services.json + Gradle plugin native [DEFAULT] app khud
        // bana dete hain. Bina options wali call maujooda app ko use karti hai —
        // naya banane ki koshish nahi karti, is liye duplicate-app nahi aata.
        await Firebase.initializeApp();
        debugPrint('Firebase initialized (google-services.json)');
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized');
      }
    } catch (e) {
      // Android par google-services.json/Gradle plugin native [DEFAULT] app pehle
      // hi bana deta hai — "duplicate-app" ka matlab app already ready hai.
      if ('$e'.contains('duplicate-app')) {
        debugPrint('Firebase already initialized (google-services.json)');
      } else {
        // Koi aur error ho, lekin default app phir bhi maujood ho to chalne dein
        try {
          Firebase.app();
          debugPrint('Firebase app pehle se maujood hai: $e');
        } catch (_) {
          firebaseReady = false;
          debugPrint('Firebase init failed: $e');
        }
      }
    }
  }

  // Notifications ka channel/permission (Firebase ke bagair bhi chalta hai)
  try {
    await PushService.initLocal();
  } catch (e) {
    debugPrint('Local notification setup failed: $e');
  }

  // FCM: push receive (sirf Firebase ready ho to)
  if (firebaseReady) {
    try {
      await PushService.initFcm();
    } catch (e) {
      debugPrint('FCM setup failed: $e');
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
