import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/reporting_export/presentation/providers/reporting_export_providers.dart';
import 'package:elegant_notification/elegant_notification.dart';

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

  void _selectDateRange() async {
    final colors = context.colors;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 2),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: colors.primary,
                  onPrimary: Colors.white,
                  surface: colors.surface,
                  onSurface: colors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
    });

    final repo = ref.read(reportingExportRepositoryProvider);

    try {
      if (_selectedReportType == 'pdf') {
        // Local PDF report generation
        final title = 'Báo cáo thu chi';
        final file = await repo.generateLocalPdfReport(
          title: title,
          dateRange: _selectedDateRange,
          walletId: _selectedWalletId,
          categoryId: _selectedCategoryId,
          transactionType: _selectedTransactionType,
        );

        if (mounted) {
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
        // Trigger Server CSV Export
        final startStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange.start);
        final endStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange.end);

        await repo.triggerRemoteExport(
          startDate: startStr,
          endDate: endStr,
          walletId: _selectedWalletId,
          categoryId: _selectedCategoryId,
          transactionType: _selectedTransactionType,
        );

        if (mounted) {
          ElegantNotification.success(
            title: Text('success'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
            description: const Text('Yêu cầu xuất CSV đã được gửi lên hệ thống và đang được xử lý.'),
          ).show(context);
          
          ref.invalidate(exportHistoryListProvider);
        }
      }
    } catch (e) {
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
        title: Text('Báo cáo & Xuất dữ liệu', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          '• Báo cáo PDF: xuất bảng thu chi kèm biểu đồ phân bổ phần trăm trực quan trên điện thoại.\n• Xuất CSV/Excel: gửi yêu cầu tải dữ liệu dạng bảng về toàn bộ giao dịch tương ứng với bộ lọc của bạn.',
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
            title: const Text('Đang tải xuống tệp', style: TextStyle(fontWeight: FontWeight.bold)),
            description: const Text('Tệp CSV đang được tải xuống từ máy chủ...'),
            toastDuration: const Duration(seconds: 2),
          ).show(context);
        }

        final dio = ref.read(dioClientProvider);
        final tempDir = await getTemporaryDirectory();
        final savePath = '${tempDir.path}/${item.name}';
        
        await dio.download(item.pathOrUrl, savePath);

        // Open local downloaded file
        await OpenFile.open(savePath);
      } catch (e) {
        if (mounted) {
          ElegantNotification.error(
            title: const Text('Lỗi tải xuống', style: TextStyle(fontWeight: FontWeight.bold)),
            description: Text('Không thể tải xuống tệp CSV: $e'),
          ).show(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final walletsAsync = ref.watch(walletNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final historyAsync = ref.watch(exportHistoryListProvider);

    final dateFormat = DateFormat('dd/MM/yyyy');
    final rangeText = '${dateFormat.format(_selectedDateRange.start)} - ${dateFormat.format(_selectedDateRange.end)}';

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
            Text(
              'report_type'.tr(ref),
              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    id: 'pdf',
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'pdf_report'.tr(ref),
                    subtitle: 'pdf_report_desc'.tr(ref),
                    color: colors.incomeGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    id: 'csv',
                    icon: Icons.table_chart_outlined,
                    title: 'csv_excel'.tr(ref),
                    subtitle: 'csv_excel_desc'.tr(ref),
                    color: colors.profileInfo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ⚙️ 2. FILTER BOX
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colors.textSecondary.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list_rounded, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'data_filter'.tr(ref),
                        style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colors.textSecondary.withOpacity(0.08), height: 1),
                  const SizedBox(height: 16),

                  // Calendar Date Range Picker
                  Text(
                    'time_range'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: colors.textSecondary, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                rangeText,
                                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Categories Filter Chips
                  Text(
                    'category_label'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    data: (categories) {
                      final parents = categories.where((c) => c.parentId == null).toList();
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildChoiceChip(
                              isSelected: _selectedCategoryId == null,
                              label: 'all_categories'.tr(ref),
                              onSelected: (_) => setState(() => _selectedCategoryId = null),
                            ),
                            ...parents.map((c) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: _buildChoiceChip(
                                  isSelected: _selectedCategoryId == c.id,
                                  label: c.name,
                                  onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 16),

                  // Wallets Filter Chips
                  Text(
                    'wallet_label'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  walletsAsync.when(
                    data: (wallets) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildChoiceChip(
                              isSelected: _selectedWalletId == null,
                              label: 'all_wallets'.tr(ref),
                              onSelected: (_) => setState(() => _selectedWalletId = null),
                            ),
                            ...wallets.map((w) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: _buildChoiceChip(
                                  isSelected: _selectedWalletId == w.id,
                                  label: w.name,
                                  onSelected: (_) => setState(() => _selectedWalletId = w.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 16),

                  // Transaction Types Filter Chips
                  Text(
                    'transaction_type_label'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceChip(
                          isSelected: _selectedTransactionType == null,
                          label: 'all_types'.tr(ref),
                          onSelected: (_) => setState(() => _selectedTransactionType = null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoiceChip(
                          isSelected: _selectedTransactionType == 'income',
                          label: 'income_type'.tr(ref),
                          onSelected: (_) => setState(() => _selectedTransactionType = 'income'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoiceChip(
                          isSelected: _selectedTransactionType == 'expense',
                          label: 'expense_type'.tr(ref),
                          onSelected: (_) => setState(() => _selectedTransactionType = 'expense'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📜 3. RECENT FILE LOGS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'export_history_title'.tr(ref),
                  style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(exportHistoryListProvider.notifier).clearAllLocalHistory();
                  },
                  child: Text(
                    'clear_all'.tr(ref),
                    style: TextStyle(color: colors.expenseRed, fontSize: 12, fontWeight: FontWeight.bold),
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
                      child: Text('Chưa xuất file nào gần đây.', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    ),
                  );
                }

                // Show top 2 items
                final recent = list.take(2).toList();
                return Column(
                  children: [
                    ...recent.map((item) => _buildHistoryItem(item)),
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
                              'Xem toàn bộ lịch sử',
                              style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, color: colors.primary, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
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

  Widget _buildTypeCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedReportType == id;
    final colors = context.colors;

    return GestureDetector(
      onTap: () => setState(() => _selectedReportType = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.incomeGreen : colors.textSecondary.withOpacity(0.08),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colors.incomeGreen.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required bool isSelected,
    required String label,
    required void Function(bool) onSelected,
  }) {
    final colors = context.colors;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: colors.incomeGreen.withOpacity(0.08),
      backgroundColor: colors.background,
      labelStyle: TextStyle(
        color: isSelected ? colors.incomeGreen : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? colors.incomeGreen : colors.textSecondary.withOpacity(0.1),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildHistoryItem(ExportHistoryItem item) {
    final colors = context.colors;
    final fileIcon = item.isLocal ? Icons.picture_as_pdf : Icons.analytics_outlined;
    final iconColor = item.isLocal ? colors.expenseRed : colors.profileInfo;

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
                    style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.status == 'pending'
                        ? 'Đang xử lý...'
                        : '${DateFormat('dd/MM/yyyy, HH:mm').format(item.date)} • ${item.sizeInMb.toStringAsFixed(1)} MB',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.download_rounded, color: colors.textSecondary, size: 20),
                  onPressed: () => _openOrDownloadItem(item),
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined, color: colors.textSecondary, size: 18),
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
