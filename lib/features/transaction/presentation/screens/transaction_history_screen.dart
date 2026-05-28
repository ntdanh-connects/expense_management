import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';

class MockTransaction {
  final String id;
  final String title;
  final String category;
  final String wallet;
  final double amount;
  final bool isIncome;
  final bool isTransfer; // Chuyển tiền
  final DateTime date;
  final IconData icon;
  final Color color;

  MockTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.wallet,
    required this.amount,
    required this.isIncome,
    this.isTransfer = false,
    required this.date,
    required this.icon,
    required this.color,
  });
}

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Expense, Income, Transfer

  final List<MockTransaction> _allTransactions = [
    MockTransaction(
      id: '1',
      title: 'Ăn trưa (Phở Bò)',
      category: 'Ăn uống',
      wallet: 'Ví Tiền mặt',
      amount: 65000.0,
      isIncome: false,
      date: DateTime.now(),
      icon: Icons.restaurant_rounded,
      color: Colors.orange,
    ),
    MockTransaction(
      id: '2',
      title: 'Grab Bike',
      category: 'Di chuyển',
      wallet: 'MoMo Wallet',
      amount: 55000.0,
      isIncome: false,
      date: DateTime.now(),
      icon: Icons.directions_bike_rounded,
      color: Colors.blue,
    ),
    MockTransaction(
      id: '3',
      title: 'Lương tháng 10',
      category: 'Lương',
      wallet: 'Vietcombank',
      amount: 15000000.0,
      isIncome: true,
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.payments_rounded,
      color: Colors.green,
    ),
    MockTransaction(
      id: '4',
      title: 'Mua sắm Shopee',
      category: 'Mua sắm',
      wallet: 'Ví Tiền mặt',
      amount: 200000.0,
      isIncome: false,
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.shopping_bag_rounded,
      color: Colors.purple,
    ),
    MockTransaction(
      id: '5',
      title: 'Chuyển nội bộ',
      category: 'Chuyển khoản',
      wallet: 'Tiền mặt → MoMo',
      amount: 500000.0,
      isIncome: false,
      isTransfer: true,
      date: DateTime.now().subtract(const Duration(days: 3)),
      icon: Icons.swap_horiz_rounded,
      color: Colors.grey.shade600,
    ),
    MockTransaction(
      id: '6',
      title: 'Tiền điện tháng 10',
      category: 'Hóa đơn',
      wallet: 'Vietcombank',
      amount: 450000.0,
      isIncome: false,
      date: DateTime.now().subtract(const Duration(days: 3)),
      icon: Icons.electric_bolt_rounded,
      color: Colors.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Lọc danh sách theo bộ tìm kiếm + bộ lọc ngang
    final filteredTransactions = _allTransactions.where((tx) {
      final matchesSearch = tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _selectedFilter == 'All' ||
          (_selectedFilter == 'Expense' && !tx.isIncome && !tx.isTransfer) ||
          (_selectedFilter == 'Income' && tx.isIncome) ||
          (_selectedFilter == 'Transfer' && tx.isTransfer);

      return matchesSearch && matchesType;
    }).toList();

    // Nhóm giao dịch theo Ngày để hiển thị chuẩn chỉ
    final groupedTransactions = _groupTransactionsByDate(filteredTransactions);

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
                  'Lịch sử',
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chi tiêu', 'Expense'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Thu nhập', 'Income'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chuyển tiền', 'Transfer'),
                ],
              ),
            ),
          ),

          // 📅 3. THANH DROPDOWN CHỌN NHANH (THÁNG NÀY / TẤT CẢ VÍ / HẠNG MỤC)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                _buildDropdownButton('Tháng này'),
                const SizedBox(width: 8),
                _buildDropdownButton('Tất cả ví'),
                const SizedBox(width: 8),
                _buildDropdownButton('Hạng mục'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. DANH SÁCH CÁC NGÀY NHÓM GIAO DỊCH
          Expanded(
            child: groupedTransactions.isEmpty
                ? _buildEmptyState(colors)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: groupedTransactions.length,
                    itemBuilder: (context, index) {
                      final group = groupedTransactions[index];
                      return _buildDateGroupSection(group, colors);
                    },
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
          color: isSelected ? colors.primary : colors.textSecondary.withOpacity(0.08),
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
          Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 16),
        ],
      ),
    );
  }

  Widget _buildDateGroupSection(MapEntry<String, List<MockTransaction>> group, AppColorsExtension colors) {
    final dateStr = group.key;
    final txList = group.value;

    // Tính tổng thu/chi của ngày đó để hiển thị góc phải
    double dayTotal = 0;
    for (var tx in txList) {
      if (tx.isIncome) {
        dayTotal += tx.amount;
      } else {
        dayTotal -= tx.amount;
      }
    }

    final totalSign = dayTotal >= 0 ? '+' : '-';
    final totalColor = dayTotal >= 0 ? colors.incomeGreen : colors.textSecondary;
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

  Widget _buildTransactionCard(MockTransaction tx, AppColorsExtension colors) {
    String displayAmount = '${_formatMoney(tx.amount)} đ';
    Color amountColor = colors.textPrimary;

    if (tx.isIncome) {
      displayAmount = '+$displayAmount';
      amountColor = colors.incomeGreen;
    } else if (tx.isTransfer) {
      amountColor = colors.textPrimary; // Chuyển khoản giữ màu thường
    } else {
      displayAmount = '-$displayAmount';
      amountColor = colors.expenseRed;
    }

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
              color: tx.color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(tx.icon, color: tx.color, size: 22),
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
                  '${tx.wallet} • ${_formatTime(tx.date)}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
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
            'Không tìm thấy giao dịch nào',
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

  List<MapEntry<String, List<MockTransaction>>> _groupTransactionsByDate(List<MockTransaction> txs) {
    final Map<String, List<MockTransaction>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var tx in txs) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String key = '';
      if (txDate == today) {
        key = 'Hôm nay';
      } else if (txDate == yesterday) {
        key = 'Hôm qua';
      } else {
        key = '${txDate.day} Tháng ${txDate.month}, ${txDate.year}';
      }

      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(tx);
    }

    return groups.entries.toList();
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
