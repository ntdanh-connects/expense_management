import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/reporting_export/presentation/providers/reporting_export_providers.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';

import '../widgets/export/export_type_selector.dart';
import '../widgets/export/export_filter_section.dart';
import '../widgets/export/export_recent_history_section.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  // Screen States
  String _selectedReportType = 'pdf'; // 'pdf' or 'csv'
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59),
  );

  String? _selectedCategoryId; // null = "Tất cả"
  String? _selectedWalletId;   // null = "Tất cả"
  String? _selectedTransactionType; // null = "Tất cả", 'income', 'expense'

  bool _isExporting = false;

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
    });

    final repo = ref.read(reportingExportRepositoryProvider);
    final userCurrency = ref.read(currentUserProvider)?.currency ?? 'VND';
    final ratesData = ref.read(exchangeRatesProvider).value;

    try {
      if (_selectedReportType == 'pdf') {
        // Local PDF report generation
        final title = 'pdf_report_title'.tr(ref);
        final file = await repo.generateLocalPdfReport(
          title: title,
          dateRange: _selectedDateRange,
          walletId: _selectedWalletId,
          categoryId: _selectedCategoryId,
          transactionType: _selectedTransactionType,
          userCurrency: userCurrency,
          ratesData: ratesData,
          translations: ref.read(translationsProvider),
        );

        if (mounted) {
          final title = 'Xuất dữ liệu thành công';
          final body = 'Báo cáo PDF "${file.path.split('/').last.split('\\').last}" đã được xuất thành công.';

          final pref = ref.read(notificationPreferencesProvider).value;
          final pushEnabled = pref?.pushEnabled ?? true;

          if (pushEnabled) {
            LocalNotificationService.showNotification(
              id: file.path.hashCode,
              title: title,
              body: body,
            );

            final userId = ref.read(currentUserProvider)?.id ?? '';
            if (userId.isNotEmpty) {
              LocalNotificationStorage.createAndSave(
                userId: userId,
                type: 'export_completed',
                title: title,
                body: body,
              ).then((localNotif) {
                if (localNotif != null) {
                  ref.read(notificationNotifierProvider.notifier).addLocalNotification(localNotif);
                }
              });
            }
          }

          ElegantNotification.success(
            title: Text('success'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
            description: Text('export_success'.tr(ref)),
          ).show(context);
          
          // Invalidate history to reload unified list
          ref.invalidate(exportHistoryListProvider);
          
          // Open PDF file immediately
          await OpenFile.open(file.path);
        }
      } else {
        final isRaw = _selectedReportType == 'raw_csv';
        // Local CSV report generation
        final file = await repo.generateLocalCsvReport(
          dateRange: _selectedDateRange,
          walletId: _selectedWalletId,
          categoryId: _selectedCategoryId,
          transactionType: _selectedTransactionType,
          isRaw: isRaw,
        );

        if (mounted) {
          final title = 'Xuất dữ liệu thành công';
          final body = isRaw
              ? 'Tệp CSV thô "${file.path.split('/').last.split('\\').last}" đã được xuất thành công.'
              : 'Báo cáo CSV "${file.path.split('/').last.split('\\').last}" đã được xuất thành công.';

          final pref = ref.read(notificationPreferencesProvider).value;
          final pushEnabled = pref?.pushEnabled ?? true;

          if (pushEnabled) {
            LocalNotificationService.showNotification(
              id: file.path.hashCode,
              title: title,
              body: body,
            );

            final userId = ref.read(currentUserProvider)?.id ?? '';
            if (userId.isNotEmpty) {
              LocalNotificationStorage.createAndSave(
                userId: userId,
                type: 'export_completed',
                title: title,
                body: body,
              ).then((localNotif) {
                if (localNotif != null) {
                  ref.read(notificationNotifierProvider.notifier).addLocalNotification(localNotif);
                }
              });
            }
          }

          ElegantNotification.success(
            title: Text('success'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
            description: Text('export_success'.tr(ref)),
          ).show(context);
          
          // Invalidate history to reload unified list
          ref.invalidate(exportHistoryListProvider);
          
          // Open CSV file immediately
          await OpenFile.open(file.path);
        }
      }
    } catch (e, stack) {
      AppLogger.error(
        'Lỗi khi gửi yêu cầu xuất file',
        tag: 'Export',
        details: e.toString(),
        stackTrace: stack,
      );
      if (mounted) {
        ElegantNotification.error(
          title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: Text('${'export_error'.tr(ref)}$e'),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showInfoDialog() {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('export_info_title'.tr(ref), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'export_info_desc'.tr(ref),
          style: TextStyle(color: colors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr(ref), style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _openOrDownloadItem(ExportHistoryItem item) async {
    if (item.isLocal) {
      await OpenFile.open(item.pathOrUrl);
    } else if (item.status == 'completed' && item.pathOrUrl.isNotEmpty) {
      try {
        if (mounted) {
          ElegantNotification.info(
            title: Text('downloading_file'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
            description: Text('downloading_csv_desc'.tr(ref)),
            toastDuration: const Duration(seconds: 2),
          ).show(context);
        }

        final repo = ref.read(reportingExportRepositoryProvider);
        final tempDir = await getTemporaryDirectory();
        final savePath = '${tempDir.path}/${item.name}';
        
        await repo.downloadFile(item.pathOrUrl, savePath);

        // Open local downloaded file
        await OpenFile.open(savePath);
      } catch (e) {
        if (mounted) {
          ElegantNotification.error(
            title: Text('download_error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
            description: Text('${'download_csv_error'.tr(ref)}$e'),
          ).show(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'export_title'.tr(ref),
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: colors.textPrimary),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📑 1. REPORT TYPE CARD SELECTORS
            ExportTypeSelector(
              selectedType: _selectedReportType,
              onTypeChanged: (type) => setState(() => _selectedReportType = type),
            ),
            const SizedBox(height: 24),

            // ⚙️ 2. FILTER BOX
            ExportFilterSection(
              selectedDateRange: _selectedDateRange,
              selectedCategoryId: _selectedCategoryId,
              selectedWalletId: _selectedWalletId,
              selectedTransactionType: _selectedTransactionType,
              onDateRangeChanged: (range) => setState(() => _selectedDateRange = range),
              onCategoryChanged: (catId) => setState(() => _selectedCategoryId = catId),
              onWalletChanged: (walletId) => setState(() => _selectedWalletId = walletId),
              onTransactionTypeChanged: (type) => setState(() => _selectedTransactionType = type),
            ),
            const SizedBox(height: 24),

            // 📜 3. RECENT FILE LOGS
            ExportRecentHistorySection(
              onOpenOrDownloadItem: _openOrDownloadItem,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: colors.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _handleExport,
                icon: _isExporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.file_upload_outlined, color: Colors.white),
                label: Text(
                  _isExporting ? 'exporting_msg'.tr(ref) : 'export_data_btn'.tr(ref),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.incomeGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'export_save_desc'.tr(ref),
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
