import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/shared_top_app_bar.dart';

class AnalyticScreen extends ConsumerStatefulWidget {
  const AnalyticScreen({super.key});

  @override
  ConsumerState<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends ConsumerState<AnalyticScreen> {
  String _selectedSubTab = 'Thống kê'; // Thống kê, Lịch sử, Ngân sách

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const SharedTopAppBar(
        hintText: 'Tìm kiếm giao dịch, ví, hũ...',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 1. BỘ PHÂN LOẠI NGANG PHỤ (THỐNG KÊ / LỊCH SỬ / NGÂN SÁCH)
            Row(
              children: [
                _buildSubTabButton('Thống kê'),
                const SizedBox(width: 8),
                _buildSubTabButton('Lịch sử'),
                const SizedBox(width: 8),
                _buildSubTabButton('Ngân sách'),
              ],
            ),
            const SizedBox(height: 18),

            // 📈 2. BIỂU ĐỒ CỘT THU NHẬP & CHI TIÊU HÀNG THÁNG
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thu nhập & Chi tiêu',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dữ liệu 6 tháng gần nhất',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(colors.primary, 'Thu nhập'),
                          const SizedBox(width: 12),
                          _buildLegendDot(const Color(0xFFA7F3D0), 'Chi tiêu'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Vẽ cột biểu đồ
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildDoubleBar('T1', 0.6, 0.45, colors),
                        _buildDoubleBar('T2', 0.72, 0.55, colors),
                        _buildDoubleBar('T3', 0.5, 0.48, colors),
                        _buildDoubleBar('T4', 0.8, 0.38, colors),
                        _buildDoubleBar('T5', 0.65, 0.7, colors),
                        _buildDoubleBar('T6', 0.88, 0.42, colors),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 🍩 3. BIỂU ĐỒ TRÒN PHÂN BỐ DANH MỤC
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phân bố danh mục',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Custom Donut Chart (Chất lượng Premium vẽ hình học)
                          CustomPaint(
                            size: const Size(150, 150),
                            painter: DonutChartPainter(
                              segments: [
                                ChartSegment(color: colors.primary.withOpacity(0.3), percentage: 0.25),
                                ChartSegment(color: const Color(0xFFFED7AA), percentage: 0.15),
                                ChartSegment(color: const Color(0xFFFCA5A5), percentage: 0.20),
                                ChartSegment(color: const Color(0xFFA7F3D0), percentage: 0.40),
                              ],
                              strokeWidth: 20,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tổng chi',
                                style: TextStyle(color: colors.textSecondary, fontSize: 12),
                              ),
                              Text(
                                '10,5M',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Bấm vào từng phần để xem chi tiết',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 🏆 4. DANH SÁCH TOP 5 CHI TIÊU PROGRESS BAR
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top 5 Chi tiêu',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTopExpenseRow('Ăn uống', '4,200,000đ', 0.8, const Color(0xFFA7F3D0), colors),
                  _buildTopExpenseRow('Tiền thuê nhà', '3,500,000đ', 0.68, const Color(0xFFEF4444), colors),
                  _buildTopExpenseRow('Mua sắm', '2,625,000đ', 0.5, const Color(0xFFFCA5A5), colors),
                  _buildTopExpenseRow('Di chuyển', '2,100,000đ', 0.4, const Color(0xFFCBD5E1), colors),
                  _buildTopExpenseRow('Học tập', '1,200,000đ', 0.22, const Color(0xFFD1FAE5), colors),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 📥 5. GRID 2 HỘP THÔNG TIN (TIẾT KIỆM VÀ SỐ DƯ)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
                        SizedBox(height: 14),
                        Text(
                          'TIẾT KIỆM',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '+15.2%',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: colors.incomeGreen, size: 22),
                        const SizedBox(height: 14),
                        Text(
                          'SỐ DƯ',
                          style: TextStyle(color: colors.incomeGreen.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '24,5M',
                          style: TextStyle(color: colors.incomeGreen, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 🎯 6. MỤC TIÊU MUA XE PROGRESS CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mục tiêu mua xe',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '75%',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Còn 12.000.000đ',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Thanh progress bar của mục tiêu
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: 0.75,
                            minHeight: 6,
                            backgroundColor: colors.textSecondary.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.directions_car_filled_rounded, color: colors.primary, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Dành khoảng trống cho Bottom Bar trượt
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String title) {
    final colors = context.colors;
    final isSelected = _selectedSubTab == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubTab = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.textSecondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDoubleBar(String label, double incomeVal, double expenseVal, AppColorsExtension colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Cột thu nhập
            Container(
              width: 8,
              height: 110 * incomeVal,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(width: 4),
            // Cột chi tiêu
            Container(
              width: 8,
              height: 110 * expenseVal,
              decoration: BoxDecoration(
                color: const Color(0xFFA7F3D0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTopExpenseRow(String title, String amount, double pct, Color progressColor, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: colors.textSecondary.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

// 📐 VẼ CUSTOM DONUT CHART PHÂN BỔ DANH MỤC TIÊU DÙNG
class ChartSegment {
  final Color color;
  final double percentage;
  ChartSegment({required this.color, required this.percentage});
}

class DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double strokeWidth;

  DonutChartPainter({required this.segments, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    double startAngle = -3.14159 / 2; // Bắt đầu ở góc 12h

    for (var segment in segments) {
      final sweepAngle = segment.percentage * 2 * 3.14159;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}