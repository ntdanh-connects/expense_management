import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_card.dart';

import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/shared/widgets/transaction_list_shimmer.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/user_provider.dart';

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
  String _searchQuery = '';
  String _selectedType = 'All'; // All, Expense, Income, Transfer

  // Bộ lọc nâng cao
  String? _selectedCategoryId; // ID danh mục con đang chọn
  String? _selectedCategoryName; // Tên hiển thị
  String? _selectedWalletId; // ID ví
  String? _selectedWalletName; // Tên ví hiển thị
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showRecentOnly = false; // 5 giao dịch gần nhất

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter == 'recent') {
      _showRecentOnly = true;
    }
  }

  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _selectedWalletId != null ||
      _startDate != null ||
      _endDate != null ||
      _selectedType != 'All' ||
      _showRecentOnly;

  void _clearAllFilters() {
    setState(() {
      _selectedType = 'All';
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedWalletId = null;
      _selectedWalletName = null;
      _startDate = null;
      _endDate = null;
      _showRecentOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final transactionState = ref.watch(transactionListProvider);
    final userCurrency = ref.watch(currentUserProvider)?.currency ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    final ratesData = ref.watch(exchangeRatesProvider).value;
    
    return Scaffold(
      backgroundColor: colors.background,
      appBar: SharedTopAppBar(
        hintText: 'search_transactions_hint'.tr(ref),
        onSearchChanged: (val) {
          setState(() => _searchQuery = val);
        },
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
                  _buildTypeChip('all'.tr(ref), 'All'),
                  const SizedBox(width: 8),
                  _buildTypeChip('expense'.tr(ref), 'Expense'),
                  const SizedBox(width: 8),
                  _buildTypeChip('income'.tr(ref), 'Income'),
                  const SizedBox(width: 8),
                  _buildTypeChip('transfer'.tr(ref), 'Transfer'),
                ],
              ),
            ),
          ),

          // ── 3. BỘ LỌC NÂNG CAO: Danh mục | Ví | Ngày | Gần nhất
          _buildAdvancedFilterRow(colors),

          const SizedBox(height: 6),

          // ── 4. DANH SÁCH GIAO DỊCH
          Expanded(
            child: transactionState.when(
              data: (txList) {
                final filtered = _applyFilters(txList);

                if (filtered.isEmpty) {
                  return _buildEmptyState(colors);
                }

                // Nhóm theo ngày
                final grouped = _groupByDate(filtered);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) =>
                      _buildDaySection(grouped[index], colors,userCurrency,currencySymbol,ratesData),
                );
              },
              loading: () => const TransactionListShimmer(
                itemCount: 8,
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
              error: (err, _) => Center(
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
                          .read(transactionListProvider.notifier)
                          .refreshTransactions(),
                      child: Text('try_again'.tr(ref)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Hàng bộ lọc nâng cao
  Widget _buildAdvancedFilterRow(AppColorsExtension colors) {
    final categoryLabel = _selectedCategoryName != null ? _selectedCategoryName!.tr(ref) : 'category'.tr(ref);
    final walletLabel = _selectedWalletName ?? 'all_wallets'.tr(ref);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Lọc danh mục
            _buildFilterChipButton(
              icon: Icons.category_rounded,
              label: categoryLabel,
              isActive: _selectedCategoryId != null,
              onTap: () => _showCategoryPicker(colors),
              colors: colors,
            ),
            const SizedBox(width: 8),

            // Lọc ví
            _buildFilterChipButton(
              icon: Icons.account_balance_wallet_rounded,
              label: walletLabel,
              isActive: _selectedWalletId != null,
              onTap: () => _showWalletPicker(colors),
              colors: colors,
            ),
            const SizedBox(width: 8),

            // Lọc ngày
            _buildFilterChipButton(
              icon: Icons.calendar_month_rounded,
              label: _buildDateLabel(),
              isActive: _startDate != null || _endDate != null,
              onTap: () => _showDateRangePicker(colors),
              colors: colors,
            ),
            const SizedBox(width: 8),

            // Toggle 5 gần nhất
            _buildFilterChipButton(
              icon: Icons.access_time_rounded,
              label: 'five_recent_transactions'.tr(ref),
              isActive: _showRecentOnly,
              onTap: () => setState(() => _showRecentOnly = !_showRecentOnly),
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }

  String _buildDateLabel() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('dd/MM').format(_startDate!)} – ${DateFormat('dd/MM').format(_endDate!)}';
    } else if (_startDate != null) {
      return 'Từ ${DateFormat('dd/MM').format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Đến ${DateFormat('dd/MM').format(_endDate!)}';
    }
    return 'this_month'.tr(ref);
  }

  Widget _buildFilterChipButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primary.withOpacity(0.12)
              : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? colors.primary.withOpacity(0.5)
                : colors.textSecondary.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? colors.primary : colors.textSecondary,
                size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? colors.primary : colors.textSecondary,
                fontSize: 12.5,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: isActive ? colors.primary : colors.textSecondary,
                size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerShimmer(AppColorsExtension colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 140,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PICKER DANH MỤC (Cha → Con)
  void _showCategoryPicker(AppColorsExtension colors) {
    String? _pickerSelectedParentId;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Consumer(
              builder: (context, ref, child) {
                final categoryState = ref.watch(categoriesNotifierProvider);

                return categoryState.when(
                  data: (allCategories) {
                    final parents = allCategories.where((c) => c.parentId == null).toList();
                    final Map<String, List<CategoryDto>> childMap = {};
                    for (final cat in allCategories) {
                      if (cat.parentId != null) {
                        childMap.putIfAbsent(cat.parentId!, () => []).add(cat);
                      }
                    }

                    final children = _pickerSelectedParentId != null
                        ? (childMap[_pickerSelectedParentId] ?? [])
                        : <CategoryDto>[];

                    return SafeArea(
                      child: DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.6,
                        maxChildSize: 0.9,
                        builder: (_, scrollCtrl) => Column(
                          children: [
                            // Handle
                            const SizedBox(height: 12),
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.textSecondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  if (_pickerSelectedParentId != null)
                                    IconButton(
                                      onPressed: () => setSheetState(
                                          () => _pickerSelectedParentId = null),
                                      icon: Icon(Icons.arrow_back_ios_rounded,
                                          size: 18,
                                          color: colors.textPrimary),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  if (_pickerSelectedParentId != null)
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _pickerSelectedParentId == null
                                          ? 'select_category'.tr(ref)
                                          : (parents
                                                  .firstWhere((p) =>
                                                      p.id ==
                                                      _pickerSelectedParentId)
                                                  .name.tr(ref)),
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_selectedCategoryId != null)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedCategoryId = null;
                                          _selectedCategoryName = null;
                                        });
                                        Navigator.pop(ctx);
                                      },
                                      child: Text('clear'.tr(ref),
                                          style: TextStyle(
                                              color: colors.expenseRed)),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Danh sách
                            Expanded(
                              child: ListView(
                                controller: scrollCtrl,
                                children: [
                                  // "Tất cả" option khi đang ở bước cha
                                  if (_pickerSelectedParentId == null)
                                    ListTile(
                                      leading: Icon(Icons.apps_rounded,
                                          color: _selectedCategoryId == null
                                              ? colors.primary
                                              : colors.textSecondary),
                                      title: Text(
                                        'all_categories'.tr(ref),
                                        style: TextStyle(
                                          color: _selectedCategoryId == null
                                              ? colors.primary
                                              : colors.textPrimary,
                                          fontWeight: _selectedCategoryId == null
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      trailing: _selectedCategoryId == null
                                          ? Icon(Icons.check_circle_rounded,
                                              color: colors.primary, size: 20)
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedCategoryId = null;
                                          _selectedCategoryName = null;
                                        });
                                        Navigator.pop(ctx);
                                      },
                                    ),

                                  // Danh sách cha
                                  if (_pickerSelectedParentId == null)
                                    ...parents.map((parent) {
                                      final hasChildren =
                                          childMap.containsKey(parent.id) &&
                                              childMap[parent.id]!.isNotEmpty;
                                      final icon =
                                          CategoryUIConstants.getIconData(parent.icon, categoryName: parent.name);
                                      final color =
                                          CategoryUIConstants.getColorFromHex(
                                              parent.color, categoryName: parent.name);
                                      return ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child:
                                              Icon(icon, color: color, size: 18),
                                        ),
                                        title: Text(
                                          parent.name.tr(ref),
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing: hasChildren
                                            ? Icon(Icons.chevron_right_rounded,
                                                color: colors.textSecondary)
                                            : null,
                                        onTap: () {
                                          if (hasChildren) {
                                            setSheetState(() =>
                                                _pickerSelectedParentId =
                                                    parent.id);
                                          } else {
                                            setState(() {
                                              _selectedCategoryId = parent.id;
                                              _selectedCategoryName = parent.name;
                                            });
                                            Navigator.pop(ctx);
                                          }
                                        },
                                      );
                                    }),

                                  // Danh sách con
                                  if (_pickerSelectedParentId != null)
                                    ...children.map((child) {
                                      final isSelected =
                                          _selectedCategoryId == child.id;
                                      final icon = CategoryUIConstants.getIconData(
                                          child.icon, categoryName: child.name);
                                      final color =
                                          CategoryUIConstants.getColorFromHex(
                                              child.color, categoryName: child.name);
                                      return ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child:
                                              Icon(icon, color: color, size: 18),
                                        ),
                                        title: Text(
                                          child.name.tr(ref),
                                          style: TextStyle(
                                            color: isSelected
                                                ? colors.primary
                                                : colors.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? Icon(Icons.check_circle_rounded,
                                                color: colors.primary, size: 20)
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedCategoryId = child.id;
                                            _selectedCategoryName = child.name;
                                          });
                                          Navigator.pop(ctx);
                                        },
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.6,
                    maxChildSize: 0.9,
                    builder: (_, scrollCtrl) => SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.textSecondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(child: _buildPickerShimmer(colors)),
                        ],
                      ),
                    ),
                  ),
                  error: (err, _) => Center(child: Text('load_transactions_error'.tr(ref))),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── PICKER VÍ
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

            return walletState.when(
              data: (allWallets) {
                final wallets = allWallets.where((w) => !w.isHidden).toList();

                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'filter_by_wallet'.tr(ref),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedWalletId != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedWalletId = null;
                                    _selectedWalletName = null;
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: Text('clear'.tr(ref),
                                    style: TextStyle(color: colors.expenseRed)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            // Tất cả ví
                            ListTile(
                              leading: Icon(Icons.account_balance_wallet_rounded,
                                  color: _selectedWalletId == null
                                      ? colors.primary
                                      : colors.textSecondary),
                              title: Text(
                                'all_wallets'.tr(ref),
                                style: TextStyle(
                                  color: _selectedWalletId == null
                                      ? colors.primary
                                      : colors.textPrimary,
                                  fontWeight: _selectedWalletId == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: _selectedWalletId == null
                                  ? Icon(Icons.check_circle_rounded,
                                      color: colors.primary, size: 20)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedWalletId = null;
                                  _selectedWalletName = null;
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                            ...wallets.map((w) {
                              final isSelected = _selectedWalletId == w.id;
                              return ListTile(
                                leading: Icon(
                                  _getWalletIcon(w.type),
                                  color: isSelected
                                      ? colors.primary
                                      : colors.textSecondary,
                                ),
                                title: Text(
                                  w.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle_rounded,
                                        color: colors.primary, size: 20)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedWalletId = w.id;
                                    _selectedWalletName = w.name;
                                  });
                                  Navigator.pop(ctx);
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
              loading: () => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPickerShimmer(colors),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              error: (err, _) => Center(child: Text('load_transactions_error'.tr(ref))),
            );
          },
        );
      },
    );
  }

  // ── DATE RANGE PICKER
  Future<void> _showDateRangePicker(AppColorsExtension colors) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
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
        _startDate = picked.start;
        _endDate = picked.end;
        _showRecentOnly = false;
      });
    }
  }

  // ── ÁP DỤNG BỘ LỌC
  List<TransactionEntity> _applyFilters(List<TransactionEntity> txList) {
    List<String>? targetCategoryIds;
    if (_selectedCategoryId != null) {
      targetCategoryIds = [_selectedCategoryId!];
      final categories = ref.read(categoriesNotifierProvider).value ?? [];
      for (final parent in categories) {
        if (parent.id == _selectedCategoryId) {
          if (parent.children != null) {
            for (final child in parent.children!) {
              targetCategoryIds.add(child.id);
            }
          }
          break;
        }
      }
    }

    var result = txList.where((tx) {
      // Search
      final matchesSearch =
          tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (tx.categoryName ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (tx.notes ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());

      // Loại giao dịch
      final isTransfer = tx.sourceType == 'transfer';
      final matchesType = _selectedType == 'All' ||
          (_selectedType == 'Expense' &&
              tx.type == 'expense' &&
              !isTransfer) ||
          (_selectedType == 'Income' &&
              tx.type == 'income' &&
              !isTransfer) ||
          (_selectedType == 'Transfer' && isTransfer);

      // Danh mục (lọc theo ID cha hoặc ID con)
      final matchesCategory = targetCategoryIds == null ||
          targetCategoryIds.contains(tx.categoryId);

      // Ví (lọc theo ID)
      final matchesWallet =
          _selectedWalletId == null || tx.walletId == _selectedWalletId;

      // Ngày tháng
      bool matchesDate = true;
      if (_startDate != null) {
        matchesDate = matchesDate &&
            !tx.transactionDate.isBefore(DateTime(
                _startDate!.year, _startDate!.month, _startDate!.day));
      }
      if (_endDate != null) {
        matchesDate = matchesDate &&
            !tx.transactionDate.isAfter(DateTime(
                _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59));
      }

      return matchesSearch &&
          matchesType &&
          matchesCategory &&
          matchesWallet &&
          matchesDate;
    }).toList();

    // Sắp xếp: Ưu tiên giao dịch chờ đồng bộ (pending) lên đầu, sau đó sắp xếp theo ngày mới nhất
    result.sort((a, b) {
      final aPending = a.status == 'pending';
      final bPending = b.status == 'pending';
      if (aPending && !bPending) return -1;
      if (!aPending && bPending) return 1;
      return b.transactionDate.compareTo(a.transactionDate);
    });

    if (_showRecentOnly) return result.take(5).toList();
    return result;
  }

  // ── NHÓM THEO NGÀY
  List<MapEntry<String, List<TransactionEntity>>> _groupByDate(
      List<TransactionEntity> txs) {
    final Map<String, List<TransactionEntity>> groups = {};
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
    return groups.entries.toList();
  }

  // ── SECTION NGÀY
  Widget _buildDaySection(
    MapEntry<String, List<TransactionEntity>> group,
    AppColorsExtension colors,
    String userCurrency,
    String currencySymbol,
    dynamic ratesData,
  ) {
    final txList = group.value;

    double dayIncome  = 0;
    double dayExpense = 0;

    for (final tx in txList) {
      if (tx.sourceType == 'transfer') continue;
      final txCurrency = (tx.currencyCode ?? 'VND').toUpperCase();

      // Quy đổi về tiền tệ profile trước khi cộng vào tổng
      final converted = _convertToUserCurrency(
        tx.amount, txCurrency, userCurrency, ratesData,
      );

      if (tx.type == 'income') {
        dayIncome += converted;
      } else if (tx.type == 'expense') {
        dayExpense += converted;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.key.toUpperCase(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  if (dayIncome > 0)
                    Text(
                      '+${_fmt(dayIncome, userCurrency)} $currencySymbol',
                      style: TextStyle(
                        color: colors.incomeGreen,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (dayIncome > 0 && dayExpense > 0)
                    Text(
                      '  |  ',
                      style: TextStyle(
                        color: colors.textSecondary.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  if (dayExpense > 0)
                    Text(
                      '-${_fmt(dayExpense, userCurrency)} $currencySymbol',
                      style: TextStyle(
                        color: colors.expenseRed,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ...txList.map((tx) => TransactionCard(tx: tx)),
        const SizedBox(height: 8),
      ],
    );
  }


  Widget _buildTypeChip(String label, String value) {
    final colors = context.colors;
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : colors.textSecondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 64, color: colors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'no_transactions'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearAllFilters,
              child: Text('clear_filters'.tr(ref),
                  style: TextStyle(color: colors.primary)),
            ),
          ],
        ],
      ),
    );
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


  String _fmt(double value,String currencyCode) {
    final String code = currencyCode.toUpperCase();
    final int decimals = (code == 'VND' || code == 'JPY') ? 0 : 2;

    if (decimals == 0) {
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return value
          .toStringAsFixed(0)
          .replaceAllMapped(reg, (m) => '${m[1]},');
    } else {
      final parts = value.toStringAsFixed(2).split('.');
      final wholePart = parts[0];
      final decimalPart = parts[1];
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final formattedWhole = wholePart
          .replaceAllMapped(reg, (m) => '${m[1]},');
      return '$formattedWhole.$decimalPart';
    }
  }

  double _convertToUserCurrency(
    double amount,
    String fromCurrency,
    String userCurrency,
    dynamic ratesData,
  ) {
    final from = fromCurrency.toUpperCase();
    final to = userCurrency.toUpperCase();
    if (from == to) return amount;

    const fallbackRates = {
      'USD': 1.0, 'VND': 25400.0, 'EUR': 0.92,
      'GBP': 0.78, 'JPY': 156.0,
    };

    final base = (ratesData?.base ?? 'USD').toUpperCase();
    final rates = ratesData?.rates.map(
      (k, v) => MapEntry(k.toUpperCase(), v.toDouble()),
    ) ?? fallbackRates;

    final fromRate = from == base ? 1.0 : (rates[from] ?? 1.0);
    final toRate   = to == base   ? 1.0 : (rates[to]   ?? 1.0);

    return amount * (toRate / fromRate);
  }
}
