import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/profile/data/models/exchange_rates_dto.dart';
import 'package:expense_management/core/language/app_language.dart';

class VndToForeignConverterBottomSheet extends ConsumerStatefulWidget {
  const VndToForeignConverterBottomSheet({super.key});

  @override
  ConsumerState<VndToForeignConverterBottomSheet> createState() =>
      _VndToForeignConverterBottomSheetState();
}

class _VndToForeignConverterBottomSheetState
    extends ConsumerState<VndToForeignConverterBottomSheet> {
  late TextEditingController _amountController;
  double _vndAmount = 1000000.0; // Mặc định 1.000.000đ
  final Set<String> _expandedCurrencies = {};
  bool _isExplanationExpanded = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: NumberFormat('#,###').format(_vndAmount),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _getCurrencyFlag(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return '🇺🇸';
      case 'EUR':
        return '🇪🇺';
      case 'JPY':
        return '🇯🇵';
      case 'GBP':
        return '🇬🇧';
      case 'AUD':
        return '🇦🇺';
      case 'SGD':
        return '🇸🇬';
      case 'CAD':
        return '🇨🇦';
      case 'HKD':
        return '🇭🇰';
      case 'CHF':
        return '🇨🇭';
      case 'CNY':
        return '🇨🇳';
      case 'KRW':
        return '🇰🇷';
      case 'RUB':
        return '🇷🇺';
      case 'INR':
        return '🇮🇳';
      case 'THB':
        return '🇹🇭';
      case 'MYR':
        return '🇲🇾';
      case 'IDR':
        return '🇮🇩';
      default:
        return '🏳️';
    }
  }

  String _formatForeignCurrency(double value, String currencyCode) {
    final code = currencyCode.toUpperCase();
    if (code == 'JPY' || code == 'VND' || code == 'KRW') {
      return NumberFormat('#,###').format(value);
    }
    return NumberFormat('#,##0.00').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // ── THANH KÉO VÀ HEADER
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'currency_exchange'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quy đổi VND sang ngoại tệ khác',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // ── Ô NHẬP SỐ TIỀN VND
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhập số tiền Việt Nam (VND):',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            if (val.isEmpty) {
                              setState(() {
                                _vndAmount = 0.0;
                              });
                              return;
                            }
                            final cleanString = val.replaceAll(RegExp(r'[^0-9]'), '');
                            final double? amt = double.tryParse(cleanString);
                            if (amt != null) {
                              setState(() {
                                _vndAmount = amt;
                              });
                              final formatted = NumberFormat('#,###').format(amt);
                              _amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.fromPosition(
                                  TextPosition(offset: formatted.length),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      Text(
                        'VND',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── KẾT QUẢ QUY ĐỔI NGOẠI TỆ
          Expanded(
            child: ratesAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3.0),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: colors.expenseRed, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Không thể tải dữ liệu tỷ giá Vietcombank.',
                        style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              data: (ratesData) {
                final vcbRates = ratesData.vcbRates ?? {};
                final currenciesList =
                    vcbRates.entries.where((e) => e.key != 'VND').toList();

                if (currenciesList.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có dữ liệu tỷ giá ngoại tệ.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  );
                }

                // Sắp xếp các ngoại tệ phổ biến lên đầu
                final popularOrder = ['USD', 'EUR', 'JPY', 'GBP', 'AUD', 'SGD', 'CAD'];
                currenciesList.sort((a, b) {
                  final idxA = popularOrder.indexOf(a.key.toUpperCase());
                  final idxB = popularOrder.indexOf(b.key.toUpperCase());
                  if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
                  if (idxA != -1) return -1;
                  if (idxB != -1) return 1;
                  return a.key.compareTo(b.key);
                });

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: currenciesList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == currenciesList.length) {
                      // Chú thích cuối danh sách
                      return _buildExplanationCollapsible(colors);
                    }

                    final entry = currenciesList[index];
                    final currencyCode = entry.key;
                    final rateItem = entry.value;

                    final isExpanded = _expandedCurrencies.contains(currencyCode);

                    // Tính quy đổi dựa trên tỷ giá bán ra (Bán ngoại tệ từ bank cho khách)
                    final sellRate = rateItem.sell;
                    final convertedSell = sellRate > 0 ? (_vndAmount / sellRate) : 0.0;

                    // Tính quy đổi mua tiền mặt và mua chuyển khoản để đối chiếu
                    final buyCashRate = rateItem.buyCash;
                    final convertedBuyCash =
                        buyCashRate > 0 ? (_vndAmount / buyCashRate) : 0.0;

                    final buyTransferRate = rateItem.buyTransfer;
                    final convertedBuyTransfer =
                        buyTransferRate > 0 ? (_vndAmount / buyTransferRate) : 0.0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? colors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isExpanded
                              ? colors.primary.withOpacity(0.3)
                              : colors.textSecondary.withOpacity(0.06),
                          width: isExpanded ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCurrencies.remove(currencyCode);
                            } else {
                              _expandedCurrencies.add(currencyCode);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hàng tiêu đề của thẻ ngoại tệ
                              Row(
                                children: [
                                  // Flag/Logo tròn
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: colors.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      _getCurrencyFlag(currencyCode),
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Code & Tên
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currencyCode,
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          rateItem.currencyName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Số tiền quy đổi chính
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatForeignCurrency(
                                            convertedSell, currencyCode),
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tỷ giá: ${NumberFormat('#,###').format(sellRate)} ₫',
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: colors.textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),

                              // Chi tiết bảng so sánh khi bấm mở rộng card
                              if (isExpanded) ...[
                                const Divider(height: 24),
                                _buildDetailRateRow(
                                  label: 'Mua từ Bank (Tỷ giá Bán)',
                                  desc: 'Dùng VND đổi lấy ngoại tệ chuyển khoản/tiền mặt',
                                  rate: sellRate,
                                  amount: convertedSell,
                                  code: currencyCode,
                                  color: colors.primary,
                                  colors: colors,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRateRow(
                                  label: 'Bán Tiền mặt cho Bank (Tỷ giá Mua mặt)',
                                  desc: 'Đổi ngoại tệ tiền mặt của bạn lấy VND',
                                  rate: buyCashRate,
                                  amount: convertedBuyCash,
                                  code: currencyCode,
                                  color: colors.expenseRed,
                                  colors: colors,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRateRow(
                                  label: 'Bán CK cho Bank (Tỷ giá Mua CK)',
                                  desc: 'Chuyển khoản ngoại tệ của bạn lấy VND',
                                  rate: buyTransferRate,
                                  amount: convertedBuyTransfer,
                                  code: currencyCode,
                                  color: colors.incomeGreen,
                                  colors: colors,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRateRow({
    required String label,
    required String desc,
    required double rate,
    required double amount,
    required String code,
    required Color color,
    required AppColorsExtension colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            Text(
              'Tỷ giá: ${NumberFormat('#,###.##').format(rate)} ₫',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          desc,
          style: TextStyle(
            color: colors.textSecondary.withOpacity(0.8),
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Số tiền ngoại tệ nhận:',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${_formatForeignCurrency(amount, code)} $code',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExplanationCollapsible(AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExplanationExpanded = !_isExplanationExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lưu ý về tỷ giá Vietcombank áp dụng',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _isExplanationExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_isExplanationExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                '• Quy đổi hiển thị ở danh sách chính được tính dựa trên Tỷ giá Bán (Sell Rate) của Vietcombank. Đây là tỷ giá bạn cần trả để mua ngoại tệ từ ngân hàng.\n'
                '• Khi mở rộng từng mục, bạn sẽ thấy thêm Tỷ giá Mua tiền mặt và Mua chuyển khoản dùng để đối chiếu trong trường hợp bán ngoại tệ lấy VND.\n'
                '• Dữ liệu tỷ giá được đồng bộ và cập nhật tự động từ hệ thống Vietcombank mới nhất.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
