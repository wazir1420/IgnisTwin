import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Monospace text style (labels, numbers, IDs)
const mono = TextStyle(fontFamily: 'monospace');

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(primary: AppColors.cyan, surface: AppColors.card),
      useMaterial3: true,
    );
