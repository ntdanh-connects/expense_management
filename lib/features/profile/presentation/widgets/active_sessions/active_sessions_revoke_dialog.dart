import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/profile/data/models/user_session_dto.dart';
import 'package:expense_management/features/profile/presentation/providers/active_sessions_provider.dart';

class ActiveSessionsRevokeDialog extends ConsumerWidget {
  final UserSessionDto? session;
  final bool revokeAll;

  const ActiveSessionsRevokeDialog({
    super.key,
    this.session,
    this.revokeAll = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    if (revokeAll) {
      return AlertDialog(
        backgroundColor: colors.authCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'revoke_all_sessions_confirm_title'.tr(ref),
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'revoke_all_sessions_confirm_desc'.tr(ref),
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(ref),
              style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('revoking_all_progress'.tr(ref)),
                  duration: const Duration(days: 1),
                ),
              );

              try {
                await ref.read(activeSessionsProvider.notifier).revokeAllSessions();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ref.read(authNotifierProvider.notifier).logout();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: colors.expenseRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.expenseRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'confirm'.tr(ref),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    final currentSession = session!;
    return AlertDialog(
      backgroundColor: colors.authCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'revoke_session_confirm_title'.tr(ref),
        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'revoke_session_confirm_desc'.tr(ref).replaceAll('{name}', currentSession.deviceName),
        style: TextStyle(color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'cancel'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('revoking_session_progress'.tr(ref)),
                duration: const Duration(seconds: 1),
              ),
            );

            try {
              if (currentSession.isCurrent) {
                await ref.read(activeSessionsProvider.notifier).revokeSession(currentSession.id, silent: true);
                if (context.mounted) {
                  ref.read(authNotifierProvider.notifier).logout();
                }
              } else {
                await ref.read(activeSessionsProvider.notifier).revokeSession(currentSession.id, silent: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('revoke_session_success'.tr(ref)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: colors.expenseRed,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.expenseRed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'confirm'.tr(ref),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
