import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_card.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/shared/widgets/transaction_list_shimmer.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_history/transaction_day_section.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_history/transaction_history_empty_state.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_history/transaction_filter_chip_button.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_history/transaction_history_type_chip.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_history/transaction_history_sort_sheet.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_history/transaction_history_amount_range_dialog.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_history/transaction_history_wallet_picker_sheet.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_history/transaction_history_category_picker_sheet.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  /// Nếu 'recent' → chỉ hiện 5 giao dịch mới nhất (từ dashboard)
  final String? initialFilter;

  const TransactionHistoryScreen({super.key, this.initialFilter});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  // Tên hiển thị tạm trên chip (vì filter lưu ID)
  String? _selectedCategoryName;
  String? _selectedWalletName;
  bool _showRecentOnly = false; // 5 giao dịch gần nhất

  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final currentSearch = ref.read(transactionFilterProvider).search ?? '';
    _searchController = TextEditingController(text: currentSearch);
    if (widget.initialFilter == 'recent') {
      _showRecentOnly = true;
    }
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_showRecentOnly) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const threshold = 200.0;
    if (maxScroll - currentScroll <= threshold) {
      ref.read(filteredTransactionListProvider.notifier).loadMoreTransactions();
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(transactionFilterProvider.notifier).update((state) => state.copyWith(search: val));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool get _hasActiveFilters {
    final filter = ref.read(transactionFilterProvider);
    return !filter.isEmpty || _showRecentOnly;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryName = null;
      _selectedWalletName = null;
      _showRecentOnly = false;
    });
    _searchController.clear();
    ref.read(transactionFilterProvider.notifier).state = TransactionFilter();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final transactionState = ref.watch(filteredTransactionListProvider);
    final userCurrency = ref.watch(currentUserProvider.select((u) => u?.currency)) ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    final ratesData = ref.watch(exchangeRatesProvider).value;
    
    return Scaffold(
      backgroundColor: colors.background,
      appBar: SharedTopAppBar(
        hintText: 'search_transactions_hint'.tr(ref),
        onSearchChanged: _onSearchChanged,
        searchController: _searchController,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. TIÊU ĐỀ & NÚT XOÁ LỌC/EXPORT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'history'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_showRecentOnly)
                      Text(
                        'five_recent_transactions'.tr(ref),
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (_hasActiveFilters)
                      GestureDetector(
                        onTap: _clearAllFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.expenseRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_alt_off_rounded,
                                  color: colors.expenseRed, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'clear_filters'.tr(ref),
                                style: TextStyle(
                                  color: colors.expenseRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.file_download_outlined,
                          color: colors.primary, size: 26),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. BỘ LỌC LOẠI GIAO DỊCH
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  TransactionHistoryTypeChip(label: 'all'.tr(ref), value: 'All'),
                  const SizedBox(width: 8),
                  TransactionHistoryTypeChip(label: 'expense'.tr(ref), value: 'Expense'),
                  const SizedBox(width: 8),
                  TransactionHistoryTypeChip(label: 'income'.tr(ref), value: 'Income'),
                  const SizedBox(width: 8),
                  TransactionHistoryTypeChip(label: 'transfer'.tr(ref), value: 'Transfer'),
                ],
              ),
            ),
          ),

          // ── 3. BỘ LỌC NÂNG CAO: Danh mục | Ví | Ngày | Gần nhất
          _buildAdvancedFilterRow(colors),

          const SizedBox(height: 6),

          Expanded(
            child: RefreshIndicator(
              color: colors.primary,
              onRefresh: () async {
                await ref
                    .read(filteredTransactionListProvider.notifier)
                    .refreshTransactions(silent: false);
                await ref
                    .read(categoriesNotifierProvider.notifier)
                    .refreshCategories(silent: true);
              },
              child: transactionState.when(
                data: (txList) {
                  final filtered = _applyFilters(txList);
                  final pagination = ref.watch(transactionPaginationProvider);

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                        TransactionHistoryEmptyState(
                          hasMore: pagination.hasMore,
                          isLoadingMore: pagination.isLoadingMore,
                          showRecentOnly: _showRecentOnly,
                          onLoadMore: () {
                            ref.read(filteredTransactionListProvider.notifier).loadMoreTransactions();
                          },
                        ),
                      ],
                    );
                  }

                  // Nhóm theo ngày
                  final grouped = _groupByDate(filtered);

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: grouped.length + (pagination.hasMore && !_showRecentOnly ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == grouped.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                              ),
                            ),
                          ),
                        );
                      }
                      return TransactionDaySection(
                        group: grouped[index],
                        userCurrency: userCurrency,
                        currencySymbol: currencySymbol,
                        ratesData: ratesData,
                      );
                    },
                  );
                },
                loading: () => const TransactionListShimmer(
                  itemCount: 8,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                error: (err, _) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'load_transactions_error'.tr(ref),
                            style: TextStyle(color: colors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref
                                .read(filteredTransactionListProvider.notifier)
                                .refreshTransactions(),
                            child: Text('try_again'.tr(ref)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilterRow(AppColorsExtension colors) {
    final filter = ref.watch(transactionFilterProvider);
    
    // Resolve dynamic category label
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    String categoryLabel = 'category'.tr(ref);
    if (filter.categoryId != null) {
      if (filter.categoryId == 'uncategorized') {
        categoryLabel = 'uncategorized'.tr(ref);
      } else {
        final allCats = categoriesAsync.value ?? [];
        final match = allCats.where((c) => c.id == filter.categoryId).firstOrNull;
        if (match != null) {
          categoryLabel = match.name.tr(ref);
        }
      }
    }

    // Resolve dynamic wallet label
    final walletsAsync = ref.watch(walletNotifierProvider);
    String walletLabel = 'all_wallets'.tr(ref);
    if (filter.walletId != null) {
      final allWallets = walletsAsync.value ?? [];
      final match = allWallets.where((w) => w.id == filter.walletId).firstOrNull;
      if (match != null) {
        walletLabel = match.name;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Lọc danh mục
            TransactionFilterChipButton(
              icon: Icons.category_rounded,
              label: categoryLabel,
              isActive: filter.categoryId != null,
              onTap: () => _showCategoryPicker(colors),
            ),
            const SizedBox(width: 8),

            // Lọc ví
            TransactionFilterChipButton(
              icon: Icons.account_balance_wallet_rounded,
              label: walletLabel,
              isActive: filter.walletId != null,
              onTap: () => _showWalletPicker(colors),
            ),
            const SizedBox(width: 8),

            // Lọc ngày
            TransactionFilterChipButton(
              icon: Icons.calendar_month_rounded,
              label: _buildDateLabel(filter),
              isActive: filter.startDate != null || filter.endDate != null,
              onTap: () => _showDateRangePicker(colors),
            ),
            const SizedBox(width: 8),

            // Lọc khoảng số tiền
            TransactionFilterChipButton(
              icon: Icons.monetization_on_rounded,
              label: _buildAmountLabel(filter),
              isActive: filter.minAmount != null || filter.maxAmount != null,
              onTap: () => _showAmountRangeDialog(colors),
            ),
            const SizedBox(width: 8),

            // Sắp xếp
            TransactionFilterChipButton(
              icon: Icons.sort_rounded,
              label: _buildSortLabel(filter),
              isActive: filter.sortBy != 'date' || filter.sortOrder != 'desc',
              onTap: () => _showSortBottomSheet(colors),
            ),
            const SizedBox(width: 8),

            // Toggle 5 gần nhất
            TransactionFilterChipButton(
              icon: Icons.access_time_rounded,
              label: 'five_recent_transactions'.tr(ref),
              isActive: _showRecentOnly,
              onTap: () => setState(() => _showRecentOnly = !_showRecentOnly),
            ),
          ],
        ),
      ),
    );
  }

  String _buildDateLabel(TransactionFilter filter) {
    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    final location = tz.getLocation(tzName);

    DateTime? startDate;
    if (filter.startDate != null) {
      final parsed = DateTime.parse(filter.startDate!);
      startDate = parsed.isUtc 
          ? tz.TZDateTime.from(parsed, location) 
          : tz.TZDateTime(location, parsed.year, parsed.month, parsed.day);
    }

    DateTime? endDate;
    if (filter.endDate != null) {
      final parsed = DateTime.parse(filter.endDate!);
      endDate = parsed.isUtc 
          ? tz.TZDateTime.from(parsed, location) 
          : tz.TZDateTime(location, parsed.year, parsed.month, parsed.day);
    }

    if (startDate != null && endDate != null) {
      return '${DateFormat('dd/MM').format(startDate)} – ${DateFormat('dd/MM').format(endDate)}';
    } else if (startDate != null) {
      return 'Từ ${DateFormat('dd/MM').format(startDate)}';
    } else if (endDate != null) {
      return 'Đến ${DateFormat('dd/MM').format(endDate)}';
    }
    return 'this_month'.tr(ref);
  }

  String _buildAmountLabel(TransactionFilter filter) {
    if (filter.minAmount != null && filter.maxAmount != null) {
      return '${_fmtSimple(filter.minAmount!)} – ${_fmtSimple(filter.maxAmount!)}';
    } else if (filter.minAmount != null) {
      return '>= ${_fmtSimple(filter.minAmount!)}';
    } else if (filter.maxAmount != null) {
      return '<= ${_fmtSimple(filter.maxAmount!)}';
    }
    return 'Khoảng số tiền';
  }

  String _fmtSimple(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _buildSortLabel(TransactionFilter filter) {
    String criterion = 'Ngày';
    if (filter.sortBy == 'amount') criterion = 'Số tiền';
    if (filter.sortBy == 'category') criterion = 'Danh mục';

    String direction = filter.sortOrder == 'asc' ? '↑' : '↓';
    return '$criterion $direction';
  }

  void _showAmountRangeDialog(AppColorsExtension colors) {
    showDialog(
      context: context,
      builder: (ctx) => const TransactionHistoryAmountRangeDialog(),
    );
  }

  void _showSortBottomSheet(AppColorsExtension colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const TransactionHistorySortSheet(),
    );
  }



  void _showCategoryPicker(AppColorsExtension colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final categoryState = ref.watch(categoriesNotifierProvider);
            return TransactionHistoryCategoryPickerSheet(
              categoryState: categoryState,
              onClear: () {
                setState(() {
                  _selectedCategoryName = null;
                });
                ref.read(transactionFilterProvider.notifier).update(
                      (state) => state.copyWith(clearCategory: true),
                    );
                Navigator.pop(ctx);
              },
              onSelected: (category) {
                setState(() {
                  _selectedCategoryName = category.name;
                });
                ref.read(transactionFilterProvider.notifier).update(
                      (state) => state.copyWith(categoryId: category.id),
                    );
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  void _showWalletPicker(AppColorsExtension colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final walletState = ref.watch(walletNotifierProvider);
            final filter = ref.watch(transactionFilterProvider);
            return TransactionHistoryWalletPickerSheet(
              walletState: walletState,
              walletId: filter.walletId,
              onClear: () {
                setState(() {
                  _selectedWalletName = null;
                });
                ref.read(transactionFilterProvider.notifier).update(
                      (state) => state.copyWith(clearWallet: true),
                    );
                Navigator.pop(ctx);
              },
              onSelected: (wallet) {
                setState(() {
                  _selectedWalletName = wallet.name;
                });
                ref.read(transactionFilterProvider.notifier).update(
                      (state) => state.copyWith(walletId: wallet.id),
                    );
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  // ── DATE RANGE PICKER
  Future<void> _showDateRangePicker(AppColorsExtension colors) async {
    final filter = ref.read(transactionFilterProvider);
    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    final location = tz.getLocation(tzName);
    final now = tz.TZDateTime.now(location);

    DateTime? filterStart;
    if (filter.startDate != null) {
      final parsed = DateTime.parse(filter.startDate!);
      filterStart = parsed.isUtc 
          ? tz.TZDateTime.from(parsed, location) 
          : tz.TZDateTime(location, parsed.year, parsed.month, parsed.day);
    }

    DateTime? filterEnd;
    if (filter.endDate != null) {
      final parsed = DateTime.parse(filter.endDate!);
      filterEnd = parsed.isUtc 
          ? tz.TZDateTime.from(parsed, location) 
          : tz.TZDateTime(location, parsed.year, parsed.month, parsed.day);
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (filterStart != null && filterEnd != null)
          ? DateTimeRange(start: filterStart, end: filterEnd)
          : DateTimeRange(
              start: tz.TZDateTime(location, now.year, now.month, 1),
              end: now,
            ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: colors.primary,
            brightness: Theme.of(context).brightness,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _showRecentOnly = false;
      });
      ref.read(transactionFilterProvider.notifier).update(
            (state) => state.copyWith(
              startDate: DateFormat('yyyy-MM-dd').format(picked.start),
              endDate: DateFormat('yyyy-MM-dd').format(picked.end),
            ),
          );
    }
  }

  // ── ÁP DỤNG BỘ LỌC
  List<TransactionEntity> _applyFilters(List<TransactionEntity> txList) {
    final List<TransactionEntity> result = List.from(txList);
    final filter = ref.read(transactionFilterProvider);

    result.sort((a, b) {
      final aPending = a.status == 'pending';
      final bPending = b.status == 'pending';
      if (aPending && !bPending) return -1;
      if (!aPending && bPending) return 1;

      if (filter.sortBy == 'date') {
        if (filter.sortOrder == 'asc') {
          return a.transactionDate.compareTo(b.transactionDate);
        } else {
          return b.transactionDate.compareTo(a.transactionDate);
        }
      }
      
      final indexA = txList.indexOf(a);
      final indexB = txList.indexOf(b);
      return indexA.compareTo(indexB);
    });

    if (_showRecentOnly) return result.take(5).toList();
    return result;
  }

  // ── NHÓM THEO NGÀY
  List<MapEntry<String, List<TransactionEntity>>> _groupByDate(
      List<TransactionEntity> txs) {
    final Map<String, List<TransactionEntity>> groups = {};
    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';

    try {
      final location = tz.getLocation(tzName);
      final userNow = tz.TZDateTime.now(location);
      final today = DateTime(userNow.year, userNow.month, userNow.day);
      final yesterday = today.subtract(const Duration(days: 1));

      for (final tx in txs) {
        final txDateTime = tz.TZDateTime.from(tx.transactionDate.toUtc(), location);
        final txDate = DateTime(
          txDateTime.year,
          txDateTime.month,
          txDateTime.day,
        );
        String key;
        if (txDate == today) {
          key = 'today'.trRead(ref);
        } else if (txDate == yesterday) {
          key = 'yesterday'.trRead(ref);
        } else {
          key = DateFormat('dd/MM/yyyy', 'vi').format(txDate);
        }
        groups.putIfAbsent(key, () => []).add(tx);
      }
    } catch (_) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      for (final tx in txs) {
        final txDate = DateTime(
          tx.transactionDate.year,
          tx.transactionDate.month,
          tx.transactionDate.day,
        );
        String key;
        if (txDate == today) {
          key = 'today'.trRead(ref);
        } else if (txDate == yesterday) {
          key = 'yesterday'.trRead(ref);
        } else {
          key = DateFormat('dd/MM/yyyy', 'vi').format(txDate);
        }
        groups.putIfAbsent(key, () => []).add(tx);
      }
    }
    return groups.entries.toList();
  }

  IconData _getWalletIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'e-wallet':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }
}
