import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/user_session_dto.dart';
import 'active_sessions_revoke_dialog.dart';

class ActiveSessionsListItem extends ConsumerWidget {
  final UserSessionDto session;

  const ActiveSessionsListItem({
    super.key,
    required this.session,
  });

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'android':
        return Icons.android_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'web':
        return Icons.language_rounded;
      case 'desktop':
        return Icons.laptop_mac_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final parsed = DateTime.parse(dateTimeStr).toLocal();
      return "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')} - ${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
    } catch (_) {
      return dateTimeStr;
    }
  }

  void _showRevokeConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => ActiveSessionsRevokeDialog(session: session),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.isCurrent
              ? colors.primary.withOpacity(0.3)
              : colors.textSecondary.withOpacity(0.08),
          width: session.isCurrent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (session.isCurrent ? colors.primary : colors.textSecondary).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getDeviceIcon(session.deviceType),
                color: session.isCurrent ? colors.primary : colors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.deviceName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (session.isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'current_device'.tr(ref),
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ip_address_label'.tr(ref).replaceAll('{ip}', session.ipAddress),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'last_active'.tr(ref).replaceAll('{time}', _formatDateTime(session.createdAt)),
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: colors.expenseRed.withOpacity(0.8),
                size: 20,
              ),
              onPressed: () => _showRevokeConfirmDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
