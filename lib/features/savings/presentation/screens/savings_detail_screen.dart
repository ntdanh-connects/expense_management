import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';
import 'package:expense_management/features/savings/presentation/provider/savings_notifier.dart';
import 'package:expense_management/shared/widgets/shimmer_components.dart';
import 'package:expense_management/shared/widgets/error_state_widget.dart';

import '../widgets/savings_progress_card.dart';
import '../widgets/savings_action_buttons.dart';
import '../widgets/savings_history_list.dart';
import '../widgets/savings_tx_dialog_content.dart';

class SavingsDetailScreen extends ConsumerWidget {
  final String goalId;
  const SavingsDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final detailState = ref.watch(savingsDetailProvider(goalId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'savings_detail_title'.tr(ref),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () {
            ref.read(savingsListProvider.notifier).loadGoals(silent: true, force: true);
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colors.expenseRed),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detailState.when(
        data: (goal) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PROGRESS GRAPHIC CARD
                SavingsProgressCard(goal: goal),
                const SizedBox(height: 20),

                // 2. ACTION BUTTONS (DEPOSIT / WITHDRAW)
                SavingsActionButtons(
                  onDeposit: () => _openTransactionDialog(context, ref, goal, 'deposit'),
                  onWithdraw: () => _openTransactionDialog(context, ref, goal, 'withdraw'),
                ),
                const SizedBox(height: 24),

                // 3. TRANSACTION HISTORY
                Text(
                  'savings_history_title'.tr(ref),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SavingsHistoryList(goal: goal),
              ],
            ),
          ),
        ),
        loading: () => const _SavingsDetailShimmer(),
        error: (err, _) => ErrorStateWidget(
          errorMessage: 'savings_detail_error'.tr(ref).replaceAll('{error}', err.toString()),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('savings_delete_dialog_title'.tr(ref)),
        content: Text('savings_delete_dialog_desc'.tr(ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'cancel'.tr(ref),
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                await ref.read(savingsListProvider.notifier).deleteGoal(goalId);

                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  context.pop(); // Back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('savings_delete_success'.tr(ref))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'savings_delete_error'.tr(ref).replaceAll('{error}', e.toString()),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              'delete'.tr(ref),
              style: TextStyle(
                color: colors.expenseRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTransactionDialog(
    BuildContext screenContext,
    WidgetRef ref,
    SavingsGoalEntity goal,
    String type,
  ) {
    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SavingsTxDialogContent(
          goal: goal,
          type: type,
          screenContext: screenContext,
        );
      },
    );
  }
}

class _SavingsDetailShimmer extends StatelessWidget {
  const _SavingsDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardShimmer(height: 220),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: BoxShimmer(height: 52)),
              SizedBox(width: 12),
              Expanded(child: BoxShimmer(height: 52)),
            ],
          ),
          SizedBox(height: 24),
          BoxShimmer(width: 140, height: 16),
          SizedBox(height: 12),
          ListShimmer(itemCount: 3, itemHeight: 70),
        ],
      ),
    );
  }
}
