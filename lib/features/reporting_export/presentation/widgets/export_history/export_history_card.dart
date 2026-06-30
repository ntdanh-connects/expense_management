import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/reporting_export/presentation/providers/reporting_export_providers.dart';

class ExportHistoryCard extends ConsumerWidget {
  final ExportHistoryItem item;
  final ValueChanged<ExportHistoryItem> onOpenOrDownloadItem;

  const ExportHistoryCard({
    super.key,
    required this.item,
    required this.onOpenOrDownloadItem,
  });

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isCsv = item.name.endsWith('.csv') || item.pathOrUrl.endsWith('.csv');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'delete_history_title'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isCsv
              ? 'delete_csv_confirm'.tr(ref)
              : (item.isLocal
                  ? 'delete_pdf_confirm'.tr(ref)
                  : 'delete_csv_confirm'.tr(ref)),
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(ref),
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(exportHistoryListProvider.notifier)
                  .deleteItem(item);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isCsv = item.name.endsWith('.csv') || item.pathOrUrl.endsWith('.csv');
    final fileIcon = isCsv
        ? Icons.table_chart_outlined
        : (item.isLocal ? Icons.picture_as_pdf : Icons.analytics_outlined);
    final iconColor = isCsv
        ? colors.profileInfo
        : (item.isLocal ? colors.expenseRed : colors.profileInfo);

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      color: colors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.textSecondary.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon wrapper
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(fileIcon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Meta stats row (Calendar, Clock, size)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(item.date),
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time,
                                size: 12, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat.format(item.date),
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.sd_storage_outlined,
                                size: 12, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${item.sizeInMb.toStringAsFixed(1)} MB',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 14),

            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: item.status == 'pending'
                          ? null
                          : () => onOpenOrDownloadItem(item),
                      icon: Icon(
                        item.isLocal
                            ? Icons.open_in_new_rounded
                            : Icons.download_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        item.isLocal ? 'open_file'.tr(ref) : 're_download'.tr(ref),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.incomeGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (item.isLocal && item.pathOrUrl.isNotEmpty) ...[
                  SizedBox(
                    height: 40,
                    width: 48,
                    child: OutlinedButton(
                      onPressed: () async {
                        await Share.shareXFiles([XFile(item.pathOrUrl)]);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: colors.textSecondary.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(Icons.share_outlined,
                          color: colors.textSecondary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Delete button
                SizedBox(
                  height: 40,
                  width: 48,
                  child: OutlinedButton(
                    onPressed: () => _showDeleteConfirmDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: colors.expenseRed.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: colors.expenseRed.withOpacity(0.03),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: colors.expenseRed, size: 18),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
