import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'profile_menu_item.dart';

class ProfileSupportSection extends ConsumerWidget {
  final VoidCallback onLogout;

  const ProfileSupportSection({super.key, required this.onLogout});

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colors.authCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.expenseRed, size: 28),
              const SizedBox(width: 10),
              Text(
                'delete_account_q'.tr(ref),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'delete_account_desc'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr(ref), style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        Text('deleting_account_progress'.tr(ref)),
                      ],
                    ),
                    duration: const Duration(days: 1),
                  ),
                );

                try {
                  await ref.read(userRepositoryProvider).deleteAccount();
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('delete_account_success'.tr(ref)),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  onLogout();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${'error'.tr(ref)}: ${e.toString().replaceFirst('Exception: ', '')}'),
                      backgroundColor: colors.expenseRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.expenseRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('confirm_delete'.tr(ref), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'support'.tr(ref).toUpperCase(),
          style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.authCardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ProfileMenuItem(
                icon: Icons.help_outline_rounded,
                iconColor: colors.profileHelp,
                title: 'help_support'.tr(ref),
                onTap: () {},
              ),
              Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
              ProfileMenuItem(
                icon: Icons.delete_outline_rounded,
                iconColor: colors.expenseRed,
                title: 'delete_account'.tr(ref),
                onTap: () => _showDeleteAccountDialog(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
