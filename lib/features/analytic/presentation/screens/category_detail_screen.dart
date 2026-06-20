import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:timezone/timezone.dart' as tz;

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final String type; // 'income' or 'expense'
  final DateTime startDate;
  final DateTime endDate;
  final String timeMode; // 'week', 'month', 'year'

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.timeMode,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late String _currentCategoryId;
  late String _currentCategoryName;
  late String? _currentCategoryColor;
  late String? _currentCategoryIcon;
  
  // Track selected period index in the chart (-1 means the latest/selected one)
  int _selectedChartIndex = 5; // defaults to the latest period
  String _activeFilterTab = 'all'; // 'all', 'top_spend', 'top_recipient'
  bool _isAmountVisible = true;

  @override
  void initState() {
    super.initState();
    _currentCategoryId = widget.categoryId;
    _currentCategoryName = widget.categoryName;
    _currentCategoryColor = widget.categoryColor;
    _currentCategoryIcon = widget.categoryIcon;
    _selectedChartIndex = (widget.timeMode == 'year') ? 1 : 5;
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  // Calculate start of chart range (e.g. 6 periods back)
  DateTime _getChartStartDate() {
    final endDate = widget.endDate;
    if (endDate is tz.TZDateTime) {
      final loc = endDate.location;
      if (widget.timeMode == 'week') {
        final start = endDate.subtract(const Duration(days: 41));
        return tz.TZDateTime(loc, start.year, start.month, start.day);
      } else if (widget.timeMode == 'month') {
        return tz.TZDateTime(loc, endDate.year, endDate.month - 5, 1);
      } else {
        return tz.TZDateTime(loc, endDate.year - 1, 1, 1);
      }
    } else {
      if (widget.timeMode == 'week') {
        return endDate.subtract(const Duration(days: 41));
      } else if (widget.timeMode == 'month') {
        return DateTime(endDate.year, endDate.month - 5, 1);
      } else {
        return DateTime(endDate.year - 1, 1, 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tzName = ref.watch(currentUserProvider.select((u) => u?.timezone)) ?? 'Asia/Ho_Chi_Minh';
    final location = tz.getLocation(tzName);

    final chartStartDate = _getChartStartDate();
    final chartEndDate = widget.endDate;

    // Fetch transactions for the 5-period window to compute chart and show lists
    final txAsync = ref.watch(categoryDetailTransactionsProvider((
      categoryId: _currentCategoryId,
      startDate: chartStartDate,
      endDate: chartEndDate,
      type: widget.type,
    )));

    return Scaffold(
      backgroundColor: isDark ? colors.background : const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: colors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _currentCategoryName,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Select & change category button
          // IconButton(
          //   icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
          //   tooltip: 'Đổi danh mục',
          //   onPressed: () => _showCategorySelectorBottomSheet(context),
          // ),
          // Home button
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: txAsync.when(
        data: (transactions) {
          // 1. Generate the periods buckets (5 periods: 0 to 4)
          final periods = _generatePeriods(chartStartDate, chartEndDate, widget.timeMode);
          
          // 2. Aggregate transactions into period buckets
          final List<double> periodAmounts = List.filled(periods.length, 0.0);
          for (final tx in transactions) {
            final txDate = tz.TZDateTime.from(tx.transactionDate, location);
            for (int i = 0; i < periods.length; i++) {
              if (txDate.isAfter(periods[i].start.subtract(const Duration(seconds: 1))) &&
                  txDate.isBefore(periods[i].end.add(const Duration(seconds: 1)))) {
                periodAmounts[i] += tx.amount * (tx.exchangeRate ?? 1.0);
                break;
              }
            }
          }

          // Bound selected index
          if (_selectedChartIndex >= periods.length) {
            _selectedChartIndex = periods.length - 1;
          }

          final currentPeriod = periods[_selectedChartIndex];
          final currentPeriodAmount = periodAmounts[_selectedChartIndex];

          // Compute average of non-zero periods (only months with spending)
          final nonZeroAmounts = periodAmounts.where((amt) => amt > 0).toList();
          final double averageAmount = nonZeroAmounts.isEmpty ? 0 : nonZeroAmounts.reduce((a, b) => a + b) / nonZeroAmounts.length;

          // Filter transactions matching the selected period
          final selectedPeriodTxs = transactions.where((tx) {
            final txDate = tz.TZDateTime.from(tx.transactionDate, location);
            return txDate.isAfter(currentPeriod.start.subtract(const Duration(seconds: 1))) &&
                txDate.isBefore(currentPeriod.end.add(const Duration(seconds: 1)));
          }).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🪙 Header Statistics Block
                Container(
                  width: double.infinity,
                  color: colors.primary,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPeriodLabel(currentPeriod.start, widget.timeMode) + (widget.type == 'expense' ? ' chi' : ' thu'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _isAmountVisible ? _formatCurrency(currentPeriodAmount) : '******',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAmountVisible = !_isAmountVisible;
                              });
                            },
                            child: Icon(
                              _isAmountVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'T.bình: ${_formatCurrency(averageAmount)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 📊 Custom Column Chart Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xu hướng chi tiêu',
                        style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nhấn vào cột để lọc danh sách giao dịch bên dưới',
                        style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                      ),
                      const SizedBox(height: 24),
                      // Interactive columns with Y-axis and Average Line
                      SizedBox(
                        height: 160,
                        child: LayoutBuilder(builder: (context, constraints) {
                          double maxVal = averageAmount * 1.5;
                          for (var amt in periodAmounts) {
                            if (amt > maxVal) maxVal = amt;
                          }
                          if (maxVal == 0) maxVal = 1.0;

                          // Định dạng các tick labels cho Y-axis
                          final levels = [1.0, 0.75, 0.5, 0.25, 0.0];
                          final tickLabels = levels.map((lvl) => _formatTick(maxVal * lvl)).toList();

                          String unit = '(đ)';
                          if (maxVal >= 1000000) {
                            unit = '(Tr)';
                          } else if (maxVal >= 1000) {
                            unit = '(K)';
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 1. Cột mức tiền cố định bên trái (Y-axis) - căn chỉnh hoàn hảo từng pixel
                              SizedBox(
                                height: 160,
                                width: 42,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Phần đơn vị nằm phía trên mức cao nhất
                                    Positioned(
                                      top: 35 - 20, // đặt cao hẳn lên (y = 15) để tránh dính chữ vào số
                                      right: 0,
                                      child: Text(
                                        unit,
                                        style: TextStyle(fontSize: 9, color: colors.textSecondary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // 5 mức tiền khớp hoàn hảo với trung tâm của 5 đường kẻ ngang
                                    ...List.generate(5, (index) {
                                      final double yPosition = 35 + (110 * (index / 4));
                                      return Positioned(
                                        top: yPosition - 6,
                                        right: 0,
                                        child: Text(
                                          tickLabels[index],
                                          style: TextStyle(fontSize: 10, color: colors.textSecondary, fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 2. Vùng biểu đồ cuộn ngang chứa lưới, cột và đường trung bình
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, chartConstraints) {
                                    final double minColumnWidth = widget.timeMode == 'year' ? 120.0 : 65.0;
                                    final double computedWidth = periods.length * minColumnWidth + 32.0;
                                    final double chartWidth = computedWidth > chartConstraints.maxWidth ? computedWidth : chartConstraints.maxWidth;

                                    return Stack(
                                      alignment: Alignment.bottomLeft,
                                      children: [
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          physics: const BouncingScrollPhysics(),
                                          child: SizedBox(
                                            width: chartWidth,
                                            height: 160,
                                            child: Stack(
                                              alignment: Alignment.bottomLeft,
                                              clipBehavior: Clip.none,
                                              children: [
                                                // Các đường kẻ ngang làm lưới phụ (sau các cột)
                                                Positioned(
                                                  left: 0,
                                                  right: 0,
                                                  bottom: 15,
                                                  top: 35,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: List.generate(
                                                      5,
                                                      (index) => Container(
                                                        height: 0.5,
                                                        color: colors.textSecondary.withOpacity(0.12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Đường nét đứt biểu thị mức trung bình (Average Line)
                                                if (maxVal > 0 && averageAmount > 0)
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    bottom: 15 + (110 * (averageAmount / maxVal)) - 0.5,
                                                    height: 1,
                                                    child: CustomPaint(
                                                      painter: DashedLinePainter(
                                                        color: Colors.orange.withOpacity(0.8),
                                                        strokeWidth: 1.2,
                                                        dashWidth: 4.0,
                                                        dashSpace: 3.0,
                                                      ),
                                                    ),
                                                  ),
                                                // Các cột dữ liệu
                                                Positioned(
                                                  left: 0,
                                                  right: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: List.generate(periods.length, (index) {
                                                        final amount = periodAmounts[index];
                                                        final label = periods[index].label;
                                                        final isSelected = index == _selectedChartIndex;
                                                        final pct = amount / maxVal;

                                                        return GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              _selectedChartIndex = index;
                                                            });
                                                          },
                                                          behavior: HitTestBehavior.opaque,
                                                          child: _buildSingleBar(label, amount, pct, colors, isSelected, widget.timeMode),
                                                        );
                                                      }),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Tag T.bình cố định bên phải hiển thị, không bị cuộn đi!
                                        if (maxVal > 0 && averageAmount > 0)
                                          Positioned(
                                            right: 8,
                                            bottom: 15 + (110 * (averageAmount / maxVal)) + 2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.orange.withOpacity(0.4),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                'T.bình',
                                                style: TextStyle(
                                                  color: Colors.orange.shade800,
                                                  fontSize: 7.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // 💸 Suggestion Card Section (if it's expense type)
                if (widget.type == 'expense')
                  _buildSuggestionCard(colors, averageAmount),

                // 💸 Transactions List Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh sách giao dịch',
                        style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Filter tabs row
                      Row(
                        children: [
                          _buildTabButton('all', 'Tất cả', Icons.list_alt_rounded, selectedPeriodTxs.length),
                          const SizedBox(width: 8),
                          _buildTabButton(
                            'top_spend',
                            widget.type == 'expense' ? 'Top chi tiêu' : 'Top thu nhập',
                            Icons.bar_chart_rounded,
                            null,
                          ),
                          const SizedBox(width: 8),
                          _buildTabButton(
                            'top_recipient',
                            widget.type == 'expense' ? 'Top người nhận' : 'Top nguồn gửi',
                            Icons.person_outline_rounded,
                            null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Render transactions based on active filter tab
                      _buildTransactionListContent(selectedPeriodTxs, colors),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => Column(
          children: [
            _buildShimmerHeader(colors),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildShimmerCard(height: 200, colors: colors),
            ),
          ],
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Lỗi tải dữ liệu chi tiết: $err', style: TextStyle(color: colors.expenseRed)),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(AppColorsExtension colors, double averageAmount) {
    // Tạo danh sách các gợi ý động cho danh mục
    final suggestions = [
      (
        icon: '👀',
        text: 'So sánh chi tiêu $_currentCategoryName với người 20 tuổi',
        query: 'Hãy so sánh mức chi tiêu cho danh mục $_currentCategoryName của tôi với mức trung bình của những người ở độ tuổi 20.'
      ),
      (
        icon: '✨',
        text: '20 tuổi, chi tiêu $_currentCategoryName như nào?',
        query: 'Ở tuổi 20, tôi nên chi tiêu cho danh mục $_currentCategoryName như thế nào cho hợp lý và tiết kiệm nhất?'
      ),
      (
        icon: '💡',
        text: 'Mẹo cắt giảm $_currentCategoryName hiệu quả',
        query: 'Hãy cho tôi một số mẹo thực tế để cắt giảm chi tiêu trong danh mục $_currentCategoryName.'
      ),
      (
        icon: '📊',
        text: 'Dự báo $_currentCategoryName tháng tới',
        query: 'Dựa trên lịch sử giao dịch của tôi, hãy dự báo chi tiêu danh mục $_currentCategoryName trong tháng tới và đưa ra lời khuyên.'
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Gợi ý cho bạn',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length + 1, // +1 cho icon Bot Moni ở đầu
            itemBuilder: (context, index) {
              if (index == 0) {
                // Vẽ mặt Bot Moni nhỏ lấp lánh ở đầu hàng cuộn ngang
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final suggestion = suggestions[index - 1];

              // Màu pastel cho từng chip khi ở chế độ Light Mode
              final List<Color> bgColorsLight = [
                const Color(0xFFE3F2FD), // Xanh lam nhạt
                const Color(0xFFF3E5F5), // Tím nhạt
                const Color(0xFFE8F5E9), // Xanh lá nhạt
                const Color(0xFFFFF3E0), // Cam nhạt
              ];
              final List<Color> borderColorsLight = [
                const Color(0xFFBBDEFB),
                const Color(0xFFE1BEE7),
                const Color(0xFFC8E6C9),
                const Color(0xFFFFE0B2),
              ];

              final chipIndex = (index - 1) % bgColorsLight.length;
              final bgColor = isDark ? colors.surface : bgColorsLight[chipIndex];
              final borderColor = isDark ? colors.textSecondary.withOpacity(0.15) : borderColorsLight[chipIndex];

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: ActionChip(
                    onPressed: () {
                      context.push(RoutePaths.aiAssistant, extra: suggestion.query);
                    },
                    avatar: Text(suggestion.icon, style: const TextStyle(fontSize: 13)),
                    label: Text(
                      suggestion.text,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: bgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: borderColor, width: 0.8),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTabButton(String key, String label, IconData icon, int? count) {
    final colors = context.colors;
    final isActive = _activeFilterTab == key;
    final displayLabel = count != null ? '$label ($count)' : label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeFilterTab = key;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? colors.primary.withOpacity(0.08) : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? colors.primary : colors.textSecondary.withOpacity(0.15),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? colors.primary : colors.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? colors.primary : colors.textSecondary,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionListContent(List<TransactionEntity> originalList, AppColorsExtension colors) {
    if (originalList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Không có giao dịch nào trong kỳ này',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    if (_activeFilterTab == 'all') {
      // Group by date
      final Map<String, List<TransactionEntity>> grouped = {};
      for (final tx in originalList) {
        final dateStr = DateFormat('dd/MM/yyyy').format(tx.transactionDate);
        grouped.putIfAbsent(dateStr, () => []).add(tx);
      }

      final keys = grouped.keys.toList();
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        separatorBuilder: (context, index) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final dateStr = keys[index];
          final txs = grouped[dateStr]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ...txs.map((tx) => _buildTransactionItemRow(tx, colors)),
            ],
          );
        },
      );
    } else if (_activeFilterTab == 'top_spend') {
      // Sort by amount descending in user currency
      final sortedList = List<TransactionEntity>.from(originalList)
        ..sort((a, b) => (b.amount * (b.exchangeRate ?? 1.0)).compareTo(a.amount * (a.exchangeRate ?? 1.0)));

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedList.length,
        separatorBuilder: (context, index) => const Divider(height: 12, thickness: 0.5),
        itemBuilder: (context, index) {
          final tx = sortedList[index];
          return _buildTransactionItemRow(tx, colors);
        },
      );
    } else {
      // Group and sum by payee using user currency amount
      final Map<String, ({double amount, int count})> payeeGroups = {};

      for (final tx in originalList) {
        final String payee = (tx.payeeName != null && tx.payeeName!.trim().isNotEmpty)
            ? tx.payeeName!.trim()
            : tx.title.trim();
        
        final txAmount = tx.amount * (tx.exchangeRate ?? 1.0);
        final existing = payeeGroups[payee];
        if (existing != null) {
          payeeGroups[payee] = (
            amount: existing.amount + txAmount,
            count: existing.count + 1,
          );
        } else {
          payeeGroups[payee] = (
            amount: txAmount,
            count: 1,
          );
        }
      }

      final sortedPayees = payeeGroups.keys.toList()
        ..sort((a, b) => payeeGroups[b]!.amount.compareTo(payeeGroups[a]!.amount));

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedPayees.length,
        separatorBuilder: (context, index) => const Divider(height: 12, thickness: 0.5),
        itemBuilder: (context, index) {
          final name = sortedPayees[index];
          final data = payeeGroups[name]!;

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final rankColor = isDark ? Colors.grey[400] : Colors.grey[600];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: colors.primary.withOpacity(0.1),
                  radius: 20,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.count} giao dịch',
                        style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Text(
                  (widget.type == 'expense' ? '-' : '+') + _formatCurrency(data.amount),
                  style: TextStyle(
                    color: widget.type == 'expense' ? colors.expenseRed : colors.incomeGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildTransactionItemRow(TransactionEntity tx, AppColorsExtension colors) {
    final catColor = CategoryUIConstants.getColorFromHex(tx.categoryColor ?? _currentCategoryColor);
    final catIcon = CategoryUIConstants.getIconData(tx.categoryIcon ?? _currentCategoryIcon);

    final showCategoryName = tx.categoryName != null && tx.categoryName!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: catColor.withOpacity(0.12),
            radius: 20,
            child: Icon(catIcon, color: catColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (showCategoryName) ...[
                      Text(
                        tx.categoryName!.tr(ref),
                        style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(color: colors.textSecondary.withOpacity(0.5), fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                    if (tx.notes != null && tx.notes!.isNotEmpty)
                      Expanded(
                        child: Text(
                          tx.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            (tx.type == 'expense' ? '-' : '+') + _formatCurrency(tx.amount * (tx.exchangeRate ?? 1.0)),
            style: TextStyle(
              color: tx.type == 'expense' ? colors.expenseRed : colors.incomeGreen,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Generate date ranges for periods
  List<PeriodBucket> _generatePeriods(DateTime start, DateTime end, String mode) {
    final List<PeriodBucket> buckets = [];
    if (mode == 'week') {
      // 6 weeks
      for (int i = 0; i < 6; i++) {
        final wStart = start.add(Duration(days: i * 7));
        final wEnd = wStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        buckets.add(PeriodBucket(
          start: wStart,
          end: wEnd,
          label: '${wStart.day}/${wStart.month}',
        ));
      }
    } else if (mode == 'month') {
      // 6 months
      for (int i = 0; i < 6; i++) {
        final date = DateTime(start.year, start.month + i, 1);
        final mStart = DateTime(date.year, date.month, 1);
        final mEnd = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
        buckets.add(PeriodBucket(
          start: mStart,
          end: mEnd,
          label: i == 0 ? '${mStart.month}/${mStart.year}' : '${mStart.month}',
        ));
      }
    } else {
      // year: 2 years (last year and this year)
      for (int i = 0; i < 2; i++) {
        final year = start.year + i;
        buckets.add(PeriodBucket(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31, 23, 59, 59),
          label: '$year',
        ));
      }
    }
    return buckets;
  }

  String _getPeriodLabel(DateTime start, String mode) {
    if (mode == 'week') {
      final end = start.add(const Duration(days: 6));
      return 'Tuần ${start.day}/${start.month} - ${end.day}/${end.month}';
    } else if (mode == 'month') {
      return 'Tháng ${start.month}/${start.year}';
    } else {
      return 'Năm ${start.year}';
    }
  }

  String _formatCompact(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K';
    }
    return val.toStringAsFixed(0);
  }

  // Show Bottom Sheet to choose another subcategory
  // void _showCategorySelectorBottomSheet(BuildContext context) async {
  //   final colors = context.colors;
  //   final database = ref.read(appDatabaseProvider);
  //   final allCategories = await database.getAllCategories();
  //   
  //   // Filter by type (income vs expense)
  //   final filtered = allCategories.where((c) => c.type == widget.type).toList();
  // 
  //   if (!context.mounted) return;
  // 
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: colors.surface,
  //     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  //     builder: (ctx) {
  //       return Container(
  //         padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
  //         height: 400,
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Chọn danh mục con',
  //               style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 16),
  //             Expanded(
  //               child: ListView.separated(
  //                 itemCount: filtered.length,
  //                 separatorBuilder: (c, i) => const Divider(height: 1, thickness: 0.5),
  //                 itemBuilder: (c, idx) {
  //                   final cat = filtered[idx];
  //                   final color = CategoryUIConstants.getColorFromHex(cat.color);
  //                   final icon = CategoryUIConstants.getIconData(cat.icon);
  //                   final isSelected = cat.id == _currentCategoryId;
  // 
  //                   return ListTile(
  //                     onTap: () {
  //                       setState(() {
  //                         _currentCategoryId = cat.id;
  //                         _currentCategoryName = cat.name;
  //                         _currentCategoryColor = cat.color;
  //                         _currentCategoryIcon = cat.icon;
  //                       });
  //                       Navigator.pop(ctx);
  //                     },
  //                     leading: CircleAvatar(
  //                       backgroundColor: color.withOpacity(0.12),
  //                       child: Icon(icon, color: color, size: 20),
  //                     ),
  //                     title: Text(
  //                       cat.name,
  //                       style: TextStyle(
  //                         color: isSelected ? colors.primary : colors.textPrimary,
  //                         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  //                       ),
  //                     ),
  //                     trailing: isSelected
  //                         ? Icon(Icons.check_circle_rounded, color: colors.primary)
  //                         : null,
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildShimmerHeader(AppColorsExtension colors) {
    return Shimmer.fromColors(
      baseColor: colors.textSecondary.withOpacity(0.08),
      highlightColor: colors.textSecondary.withOpacity(0.03),
      child: Container(
        height: 160,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildShimmerCard({required double height, required AppColorsExtension colors}) {
    return Shimmer.fromColors(
      baseColor: colors.textSecondary.withOpacity(0.08),
      highlightColor: colors.textSecondary.withOpacity(0.03),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  String _formatTick(double value) {
    if (value >= 1000000) {
      return (value / 1000000).toStringAsFixed(1);
    } else if (value >= 1000) {
      return (value / 1000).toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildSingleBar(
    String label,
    double value,
    double pct,
    AppColorsExtension colors,
    bool isSelected,
    String timeMode,
  ) {
    final barColor = isSelected ? colors.primary : colors.primary.withOpacity(0.25);
    final double barWidth = timeMode == 'year' ? 48.0 : 32.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Vùng vẽ cột cao 110px (từ y = 35 đến y = 145)
        SizedBox(
          height: 110,
          width: barWidth,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Cột màu xanh
              Container(
                width: barWidth,
                height: (110 * pct).clamp(4.0, 110.0),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              // Tooltip badge above selected column
              if (isSelected)
                Positioned(
                  bottom: (110 * pct).clamp(4.0, 110.0) + 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.textPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatCompact(value),
                      style: TextStyle(color: colors.surface, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Nhãn trục X cao 11px
        Container(
          height: 11,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.primary : colors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class PeriodBucket {
  final DateTime start;
  final DateTime end;
  final String label;

  PeriodBucket({
    required this.start,
    required this.end,
    required this.label,
  });
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
