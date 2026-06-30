import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';

class StatisticsSummarySection extends ConsumerWidget {
  const StatisticsSummarySection({super.key});

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  Widget _buildShimmerCard(BuildContext context, double height) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.textSecondary.withValues(alpha: 0.08),
      highlightColor: colors.textSecondary.withValues(alpha: 0.03),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final summaryAsync = ref.watch(reportSummaryProvider);
    final previousSummaryAsync = ref.watch(previousPeriodSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        final previousSummary = previousSummaryAsync.value;

        return Column(
          children: [
            // Net balance main card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'net_balance'.tr(ref).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(summary.net),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Compare text
                  if (previousSummary != null)
                    _buildComparisonWidget(summary, previousSummary, colors, ref),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Two expanded boxes (Income & Expense)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.textSecondary.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trending_up_rounded, color: colors.incomeGreen, size: 22),
                        const SizedBox(height: 12),
                        Text(
                          'income_label'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(summary.income),
                          style: TextStyle(
                            color: colors.incomeGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.textSecondary.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trending_down_rounded, color: colors.expenseRed, size: 22),
                        const SizedBox(height: 12),
                        Text(
                          'expense_label'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(summary.expense),
                          style: TextStyle(
                            color: colors.expenseRed,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => _buildShimmerCard(context, 220),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'error_with_details'.tr(ref).replaceAll('{error}', err.toString()),
          style: TextStyle(color: colors.expenseRed),
        ),
      ),
    );
  }

  Widget _buildComparisonWidget(ReportSummaryDto current, ReportSummaryDto previous, AppColorsExtension colors, WidgetRef ref) {
    if (previous.expense == 0) return const SizedBox();

    final diff = current.expense - previous.expense;
    final percent = (diff.abs() / previous.expense) * 100;
    final isIncrease = diff > 0;

    final textColor = Colors.white.withValues(alpha: 0.9);
    final icon = isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    final changeText = isIncrease ? 'increased_by'.tr(ref) : 'decreased_by'.tr(ref);
    final compareLabel = 'compare_with_prev'.tr(ref);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            '${percent.toStringAsFixed(1)}% $changeText $compareLabel',
            style: TextStyle(color: textColor, fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
