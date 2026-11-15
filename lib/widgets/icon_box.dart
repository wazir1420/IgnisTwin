import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? bg;
  final double size;
  final VoidCallback? onTap;
  const IconBox(this.icon, {super.key, this.color = AppColors.muted, this.bg, this.size = 44, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg ?? AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: bg == null ? Border.all(color: AppColors.border) : null,
          ),
          child: Icon(icon, color: color, size: size * 0.5),
        ),
      );
}
