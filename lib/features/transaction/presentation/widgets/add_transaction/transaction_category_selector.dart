import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class TransactionCategorySelector extends ConsumerWidget {
  final List<CategoryDto> parentCategories;
  final CategoryDto? selectedParentCategory;
  final CategoryDto? selectedCategory;
  final List<CategoryDto> quickSubcategories;
  final bool isClassifying;
  final ValueChanged<CategoryDto> onParentSelected;
  final ValueChanged<CategoryDto> onCategorySelected;
  final VoidCallback onSeeAllPressed;

  const TransactionCategorySelector({
    super.key,
    required this.parentCategories,
    required this.selectedParentCategory,
    required this.selectedCategory,
    required this.quickSubcategories,
    required this.isClassifying,
    required this.onParentSelected,
    required this.onCategorySelected,
    required this.onSeeAllPressed,
  });

  Map<String, dynamic> _getParentStyle(
    String parentName,
    AppColorsExtension colors,
  ) {
    switch (parentName) {
      case 'Chi tiêu - sinh hoạt':
      case 'Living Expenses':
        return {
          'icon': Icons.restaurant_rounded,
          'color': const Color(0xFFF97316), // Orange
        };
      case 'Chi phí phát sinh':
      case 'Occasional Expenses':
        return {
          'icon': Icons.shopping_bag_rounded,
          'color': const Color(0xFFEAB308), // Yellow
        };
      case 'Chi phí cố định':
      case 'Fixed Expenses':
        return {
          'icon': Icons.receipt_long_rounded,
          'color': const Color(0xFF3B82F6), // Blue
        };
      case 'Đầu tư - tiết kiệm':
      case 'Investment & Savings':
        return {
          'icon': Icons.savings_rounded,
          'color': const Color(0xFF10B981), // Green
        };
      case 'Thu nhập':
      case 'Income':
        return {
          'icon': Icons.account_balance_rounded,
          'color': const Color(0xFF8B5CF6), // Purple
        };
      default:
        return {'icon': Icons.category_rounded, 'color': colors.primary};
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📁 2. Parent Category Section
        Text(
          'parent_category'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scrolling parents list
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: parentCategories.length,
            itemBuilder: (context, index) {
              final parent = parentCategories[index];
              final style = _getParentStyle(parent.name, colors);
              final IconData parentIcon = style['icon'];
              final Color parentColor = style['color'];
              final isSelected = selectedParentCategory?.id == parent.id;

              String displayName = parent.name.tr(ref);

              return GestureDetector(
                onTap: () => onParentSelected(parent),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? parentColor.withOpacity(0.12)
                        : colors.authCardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? parentColor
                          : colors.textSecondary.withOpacity(0.06),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        parentIcon,
                        color: isSelected ? parentColor : colors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: isSelected ? parentColor : colors.textPrimary,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // 📂 3. Subcategory Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'subcategory'.tr(ref),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isClassifying) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                ],
              ],
            ),
            if (selectedParentCategory != null)
              TextButton(
                onPressed: onSeeAllPressed,
                child: Text(
                  'see_all'.tr(ref),
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (quickSubcategories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              'select_parent_category_hint'.tr(ref),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: quickSubcategories.length,
              itemBuilder: (context, index) {
                final category = quickSubcategories[index];
                final iconData = CategoryUIConstants.getIconData(category.icon);
                final catColor = CategoryUIConstants.getColorFromHex(category.color);
                final isSelected = selectedCategory?.id == category.id;

                return GestureDetector(
                  onTap: () => onCategorySelected(category),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.authCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? catColor
                            : colors.textSecondary.withOpacity(0.04),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(
                              isSelected ? 0.25 : 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            color: catColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              category.name.tr(ref),
                              style: TextStyle(
                                color: isSelected ? catColor : colors.textPrimary,
                                fontSize: 11,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
