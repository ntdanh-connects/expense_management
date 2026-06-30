import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

class CategorySubcategoryBreakdown extends StatelessWidget {
  final List<TransactionEntity> selectedPeriodTxs;
  final double currentPeriodAmount;
  final String? selectedSubcategoryFilter;
  final ValueChanged<String?> onSubcategoryFilterChanged;
  final String? categoryColor;
  final String? categoryIcon;

  const CategorySubcategoryBreakdown({
    super.key,
    required this.selectedPeriodTxs,
    required this.currentPeriodAmount,
    required this.selectedSubcategoryFilter,
    required this.onSubcategoryFilterChanged,
    this.categoryColor,
    this.categoryIcon,
  });

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (selectedPeriodTxs.isEmpty || currentPeriodAmount <= 0) {
      return const SizedBox.shrink();
    }

    final Map<String, double> subcatSums = {};
    final Map<String, TransactionEntity> subcatSampleTxs = {};

    for (final tx in selectedPeriodTxs) {
      final name = tx.categoryName ?? 'Chưa phân loại';
      subcatSums[name] = (subcatSums[name] ?? 0.0) + (tx.amount * (tx.exchangeRate ?? 1.0));
      if (!subcatSampleTxs.containsKey(name)) {
        subcatSampleTxs[name] = tx;
      }
    }

    if (subcatSums.length <= 1) return const SizedBox.shrink();

    final sortedNames = subcatSums.keys.toList()
      ..sort((a, b) => subcatSums[b]!.compareTo(subcatSums[a]!));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cơ cấu danh mục con',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedSubcategoryFilter != null)
                GestureDetector(
                  onTap: () => onSubcategoryFilterChanged(null),
                  child: Text(
                    'Xoá lọc',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Nhấn vào danh mục con để lọc nhanh các giao dịch bên dưới',
            style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedNames.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final name = sortedNames[index];
              final amount = subcatSums[name]!;
              final pct = amount / currentPeriodAmount;
              final sampleTx = subcatSampleTxs[name]!;

              final hasCategory = sampleTx.categoryId != null && sampleTx.categoryId!.isNotEmpty;
              final catColor = hasCategory
                  ? CategoryUIConstants.getColorFromHex(
                      sampleTx.categoryColor ?? categoryColor,
                      categoryName: sampleTx.categoryName,
                    )
                  : colors.textSecondary;
              final catIcon = hasCategory
                  ? CategoryUIConstants.getIconData(
                      sampleTx.categoryIcon ?? categoryIcon,
                      categoryName: sampleTx.categoryName,
                    )
                  : Icons.help_outline_rounded;

              final isSelected = selectedSubcategoryFilter == name;

              return InkWell(
                onTap: () {
                  if (selectedSubcategoryFilter == name) {
                    onSubcategoryFilterChanged(null);
                  } else {
                    onSubcategoryFilterChanged(name);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withValues(alpha: 0.06) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? colors.primary.withValues(alpha: 0.3) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: catColor.withValues(alpha: 0.12),
                            radius: 16,
                            child: Icon(catIcon, color: catColor, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(amount),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(pct * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(3),
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
        ],
      ),
    );
  }
}
