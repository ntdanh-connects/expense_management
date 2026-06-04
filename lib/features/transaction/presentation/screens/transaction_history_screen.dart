import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Expense, Income, Transfer
  String _groupBy = 'date'; // 'date', 'category', 'wallet'

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final transactionState = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: SharedTopAppBar(
        hintText: 'Tìm kiếm giao dịch...',
        onSearchChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🧾 1. TIÊU ĐỀ "LỊCH SỬ" & ICON DOWLOAD/EXPORT CỰC ĐẸP
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'history'.tr(ref),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.file_download_outlined,
                    color: colors.primary,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),

          // 📊 2. BỘ LỌC NGANG CHIP (TẤT CẢ / CHI TIÊU / THU NHẬP / CHUYỂN TIỀN)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('all'.tr(ref), 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('expense'.tr(ref), 'Expense'),
                  const SizedBox(width: 8),
                  _buildFilterChip('income'.tr(ref), 'Income'),
                  const SizedBox(width: 8),
                  _buildFilterChip('transfer'.tr(ref), 'Transfer'),
                ],
              ),
            ),
          ),

          // 📅 3. THANH DROPDOWN CHỌN NHANH (THÁNG NÀY / TẤT CẢ VÍ / HẠNG MỤC)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                _buildDropdownButton('this_month'.tr(ref)),
                const SizedBox(width: 8),
                _buildDropdownButton('all_wallets'.tr(ref)),
                const SizedBox(width: 8),
                _buildDropdownButton('category'.tr(ref)),
              ],
            ),
          ),

          // 📊 4. Classification Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    'group_by_label'.tr(ref) + ': ',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildGroupByChip('date_group'.tr(ref), 'date'),
                  const SizedBox(width: 8),
                  _buildGroupByChip('category_group'.tr(ref), 'category'),
                  const SizedBox(width: 8),
                  _buildGroupByChip('wallet_group'.tr(ref), 'wallet'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. DANH SÁCH CÁC NGÀY NHÓM GIAO DỊCH
          Expanded(
            child: transactionState.when(
              data: (txList) {
                // Filter the transactions list
                final filteredTransactions = txList.where((tx) {
                  final matchesSearch =
                      tx.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (tx.categoryName ?? '').toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );

                  final isTransfer = tx.sourceType == 'transfer';
                  final matchesType =
                      _selectedFilter == 'All' ||
                      (_selectedFilter == 'Expense' &&
                          tx.type == 'expense' &&
                          !isTransfer) ||
                      (_selectedFilter == 'Income' &&
                          tx.type == 'income' &&
                          !isTransfer) ||
                      (_selectedFilter == 'Transfer' && isTransfer);

                  return matchesSearch && matchesType;
                }).toList();

                if (filteredTransactions.isEmpty) {
                  return _buildEmptyState(colors);
                }

                // Group by selected mode
                final groupedTransactions = _groupTransactions(
                  filteredTransactions,
                );

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    final group = groupedTransactions[index];
                    return _buildDateGroupSection(group, colors);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
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
          const SizedBox(height: 80), // Dành khoảng trống cho Bottom Bar
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final colors = context.colors;
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownButton(String title) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroupSection(
    MapEntry<String, List<TransactionEntity>> group,
    AppColorsExtension colors,
  ) {
    final dateStr = group.key;
    final txList = group.value;

    // Tính tổng thu/chi của ngày đó để hiển thị góc phải
    double dayTotal = 0;
    for (var tx in txList) {
      if (tx.type == 'income') {
        dayTotal += tx.amount;
      } else {
        dayTotal -= tx.amount;
      }
    }

    final totalSign = dayTotal >= 0 ? '+' : '-';
    final totalColor = dayTotal >= 0
        ? colors.incomeGreen
        : colors.textSecondary;
    final totalDisplay = '$totalSign${_formatMoney(dayTotal.abs())} đ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề ngày nhóm
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr.toUpperCase(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                totalDisplay,
                style: TextStyle(
                  color: totalColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Danh sách giao dịch của ngày đó
        ...txList.map((tx) => _buildTransactionCard(tx, colors)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTransactionCard(
    TransactionEntity tx,
    AppColorsExtension colors,
  ) {
    String displayAmount = '${_formatMoney(tx.amount)} đ';
    Color amountColor = colors.textPrimary;
    final isIncome = tx.type == 'income';
    final isTransfer = tx.sourceType == 'transfer';

    if (isIncome) {
      displayAmount = '+$displayAmount';
      amountColor = colors.incomeGreen;
    } else if (isTransfer) {
      amountColor = colors.textPrimary;
    } else {
      displayAmount = '-$displayAmount';
      amountColor = colors.expenseRed;
    }

    final categoryIcon = CategoryUIConstants.getIconData(tx.categoryIcon);
    final categoryColor = CategoryUIConstants.getColorFromHex(tx.categoryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          // Icon tròn phát sáng màu nhẹ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Tiêu đề, ví thanh toán & Giờ giấc
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tx.walletName ?? 'Ví'} • ${_formatTime(tx.transactionDate)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          // Số tiền
          Text(
            displayAmount,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 16.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: colors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'no_transactions'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthNameEn(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  List<MapEntry<String, List<TransactionEntity>>> _groupTransactions(
    List<TransactionEntity> txs,
  ) {
    // Sort transactions by date descending
    txs.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    if (_groupBy == 'category') {
      final Map<String, List<TransactionEntity>> groups = {};
      for (var tx in txs) {
        final key = tx.categoryName ?? 'Chưa phân loại';
        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(tx);
      }
      return groups.entries.toList();
    } else if (_groupBy == 'wallet') {
      final Map<String, List<TransactionEntity>> groups = {};
      for (var tx in txs) {
        final key = tx.walletName ?? 'Ví';
        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(tx);
      }
      return groups.entries.toList();
    } else {
      // Default: date
      final Map<String, List<TransactionEntity>> groups = {};
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final isVi = ref.read(localeProvider) == 'vi';

      for (var tx in txs) {
        final txDate = DateTime(
          tx.transactionDate.year,
          tx.transactionDate.month,
          tx.transactionDate.day,
        );
        String key = '';
        if (txDate == today) {
          key = 'today'.trRead(ref);
        } else if (txDate == yesterday) {
          key = 'yesterday'.trRead(ref);
        } else {
          key = isVi
              ? '${txDate.day} Tháng ${txDate.month}, ${txDate.year}'
              : '${txDate.day} ${_getMonthNameEn(txDate.month)}, ${txDate.year}';
        }

        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(tx);
      }
      return groups.entries.toList();
    }
  }

  Widget _buildGroupByChip(String label, String value) {
    final colors = context.colors;
    final isSelected = _groupBy == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _groupBy = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : colors.textSecondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  String _formatMoney(double value) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]},';
    return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
  }
}
