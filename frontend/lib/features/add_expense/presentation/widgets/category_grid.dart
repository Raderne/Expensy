import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/categories_repository.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import 'add_edit_category_sheet.dart';

/// Horizontal 2-row grid of category tiles.
///
/// Tile size is derived from the **parent** width (via [LayoutBuilder]) so
/// two-pane / Fold layouts don't inflate tiles to the full window width.
/// Roomier panes (≥360dp content) show 4 tiles per row; otherwise 3.
class CategoryGrid extends StatelessWidget {
  /// Content width at which a fourth tile per row still leaves comfortable
  /// targets. Below this, three.
  static const double _fourTileWidth = 360;

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  /// Tiles per row for a given content width. Shared with the "All categories"
  /// sheet so both grids break at the same place.
  static int tilesPerRow(double contentWidth) =>
      contentWidth >= _fourTileWidth ? 4 : 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the pane/parent width, never the full window — critical in
        // two-pane. Derived inline rather than cached in State: a post-frame
        // setState would render one frame at the previous tile size.
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final tiles = tilesPerRow(w);
        // N tiles → (N−1) gaps of 8px. Width already excludes outer padding.
        final tileSize = (w - (tiles - 1) * 8.0) / tiles;

        return SizedBox(
          height: tileSize * 2 + 8,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            // categories + "More" tile
            itemCount: categories.length + 1,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              // cross-axis = vertical in a horizontal scroll → tile height
              maxCrossAxisExtent: tileSize,
              // main-axis = horizontal → tile width
              mainAxisExtent: tileSize,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (ctx, i) {
              if (i == categories.length) {
                return _MoreTile(selectedId: selectedId, onSelect: onSelect);
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
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _Tile({
    required this.category,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.colorValue;
    final bg = category.bgTintValue;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  const _MoreTile({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAll(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
    showAppBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => _AllCategoriesSheet(
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

class _AllCategoriesSheet extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  const _AllCategoriesSheet({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesViewProvider);
    final categories = categoriesAsync.value ?? const [];
    final displayCats = categories
        .where((c) => c.key != 'income' && c.key != 'subscriptions')
        .toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.scrim,
            blurRadius: 24,
            offset: const Offset(0, -4),
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
              // Same break as the inline grid, so the sheet gains a fourth
              // column on a Fold inner display instead of showing three fat
              // tiles across a much wider sheet.
              LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: displayCats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: CategoryGrid.tilesPerRow(
                      constraints.maxWidth,
                    ),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (_, i) {
                    final c = displayCats[i];
                    return _Tile(
                      category: c,
                      selected: c.id == selectedId,
                      onTap: () => onSelect(c),
                      onLongPress: c.isSystem
                          ? null
                          : () async {
                              await showEditSheet<bool>(
                                context,
                                (_) => AddEditCategorySheet(existing: c),
                              );
                            },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _AddCategoryButton(onDone: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  final VoidCallback onDone;
  const _AddCategoryButton({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showEditSheet<bool>(context, (_) => const AddEditCategorySheet());
        onDone();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Add category',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
