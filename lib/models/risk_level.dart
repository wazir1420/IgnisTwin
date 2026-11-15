import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum RiskLevel { normal, warning, critical, unknown }

extension RiskLevelX on RiskLevel {
  Color get color => switch (this) {
        RiskLevel.normal => AppColors.green,
        RiskLevel.warning => AppColors.yellow,
        RiskLevel.critical => AppColors.red,
        RiskLevel.unknown => AppColors.grey,
      };

  String get label => switch (this) {
        RiskLevel.normal => 'NORMAL',
        RiskLevel.warning => 'WARNING',
        RiskLevel.critical => 'CRITICAL',
        RiskLevel.unknown => 'UNKNOWN',
      };
}
