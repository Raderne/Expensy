import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

const double _kTileSize = 80.0;

/// Horizontal scroll row of category tiles followed by a "+" tile that opens
/// a full-grid sheet — always visible so the user can always browse all options.
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
    return SizedBox(
      height: _kTileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        // categories + "+" tile
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          if (i == categories.length) {
            return _MoreTile(
              categories: categories,
              selectedId: selectedId,
              onSelect: onSelect,
            );
          }
          final c = categories[i];
          return _Tile(
            category: c,
            selected: c.id == selectedId,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(c);
            },
          );
        },
      ),
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
        width: _kTileSize,
        height: _kTileSize,
        padding: const EdgeInsets.all(8),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                fontSize: 11,
                height: 1.1,
                color: selected ? Colors.white : AppColors.inkMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  const _MoreTile({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAll(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _kTileSize,
        height: _kTileSize,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'More',
              style: AppTextStyles.label.copyWith(
                fontSize: 11,
                height: 1.1,
                color: AppColors.inkMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000C22),
      builder: (sheetCtx) => _AllCategoriesSheet(
        categories: categories,
        selectedId: selectedId,
        onSelect: (c) {
          HapticFeedback.selectionClick();
          onSelect(c);
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }
}

class _AllCategoriesSheet extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  const _AllCategoriesSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000C22),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inkFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('All categories', style: AppTextStyles.titleM),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (_, i) {
                  final c = categories[i];
                  return _Tile(
                    category: c,
                    selected: c.id == selectedId,
                    onTap: () => onSelect(c),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
