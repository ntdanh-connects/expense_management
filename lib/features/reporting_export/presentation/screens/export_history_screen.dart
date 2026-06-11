import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:expense_management/features/reporting_export/presentation/providers/reporting_export_providers.dart';

class ExportHistoryScreen extends ConsumerStatefulWidget {
  const ExportHistoryScreen({super.key});

  @override
  ConsumerState<ExportHistoryScreen> createState() => _ExportHistoryScreenState();
}

class _ExportHistoryScreenState extends ConsumerState<ExportHistoryScreen> {
  int _activeTabIndex = 0; // 0 = "Tất cả", 1 = "PDF", 2 = "Excel"
  String _searchQuery = '';
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final historyAsync = ref.watch(exportHistoryListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                style: TextStyle(color: colors.textPrimary),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm báo cáo...',
                  hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.6)),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Text(
                'history_export_title'.tr(ref),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search, color: colors.textPrimary),
            onPressed: () {
              setState(() {
                if (_isSearchVisible) {
                  _searchQuery = '';
                  _searchController.clear();
                }
                _isSearchVisible = !_isSearchVisible;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: colors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: historyAsync.when(
        data: (list) {
          // Filter items based on active tab
          var filteredList = list.where((item) {
            if (_activeTabIndex == 1 && !item.isLocal) return false;
            if (_activeTabIndex == 2 && item.isLocal) return false;
            return true;
          }).toList();

          // Filter by search query
          if (_searchQuery.isNotEmpty) {
            filteredList = filteredList
                .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }

          final pdfCount = list.where((item) => item.isLocal).length;
          final csvCount = list.where((item) => !item.isLocal).length;
          final totalCount = list.length;

          return Column(
            children: [
              // 📊 TAB CONTROLS (Tất cả, PDF, Excel)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: Row(
                  children: [
                    _buildTabChip(0, 'Tất cả ($totalCount)'),
                    const SizedBox(width: 8),
                    _buildTabChip(1, 'PDF ($pdfCount)'),
                    const SizedBox(width: 8),
                    _buildTabChip(2, 'Excel ($csvCount)'),
                  ],
                ),
              ),

              // 📋 LIST OF LOG CARDS
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy báo cáo nào.',
                          style: TextStyle(color: colors.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return _buildHistoryCard(item);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Có lỗi xảy ra khi tải lịch sử: $err',
              style: TextStyle(color: colors.expenseRed, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String label) {
    final colors = context.colors;
    final isActive = _activeTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.incomeGreen : colors.textSecondary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : colors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ExportHistoryItem item) {
    final colors = context.colors;
    final fileIcon = item.isLocal ? Icons.picture_as_pdf : Icons.analytics_outlined;
    final iconColor = item.isLocal ? colors.expenseRed : colors.profileInfo;

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
                        style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Meta stats row (Calendar, Clock, size)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 12, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(item.date),
                              style: TextStyle(color: colors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 12, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat.format(item.date),
                              style: TextStyle(color: colors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.sd_storage_outlined, size: 12, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${item.sizeInMb.toStringAsFixed(1)} MB',
                              style: TextStyle(color: colors.textSecondary, fontSize: 11),
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
                          : () => _openOrDownloadItem(item),
                      icon: Icon(
                        item.isLocal ? Icons.open_in_new_rounded : Icons.download_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        item.isLocal ? 'Mở file' : 'Tải lại',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.incomeGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        side: BorderSide(color: colors.textSecondary.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(Icons.share_outlined, color: colors.textSecondary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Delete button
                SizedBox(
                  height: 40,
                  width: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      _showDeleteConfirmDialog(item);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.expenseRed.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: colors.expenseRed.withOpacity(0.03),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: colors.expenseRed, size: 18),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(ExportHistoryItem item) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Xóa lịch sử báo cáo', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          item.isLocal
              ? 'Bạn có chắc muốn xóa tệp báo cáo PDF này khỏi bộ nhớ thiết bị?'
              : 'Xác nhận xóa bản ghi lịch sử xuất này?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(exportHistoryListProvider.notifier).deleteItem(item);
            },
            child: Text('Xóa', style: TextStyle(color: colors.expenseRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
