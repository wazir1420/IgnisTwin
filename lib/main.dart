import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const IgnisTwinApp(),
      ),
    );

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
