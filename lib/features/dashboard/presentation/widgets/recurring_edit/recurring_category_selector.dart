import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

class RecurringCategorySelector extends ConsumerWidget {
  final CategoryDto? selectedCategory;
  final CategoryDto? selectedParentCategory;
  final String? defaultCategoryName;
  final VoidCallback onTap;

  const RecurringCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.selectedParentCategory,
    required this.defaultCategoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final catIcon = CategoryUIConstants.getIconData(selectedCategory?.icon,
        categoryName: selectedCategory?.name);
    final catColor = CategoryUIConstants.getColorFromHex(selectedCategory?.color,
        categoryName: selectedCategory?.name);
    final catName = selectedCategory?.name ??
        defaultCategoryName ??
        'recurring_select_category'.trRead(ref);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catName.tr(ref),
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  if (selectedParentCategory != null &&
                      selectedParentCategory?.id != selectedCategory?.id)
                    Text(
                      selectedParentCategory!.name.tr(ref),
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
