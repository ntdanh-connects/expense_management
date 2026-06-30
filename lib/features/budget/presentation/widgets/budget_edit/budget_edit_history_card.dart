import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:shimmer/shimmer.dart';

class BudgetEditHistoryShimmer extends StatelessWidget {
  const BudgetEditHistoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Column(
        children: List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}

class BudgetEditHistoryCard extends ConsumerWidget {
  final bool isLoadingHistory;
  final List<Map<String, dynamic>> historyData;
  final String userCurrency;
  final String currencySymbol;
  final dynamic ratesData;
  final double Function(double amount, String from, String to, dynamic rates) convertAmount;

  const BudgetEditHistoryCard({
    super.key,
    required this.isLoadingHistory,
    required this.historyData,
    required this.userCurrency,
    required this.currencySymbol,
    required this.ratesData,
    required this.convertAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
      ),
      child: isLoadingHistory
          ? const BudgetEditHistoryShimmer()
          : historyData.isEmpty
              ? Center(child: Text('no_budget_history'.tr(ref)))
              : Column(
                  children: historyData.map((hist) {
                    final histLimit = hist['limit'] as double;
                    final histUsed = hist['used'] as double;
                    final histMonthLabel = hist['monthLabel'] as String;
                    
                    double histPct = 0.0;
                    if (histLimit > 0) {
                      histPct = histUsed / histLimit;
                    }
                    
                    Color histBarColor = colors.incomeGreen;
                    if (histPct >= 1.0) {
                      histBarColor = colors.expenseRed;
                    } else if (histPct >= 0.8) {
                      histBarColor = Colors.orange;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                histMonthLabel,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${AppConstant.formatMoney(convertAmount(histUsed, 'VND', userCurrency, ratesData), userCurrency)} $currencySymbol / ${AppConstant.formatMoney(convertAmount(histLimit, 'VND', userCurrency, ratesData), userCurrency)} $currencySymbol',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: histPct.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: colors.textSecondary.withOpacity(0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(histBarColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
