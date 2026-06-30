import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/reporting_export/presentation/providers/reporting_export_providers.dart';
import '../shared/export_shimmer.dart';

class ExportRecentHistorySection extends ConsumerWidget {
  final ValueChanged<ExportHistoryItem> onOpenOrDownloadItem;

  const ExportRecentHistorySection({
    super.key,
    required this.onOpenOrDownloadItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final historyAsync = ref.watch(exportHistoryListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'export_history_title'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(exportHistoryListProvider.notifier)
                    .clearAllLocalHistory();
              },
              child: Text(
                'clear_all'.tr(ref),
                style: TextStyle(
                  color: colors.expenseRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        historyAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'no_recent_exports'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
              );
            }

            // Show top 2 items
            final recent = list.take(2).toList();
            return Column(
              children: [
                ...recent.map((item) => _buildHistoryItem(context, ref, item)),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.push(RoutePaths.exportHistory);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'view_all_history'.tr(ref),
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: colors.primary, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const ExportHistoryShimmer(
            itemCount: 2,
            isCompact: true,
          ),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(
      BuildContext context, WidgetRef ref, ExportHistoryItem item) {
    final colors = context.colors;
    final isCsv =
        item.name.endsWith('.csv') || item.pathOrUrl.endsWith('.csv');
    final fileIcon = isCsv
        ? Icons.table_chart_outlined
        : (item.isLocal ? Icons.picture_as_pdf : Icons.analytics_outlined);
    final iconColor = isCsv
        ? colors.profileInfo
        : (item.isLocal ? colors.expenseRed : colors.profileInfo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(fileIcon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.status == 'pending'
                        ? 'processing'.tr(ref)
                        : '${DateFormat('dd/MM/yyyy, HH:mm').format(item.date)} • ${item.sizeInMb.toStringAsFixed(1)} MB',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.download_rounded,
                      color: colors.textSecondary, size: 20),
                  onPressed: () => onOpenOrDownloadItem(item),
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined,
                      color: colors.textSecondary, size: 18),
                  onPressed: () async {
                    if (item.isLocal && item.pathOrUrl.isNotEmpty) {
                      await Share.shareXFiles([XFile(item.pathOrUrl)]);
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
