import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/profile/data/models/exchange_rates_dto.dart';

class VcbRateReferenceWidget extends ConsumerStatefulWidget {
  final String currencyCode;
  final double initialAmount;

  const VcbRateReferenceWidget({
    super.key,
    required this.currencyCode,
    required this.initialAmount,
  });

  @override
  ConsumerState<VcbRateReferenceWidget> createState() => _VcbRateReferenceWidgetState();
}

class _VcbRateReferenceWidgetState extends ConsumerState<VcbRateReferenceWidget> {
  late TextEditingController _amountController;
  double _customAmount = 0.0;
  bool _isExplanationExpanded = false;

  @override
  void initState() {
    super.initState();
    _customAmount = widget.initialAmount > 0 ? widget.initialAmount : 1.0;
    _amountController = TextEditingController(
      text: _customAmount.toStringAsFixed(widget.currencyCode == 'JPY' ? 0 : 2),
    );
  }

  @override
  void didUpdateWidget(covariant VcbRateReferenceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currencyCode != widget.currencyCode || oldWidget.initialAmount != widget.initialAmount) {
      _customAmount = widget.initialAmount > 0 ? widget.initialAmount : 1.0;
      _amountController.text = _customAmount.toStringAsFixed(widget.currencyCode == 'JPY' ? 0 : 2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatVnd(double value) {
    return NumberFormat('#,###').format(value) + ' ₫';
  }

  String _formatCurrency(double value) {
    if (widget.currencyCode == 'JPY') {
      return NumberFormat('#,###').format(value);
    }
    return NumberFormat('#,##0.00').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Nếu là VND thì không cần hiển thị widget tham chiếu tỷ giá ngoại tệ
    if (widget.currencyCode == 'VND') {
      return const SizedBox.shrink();
    }

    final ratesAsync = ref.watch(exchangeRatesProvider);

    return ratesAsync.when(
      loading: () => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      ),
      error: (error, _) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.expenseRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.expenseRed.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.expenseRed),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Không thể tải dữ liệu tỷ giá Vietcombank.',
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      data: (ratesData) {
        final vcbRates = ratesData.vcbRates;
        if (vcbRates == null || !vcbRates.containsKey(widget.currencyCode)) {
          return const SizedBox.shrink();
        }

        final rateItem = vcbRates[widget.currencyCode]!;

        // Các tính toán quy đổi VND dựa trên số tiền người dùng nhập
        final vndCash = _customAmount * rateItem.buyCash;
        final vndTransfer = _customAmount * rateItem.buyTransfer;
        final vndSell = _customAmount * rateItem.sell;

        final cardBg = isDark ? colors.surface.withOpacity(0.6) : const Color(0xFFF2F4FC);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.primary.withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề & Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.currency_exchange_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tham chiếu tỷ giá Vietcombank',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quy đổi ${widget.currencyCode} sang tiền Việt Nam (VND)',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Ô nhập số ngoại tệ tham khảo
              Text(
                'Nhập số tiền ngoại tệ tham khảo:',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.textSecondary.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          final double? amt = double.tryParse(val.replaceAll(',', ''));
                          if (amt != null) {
                            setState(() {
                              _customAmount = amt;
                            });
                          } else if (val.isEmpty) {
                            setState(() {
                              _customAmount = 0.0;
                            });
                          }
                        },
                      ),
                    ),
                    Text(
                      widget.currencyCode,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bảng tỷ giá & Số tiền quy đổi
              _buildRateRow(
                title: '1. Tiền mặt (Cash Buy)',
                description: 'Bán ngoại tệ tiền mặt lấy VND',
                rateValue: rateItem.buyCash,
                vndValue: vndCash,
                feePercent: rateItem.buyCashFeePercent,
                feeColor: colors.expenseRed,
                colors: colors,
              ),
              const Divider(height: 20),
              _buildRateRow(
                title: '2. Chuyển khoản (Transfer Buy)',
                description: 'Bán ngoại tệ qua bank lấy VND',
                rateValue: rateItem.buyTransfer,
                vndValue: vndTransfer,
                feePercent: rateItem.buyTransferFeePercent,
                feeColor: colors.incomeGreen,
                colors: colors,
              ),
              const Divider(height: 20),
              _buildRateRow(
                title: '3. Bán ra (Sell Rate)',
                description: 'Dùng VND mua ngoại tệ từ bank',
                rateValue: rateItem.sell,
                vndValue: vndSell,
                feePercent: rateItem.sellFeePercent,
                feeColor: Colors.orange,
                colors: colors,
              ),
              const SizedBox(height: 16),

              // Chú thích giải thích cách ăn % của ngân hàng (Collapsible)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExplanationExpanded = !_isExplanationExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giải thích về phần trăm chiết khấu của ngân hàng',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _isExplanationExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: colors.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExplanationExpanded) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '• % Phí ngân hàng ăn được tính dựa trên độ lệch giữa tỷ giá thực tế (Mua/Bán) so với tỷ giá trung bình (Mid-market rate).\n'
                    '• Đối với Tiền mặt và Chuyển khoản, phần trăm này thể hiện phần chiết khấu bạn bị giảm trừ so với giá trị thực tế của ngoại tệ.\n'
                    '• Đối với Bán ra, đây là phần phụ phí ngân hàng cộng thêm vào giá trị gốc của ngoại tệ khi bán cho bạn.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRateRow({
    required String title,
    required String description,
    required double rateValue,
    required double vndValue,
    required double feePercent,
    required Color feeColor,
    required AppColorsExtension colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: feeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Phí: ${feePercent.toStringAsFixed(3)}%',
                style: TextStyle(
                  color: feeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tỷ giá tham chiếu:',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            Text(
              '${NumberFormat('#,###.##').format(rateValue)} ₫',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Số tiền quy đổi:',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              _formatVnd(vndValue),
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
