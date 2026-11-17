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



        await Firebase.initializeApp();
        debugPrint('Firebase initialized (google-services.json)');
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized');
      }
    } catch (e) {


      if ('$e'.contains('duplicate-app')) {
        debugPrint('Firebase already initialized (google-services.json)');
      } else {

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


  try {
    await PushService.initLocal();
  } catch (e) {
    debugPrint('Local notification setup failed: $e');
  }


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
