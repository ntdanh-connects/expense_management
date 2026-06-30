import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:expense_management/features/reporting_export/presentation/providers/reporting_export_providers.dart';

import '../widgets/export_history/export_history_card.dart';
import '../widgets/export_history/export_history_tab_bar.dart';
import '../widgets/shared/export_shimmer.dart';

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
                  hintText: 'search_report_hint'.tr(ref),
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
            final isCsvOrExcel = item.name.toLowerCase().endsWith('.csv') || 
                                 item.name.toLowerCase().endsWith('.xlsx');
            if (_activeTabIndex == 1) {
              return !isCsvOrExcel;
            }
            if (_activeTabIndex == 2) {
              return isCsvOrExcel;
            }
            return true;
          }).toList();

          // Filter by search query
          if (_searchQuery.isNotEmpty) {
            filteredList = filteredList
                .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }

          final pdfCount = list.where((item) => !item.name.toLowerCase().endsWith('.csv') && 
                                                !item.name.toLowerCase().endsWith('.xlsx')).length;
          final csvCount = list.where((item) => item.name.toLowerCase().endsWith('.csv') || 
                                                item.name.toLowerCase().endsWith('.xlsx')).length;
          final totalCount = list.length;

          return Column(
            children: [
              // 📊 TAB CONTROLS (Tất cả, PDF, Excel)
              ExportHistoryTabBar(
                activeIndex: _activeTabIndex,
                onTabChanged: (idx) => setState(() => _activeTabIndex = idx),
                totalCount: totalCount,
                pdfCount: pdfCount,
                csvCount: csvCount,
              ),

              // 📋 LIST OF LOG CARDS
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          'no_reports_found'.tr(ref),
                          style: TextStyle(color: colors.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return ExportHistoryCard(
                            item: item,
                            onOpenOrDownloadItem: _openOrDownloadItem,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: SizedBox(height: 38), // placeholder spacing for tabbar while loading
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: ExportHistoryShimmer(itemCount: 4, isCompact: false),
              ),
            ),
          ],
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              '${'load_history_error'.tr(ref)}$err',
              style: TextStyle(color: colors.expenseRed, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
