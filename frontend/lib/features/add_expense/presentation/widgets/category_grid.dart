import 'package:flutter/material.dart';

import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 3-column grid of category tiles. Selected tile flips to solid category
/// color with white text (design/Expensy.html lines 287-296).
class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) {
        final c = categories[i];
        final selected = c.id == selectedId;
        return _Tile(category: c, selected: selected, onTap: () => onSelect(c));
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const _Tile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.colorValue;
    final bg = category.bgTintValue;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.22) : bg,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                category.abbr,
                style: AppTextStyles.labelStrong.copyWith(
                  fontSize: 10.5,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              category.label,
              style: AppTextStyles.label.copyWith(
                fontSize: 11,
                color: selected ? Colors.white : AppColors.inkMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
