import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget/budget_month_selector.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget/budget_overall_card.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget/budget_empty_overall_card.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget/budget_category_tile.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget/budget_shimmer.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final month = ref.watch(selectedBudgetMonthProvider);
    final year = ref.watch(selectedBudgetYearProvider);
    final now = DateTime.now();
    final isPastMonth = year < now.year || (year == now.year && month < now.month);

    final budgetsAsync = ref.watch(budgetListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🗓️ 1. BỘ CHỌN THÁNG/NĂM CÓ CHEVRON
        const BudgetMonthSelector(),
        const SizedBox(height: 18),

        // 🟢 LOAD BUDGETS DATA
        budgetsAsync.when(
          skipLoadingOnReload: false,
          data: (budgetList) {
            // Find General budget (categoryId == null)
            final generalBudget = budgetList.where((b) => b.categoryId == null).firstOrNull;
            final categoryBudgets = budgetList.where((b) => b.categoryId != null).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💳 2. NGÂN SÁCH TỔNG CARD
                if (generalBudget != null) ...[
                  BudgetOverallCard(generalBudget: generalBudget)
                ] else ...[
                  BudgetEmptyOverallCard(isPastMonth: isPastMonth)
                ],
                const SizedBox(height: 16),

                // 📋 3. NÚT SAO CHÉP NGÂN SÁCH THÁNG TRƯỚC
                if (!isPastMonth) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary.withOpacity(0.12),
                        foregroundColor: colors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: colors.primary.withOpacity(0.2)),
                        ),
                      ),
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                      label: Text(
                        'copy_previous'.tr(ref),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(budgetListProvider.notifier).copyFromPreviousMonth();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('success'.tr(ref)),
                                backgroundColor: colors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${'copy_previous_failed'.tr(ref)}: $e'),
                                backgroundColor: colors.expenseRed,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 24),

                // 🏷️ 4. TIÊU ĐỀ SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'spending_categories'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (categoryBudgets.isNotEmpty && !isPastMonth)
                      TextButton(
                        onPressed: () => context.push(RoutePaths.budgetCreate).then((_) {
                          ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
                        }),
                        child: Text(
                          'add_new'.tr(ref),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // 📊 5. DANH SÁCH HẠN MỨC CHI TIÊU
                if (categoryBudgets.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.pie_chart_outline_rounded,
                              size: 44, color: colors.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'no_category_budget_setup'.tr(ref),
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                          if (!isPastMonth) ...[
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text('add_category_budget_button'.tr(ref)),
                              onPressed: () => context.push(RoutePaths.budgetCreate).then((_) {
                                ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryBudgets.length,
                    itemBuilder: (context, index) {
                      final item = categoryBudgets[index];
                      return BudgetCategoryTile(item: item);
                    },
                  ),
                  const SizedBox(height: 14),
                  if (!isPastMonth)
                    // NÚT THÊM DANH MỤC NHANH Ở CUỐI BÀI
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.push(RoutePaths.budgetCreate).then((_) {
                          ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
                        }),
                        icon: Icon(Icons.add_circle_outline_rounded, color: colors.primary),
                        label: Text(
                          'add_category_limit_button'.tr(ref),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
          loading: () => const BudgetShimmer(),
          error: (error, _) => Container(
            height: 100,
            alignment: Alignment.center,
            child: Text(
              '${'error_occurred'.tr(ref)}: $error',
              style: TextStyle(color: colors.expenseRed),
            ),
          ),
        ),
      ],
    );
  }
}


