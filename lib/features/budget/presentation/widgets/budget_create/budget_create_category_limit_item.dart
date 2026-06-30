import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

class TempCategoryBudget {
  final String? id; // Database id, null if new
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final TextEditingController controller;
  final CurrencyTextInputFormatter formatter;

  TempCategoryBudget({
    this.id,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.controller,
    required this.formatter,
  });
}

class BudgetCreateCategoryLimitItem extends ConsumerWidget {
  final TempCategoryBudget item;
  final String currencySymbol;
  final VoidCallback onDelete;
  final ValueChanged<String> onChanged;

  const BudgetCreateCategoryLimitItem({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final categoryIcon = CategoryUIConstants.getIconData(item.categoryIcon, categoryName: item.categoryName);
    final categoryColor = CategoryUIConstants.getColorFromHex(item.categoryColor, categoryName: item.categoryName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.005),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 14),
          
          // Name & Input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.categoryName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  controller: item.controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập hạn mức...',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withOpacity(0.3),
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                    suffixText: currencySymbol,
                    suffixStyle: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.primary, width: 1.2),
                    ),
                  ),
                  inputFormatters: [item.formatter],
                  onChanged: onChanged,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'please_enter_limit'.tr(ref);
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Delete Button
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colors.expenseRed.withOpacity(0.7)),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
