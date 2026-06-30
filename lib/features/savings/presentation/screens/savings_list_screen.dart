import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/savings/presentation/provider/savings_notifier.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/shared/widgets/shimmer_components.dart';
import 'package:expense_management/shared/widgets/empty_state_widget.dart';
import 'package:expense_management/shared/widgets/error_state_widget.dart';

import '../widgets/savings_goal_card.dart';

class SavingsListScreen extends ConsumerWidget {
  const SavingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final savingsState = ref.watch(savingsListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'savings_wallet_title'.tr(ref),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(savingsListProvider.notifier).loadGoals(silent: true, force: true);
        },
        child: savingsState.when(
          data: (goals) {
            if (goals.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.savings_rounded,
                title: 'savings_empty_title'.tr(ref),
                description: 'savings_empty_desc'.tr(ref),
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16.0),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return SavingsGoalCard(goal: goal);
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: ListShimmer(itemCount: 3, itemHeight: 180),
          ),
          error: (err, _) => ErrorStateWidget(
            errorMessage: 'savings_load_error'.tr(ref).replaceAll('{error}', err.toString()),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => context.push('/savings/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded),
                const SizedBox(width: 8),
                Text(
                  'savings_create_new_goal'.tr(ref),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
