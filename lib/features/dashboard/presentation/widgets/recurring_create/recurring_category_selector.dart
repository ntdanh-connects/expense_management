import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

class RecurringCategorySelector extends ConsumerWidget {
  final List<CategoryDto> parents;
  final CategoryDto? selectedParentCategory;
  final CategoryDto? selectedCategory;
  final String selectedType;
  final List<CategoryDto> quickSubs;
  final ValueChanged<CategoryDto> onParentSelected;
  final ValueChanged<CategoryDto> onSubSelected;
  final VoidCallback onShowAll;
  final VoidCallback onAddSubcat;

  const RecurringCategorySelector({
    super.key,
    required this.parents,
    required this.selectedParentCategory,
    required this.selectedCategory,
    required this.selectedType,
    required this.quickSubs,
    required this.onParentSelected,
    required this.onSubSelected,
    required this.onShowAll,
    required this.onAddSubcat,
  });

  Map<String, dynamic> _getParentStyle(String name, AppColorsExtension colors) {
    switch (name) {
      case 'Chi tiêu - sinh hoạt':
      case 'Living Expenses':
        return {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF97316)};
      case 'Chi phí phát sinh':
      case 'Occasional Expenses':
        return {'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEAB308)};
      case 'Chi phí cố định':
      case 'Fixed Expenses':
        return {'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF3B82F6)};
      case 'Đầu tư - tiết kiệm':
      case 'Investment & Savings':
        return {'icon': Icons.savings_rounded, 'color': const Color(0xFF10B981)};
      case 'Thu nhập':
      case 'Income':
        return {'icon': Icons.account_balance_rounded, 'color': const Color(0xFF8B5CF6)};
      default:
        return {'icon': Icons.category_rounded, 'color': colors.primary};
    }
  }

  Widget _buildSectionLabel(String label, AppColorsExtension colors, WidgetRef ref,
      {String? trailing, VoidCallback? onTrailingTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing,
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('recurring_category_section'.tr(ref), colors, ref,
            trailing: 'recurring_see_all'.tr(ref),
            onTrailingTap: onShowAll),
        const SizedBox(height: 10),

        // Parent categories horizontal scroll
        SizedBox(
          height: 90,
          child: parents.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: parents.length,
                  itemBuilder: (context, index) {
                    final parent = parents[index];
                    final style = _getParentStyle(parent.name, colors);
                    final isSelected = selectedParentCategory?.id == parent.id;
                    final IconData parentIcon = style['icon'];
                    final Color parentColor = style['color'];

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
                              : colors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? parentColor
                                : colors.textSecondary.withOpacity(0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(parentIcon,
                                color: isSelected ? parentColor : colors.textSecondary,
                                size: 22),
                            const SizedBox(height: 6),
                            FittedBox(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  parent.name.tr(ref),
                                  style: TextStyle(
                                    color: isSelected ? parentColor : colors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
        const SizedBox(height: 12),

        // Quick subcategories
        if (quickSubs.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: quickSubs.length + 1,
              itemBuilder: (context, index) {
                if (index == quickSubs.length) {
                  // "Thêm" button
                  return GestureDetector(
                    onTap: onAddSubcat,
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.textSecondary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_rounded,
                                color: colors.textSecondary, size: 20),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'recurring_add_more'.tr(ref),
                            style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final sub = quickSubs[index];
                final isSelected = selectedCategory?.id == sub.id;
                final iconData = CategoryUIConstants.getIconData(sub.icon);
                final catColor = CategoryUIConstants.getColorFromHex(sub.color);

                return GestureDetector(
                  onTap: () => onSubSelected(sub),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? catColor : colors.textSecondary.withOpacity(0.06),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(isSelected ? 0.25 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: catColor, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              sub.name.tr(ref),
                              style: TextStyle(
                                color: isSelected ? catColor : colors.textPrimary,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
