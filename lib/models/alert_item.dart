import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'risk_level.dart';

class AlertItem {
  final RiskLevel level;
  final bool resolved;
  final String title;
  final String subtitle;
  final DateTime time;
  bool read;

  AlertItem(this.level, this.title, this.subtitle, {this.resolved = false})
      : time = DateTime.now(),
        read = false;

  Color get color => resolved ? AppColors.green : level.color;
}
