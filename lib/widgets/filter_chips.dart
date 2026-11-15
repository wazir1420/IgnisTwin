import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class FilterChips extends StatelessWidget {
  final List<String> items;
  final int selected;
  final ValueChanged<int> onSelect;
  const FilterChips(this.items, this.selected, this.onSelect, {super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.cyan : AppColors.card,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: i == selected ? AppColors.cyan : AppColors.border),
                  ),
                  child: Text(items[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: i == selected ? Colors.black : AppColors.muted,
                      )),
                ),
              ),
            ),
        ]),
      );
}
