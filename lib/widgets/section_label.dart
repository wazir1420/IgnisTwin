import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const SectionLabel(this.text, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(text, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 13)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: mono.copyWith(color: AppColors.cyan, fontSize: 13)),
            ),
        ]),
      );
}
