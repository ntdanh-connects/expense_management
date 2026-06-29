import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

class RecurringCategoryPickerSheet extends ConsumerStatefulWidget {
  final List<CategoryDto> parents;
  final CategoryDto? selectedCategory;
  final void Function(CategoryDto parent, CategoryDto? sub) onSelected;

  const RecurringCategoryPickerSheet({
    super.key,
    required this.parents,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  ConsumerState<RecurringCategoryPickerSheet> createState() =>
      _RecurringCategoryPickerSheetState();
}

class _RecurringCategoryPickerSheetState
    extends ConsumerState<RecurringCategoryPickerSheet> {
  CategoryDto? _selectedParent;

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final children = _selectedParent?.children ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                if (_selectedParent != null) ...[
                  GestureDetector(
                    onTap: () => setState(() => _selectedParent = null),
                    child: Icon(Icons.arrow_back_ios_rounded,
                        size: 18, color: colors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                ],
                if (_selectedParent != null)
                  Icon(
                    _getParentStyle(_selectedParent!.name, colors)['icon'],
                    color: _getParentStyle(_selectedParent!.name, colors)['color'],
                    size: 22,
                  ),
                if (_selectedParent != null) const SizedBox(width: 8),
                Text(
                  _selectedParent == null
                      ? 'recurring_select_category'.tr(ref)
                      : (_selectedParent!.name.tr(ref)),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Expanded(
            child: _selectedParent == null
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: widget.parents.length,
                    itemBuilder: (context, index) {
                      final parent = widget.parents[index];
                      final style = _getParentStyle(parent.name, colors);
                      final bool hasChildren =
                          parent.children != null && parent.children!.isNotEmpty;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (hasChildren) {
                            setState(() => _selectedParent = parent);
                          } else {
                            widget.onSelected(parent, null);
                            Navigator.pop(context);
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  (style['color'] as Color).withOpacity(0.12),
                              child: Icon(style['icon'] as IconData,
                                  color: style['color'] as Color, size: 24),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              parent.name.tr(ref),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final sub = children[index];
                      final iconData = CategoryUIConstants.getIconData(sub.icon);
                      final color = CategoryUIConstants.getColorFromHex(sub.color);
                      final isSelected = widget.selectedCategory?.id == sub.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          widget.onSelected(_selectedParent!, sub);
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  color.withOpacity(isSelected ? 0.25 : 0.12),
                              child: Icon(iconData, color: color, size: 24),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              sub.name.tr(ref),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? color : null,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
