import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/providers/active_sessions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/active_sessions/active_sessions_shimmer.dart';
import '../widgets/active_sessions/active_sessions_list_item.dart';
import '../widgets/active_sessions/active_sessions_revoke_dialog.dart';

class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  void _showRevokeAllConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const ActiveSessionsRevokeDialog(revokeAll: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final sessionsState = ref.watch(activeSessionsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'active_sessions_title'.tr(ref),
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(activeSessionsProvider.notifier).refreshSessions(silent: true),
          ),
        ],
      ),
      body: sessionsState.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                'no_data'.tr(ref),
                style: TextStyle(color: colors.textSecondary),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ActiveSessionsListItem(session: session);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRevokeAllConfirmDialog(context),
                    icon: const Icon(Icons.no_cell_rounded, color: Colors.white),
                    label: Text(
                      'revoke_all_devices'.tr(ref),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.expenseRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const ActiveSessionsShimmer(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.expenseRed, size: 48),
              const SizedBox(height: 16),
              Text(
                'error_occurred'.tr(ref),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(activeSessionsProvider.notifier).refreshSessions(),
                child: Text('try_again'.tr(ref)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
