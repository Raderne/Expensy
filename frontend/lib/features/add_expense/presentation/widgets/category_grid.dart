import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/categories_repository.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/widgets/edit_sheet_shell.dart';
import 'add_edit_category_sheet.dart';

/// Horizontal 2-row grid of category tiles.
///
/// Tile size is derived from the screen width so exactly 3 tiles are visible
/// per row (6 total) before the user scrolls. The calculation runs once in
/// [didChangeDependencies] and is only repeated on screen-size changes
/// (orientation flip, window resize) — not on every parent rebuild.
class CategoryGrid extends StatefulWidget {
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
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  // 3 tiles per row across (screenWidth − 36 outer padding − 16 inter-tile gaps) / 3
  // Initial value is a reasonable fallback before the first frame.
  double _tileSize = 80.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Parent SliverPadding: 18 left + 18 right = 36 px
    // 3 tiles per row → 2 gaps of 8 px = 16 px
    _tileSize = (screenWidth - 36.0 - 16.0) / 3.0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tileSize * 2 + 8,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        // categories + "More" tile
        itemCount: widget.categories.length + 1,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          // cross-axis = vertical in a horizontal scroll → tile height
          maxCrossAxisExtent: _tileSize,
          // main-axis = horizontal → tile width
          mainAxisExtent: _tileSize,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (ctx, i) {
          if (i == widget.categories.length) {
            return _MoreTile(
              selectedId: widget.selectedId,
              onSelect: widget.onSelect,
            );
          }
          final c = widget.categories[i];
          return _Tile(
            category: c,
            selected: c.id == widget.selectedId,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSelect(c);
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000C22),
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? const [];
    final displayCats = categories
        .where((c) => c.key != 'income' && c.key != 'subscriptions')
        .toList();

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
                itemCount: displayCats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
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
