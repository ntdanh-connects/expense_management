import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _selectedInputCurrency = 'VND';
  double _inputAmount = 1000000.0; // Mặc định 1.000.000đ
  final Set<String> _expandedCurrencies = {};
  bool _isExplanationExpanded = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _formatInputAmount(_inputAmount, _selectedInputCurrency),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool _isDecimalCurrency(String code) {
    final c = code.toUpperCase();
    return c != 'VND' && c != 'JPY' && c != 'KRW';
  }

  double? _parseLocaleSafeDouble(String val) {
    if (val.isEmpty) return null;

    final lastDot = val.lastIndexOf('.');
    final lastComma = val.lastIndexOf(',');

    if (lastDot == -1 && lastComma == -1) {
      return double.tryParse(val);
    }

    if (lastDot > lastComma) {
      // '.' is the decimal separator (e.g. 1,234.56)
      final clean = val.replaceAll(',', '');
      return double.tryParse(clean);
    } else {
      // ',' is the decimal separator (e.g. 1.234,56)
      final clean = val.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(clean);
    }
  }

  String _formatInputAmount(double value, String currencyCode) {
    if (_isDecimalCurrency(currencyCode)) {
      return NumberFormat('0.00', 'en_US').format(value);
    }
    return NumberFormat('#,###', 'en_US').format(value);
  }

  String _getCurrencyFlag(String code) {
    switch (code.toUpperCase()) {
      case 'VND':
        return '🇻🇳';
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
    if (!_isDecimalCurrency(currencyCode)) {
      return NumberFormat('#,###').format(value);
    }
    return NumberFormat('#,##0.00').format(value);
  }

  void _onAmountChanged(String val) {
    if (val.isEmpty) {
      setState(() {
        _inputAmount = 0.0;
      });
      return;
    }

    if (!_isDecimalCurrency(_selectedInputCurrency)) {
      // Non-decimal currency logic (VND, JPY, KRW)
      final cleanString = val.replaceAll(RegExp(r'[^0-9]'), '');
      final double? amt = double.tryParse(cleanString);
      if (amt != null) {
        setState(() {
          _inputAmount = amt;
        });
        final formatted = NumberFormat('#,###', 'en_US').format(amt);
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.fromPosition(
            TextPosition(offset: formatted.length),
          ),
        );
      }
    } else {
      // Decimal currency logic (USD, EUR, GBP, etc.)
      final double? amt = _parseLocaleSafeDouble(val);
      if (amt != null) {
        setState(() {
          _inputAmount = amt;
        });
      }
    }
  }

  void _changeInputCurrency(String newCurrency, Map<String, VcbRateItemDto> vcbRates) {
    if (newCurrency == _selectedInputCurrency) return;
    
    // Calculate the equivalent amount in the new currency
    double currentVnd = _inputAmount * (_selectedInputCurrency == 'VND' ? 1.0 : (vcbRates[_selectedInputCurrency]?.sell ?? 1.0));
    double newAmount = newCurrency == 'VND' ? currentVnd : (currentVnd / (vcbRates[newCurrency]?.sell ?? 1.0));
    
    setState(() {
      _selectedInputCurrency = newCurrency;
      _inputAmount = newAmount;
      _expandedCurrencies.remove(newCurrency);
      _amountController.text = _formatInputAmount(newAmount, newCurrency);
    });
  }

  void _showCurrencySelector(
      BuildContext context, Map<String, VcbRateItemDto> vcbRates, List<String> allCurrencies) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              const SizedBox(height: 16),
              Text(
                'Chọn đồng tiền nhập',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allCurrencies.length,
                  itemBuilder: (context, idx) {
                    final curr = allCurrencies[idx];
                    final isSelected = curr == _selectedInputCurrency;
                    final flag = _getCurrencyFlag(curr);
                    final name = curr == 'VND' ? 'Việt Nam Đồng' : (vcbRates[curr]?.currencyName ?? '');
                    
                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 24)),
                      title: Text(curr, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                      subtitle: Text(name, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: colors.primary) : null,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                        _changeInputCurrency(curr, vcbRates);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                          'Quy đổi ngoại tệ và VND thời gian thực',
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

          // ── Ô NHẬP SỐ TIỀN VÀ CHỌN NGOẠI TỆ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhập số tiền quy đổi:',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ratesAsync.when(
                  loading: () => Container(height: 56, color: Colors.transparent),
                  error: (_, __) => Container(height: 56, color: Colors.transparent),
                  data: (ratesData) {
                    final vcbRates = ratesData.vcbRates ?? {};
                    final allCurrencies = ['VND', ...vcbRates.keys.where((k) => k != 'VND')];
                    final popularOrder = ['VND', 'USD', 'EUR', 'JPY', 'GBP', 'AUD', 'SGD', 'CAD'];
                    allCurrencies.sort((a, b) {
                      final idxA = popularOrder.indexOf(a.toUpperCase());
                      final idxB = popularOrder.indexOf(b.toUpperCase());
                      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
                      if (idxA != -1) return -1;
                      if (idxB != -1) return 1;
                      return a.compareTo(b);
                    });

                    return Container(
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
                          // Dropdown chọn ngoại tệ đầu vào
                          InkWell(
                            onTap: () => _showCurrencySelector(context, vcbRates, allCurrencies),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Row(
                                children: [
                                  Text(
                                    _getCurrencyFlag(_selectedInputCurrency),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedInputCurrency,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: colors.textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: colors.textSecondary.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                              onChanged: _onAmountChanged,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                final allCurrencies = ['VND', ...vcbRates.keys.where((k) => k != 'VND')];
                final popularOrder = ['VND', 'USD', 'EUR', 'JPY', 'GBP', 'AUD', 'SGD', 'CAD'];
                allCurrencies.sort((a, b) {
                  final idxA = popularOrder.indexOf(a.toUpperCase());
                  final idxB = popularOrder.indexOf(b.toUpperCase());
                  if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
                  if (idxA != -1) return -1;
                  if (idxB != -1) return 1;
                  return a.compareTo(b);
                });

                // Các đồng tiền được quy đổi là các đồng tiền khác đồng tiền đang nhập
                final displayCurrencies =
                    allCurrencies.where((c) => c != _selectedInputCurrency).toList();

                if (displayCurrencies.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có dữ liệu tỷ giá ngoại tệ.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: displayCurrencies.length + 1,
                  itemBuilder: (context, index) {
                    if (index == displayCurrencies.length) {
                      return _buildExplanationCollapsible(colors);
                    }

                    final currencyCode = displayCurrencies[index];
                    final isExpanded = _expandedCurrencies.contains(currencyCode);

                    // 1. Lấy thông tin tỷ giá của đồng tiền đầu vào
                    final inputRateItem = vcbRates[_selectedInputCurrency];
                    // 2. Lấy thông tin tỷ giá của đồng tiền đích
                    final targetRateItem = vcbRates[currencyCode];

                    // Tỷ giá quy đổi (VND cho 1 đơn vị tiền tệ)
                    final inputSell = _selectedInputCurrency == 'VND' ? 1.0 : (inputRateItem?.sell ?? 0.0);
                    final inputBuyCash = _selectedInputCurrency == 'VND' ? 1.0 : (inputRateItem?.buyCash ?? 0.0);
                    final inputBuyTransfer = _selectedInputCurrency == 'VND' ? 1.0 : (inputRateItem?.buyTransfer ?? 0.0);

                    final targetSell = currencyCode == 'VND' ? 1.0 : (targetRateItem?.sell ?? 0.0);
                    final targetBuyCash = currencyCode == 'VND' ? 1.0 : (targetRateItem?.buyCash ?? 0.0);
                    final targetBuyTransfer = currencyCode == 'VND' ? 1.0 : (targetRateItem?.buyTransfer ?? 0.0);

                    // Quy đổi từ input sang target qua trung gian VND
                    final double convertedSell;
                    if (targetSell > 0) {
                      final inputVnd = _inputAmount * inputSell;
                      convertedSell = inputVnd / targetSell;
                    } else {
                      convertedSell = 0.0;
                    }

                    final double convertedBuyCash;
                    if (targetBuyCash > 0) {
                      final inputVnd = _inputAmount * inputBuyCash;
                      convertedBuyCash = inputVnd / targetBuyCash;
                    } else {
                      convertedBuyCash = 0.0;
                    }

                    final double convertedBuyTransfer;
                    if (targetBuyTransfer > 0) {
                      final inputVnd = _inputAmount * inputBuyTransfer;
                      convertedBuyTransfer = inputVnd / targetBuyTransfer;
                    } else {
                      convertedBuyTransfer = 0.0;
                    }

                    // Tên hiển thị của đồng tiền đích
                    final targetName = currencyCode == 'VND' ? 'Việt Nam Đồng' : (targetRateItem?.currencyName ?? '');

                    // Tính tỷ giá chéo (bao nhiêu đồng tiền đích đổi được 1 đồng tiền nguồn)
                    String exchangeRateText = '';
                    if (_selectedInputCurrency == 'VND') {
                      exchangeRateText = 'Tỷ giá: ${NumberFormat('#,###.##').format(targetSell)} ₫';
                    } else if (currencyCode == 'VND') {
                      exchangeRateText = 'Tỷ giá: ${NumberFormat('#,###.##').format(inputSell)} ₫';
                    } else {
                      if (targetSell > 0) {
                        final crossRate = inputSell / targetSell;
                        exchangeRateText = '1 $_selectedInputCurrency ≈ ${NumberFormat('#,##0.####').format(crossRate)} $currencyCode';
                      }
                    }

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
                              Row(
                                children: [
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          targetName,
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
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatForeignCurrency(convertedSell, currencyCode),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          exchangeRateText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
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
                              if (isExpanded) ...[
                                const Divider(height: 24),
                                _buildDetailRateRow(
                                  label: 'Mua từ Bank (Tỷ giá Bán)',
                                  desc: 'Dùng $_selectedInputCurrency đổi lấy $currencyCode theo tỷ giá Bán ra của ngân hàng',
                                  rate: targetSell,
                                  amount: convertedSell,
                                  code: currencyCode,
                                  color: colors.primary,
                                  colors: colors,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRateRow(
                                  label: 'Bán Tiền mặt cho Bank (Tỷ giá Mua mặt)',
                                  desc: 'Đổi $currencyCode mặt lấy $_selectedInputCurrency theo tỷ giá Mua tiền mặt',
                                  rate: targetBuyCash,
                                  amount: convertedBuyCash,
                                  code: currencyCode,
                                  color: colors.expenseRed,
                                  colors: colors,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRateRow(
                                  label: 'Bán CK cho Bank (Tỷ giá Mua CK)',
                                  desc: 'Đổi $currencyCode chuyển khoản lấy $_selectedInputCurrency theo tỷ giá Mua chuyển khoản',
                                  rate: targetBuyTransfer,
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
    final showRateText = code == 'VND'
        ? ''
        : 'Tỷ giá: ${NumberFormat('#,###.##').format(rate)} ₫';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (showRateText.isNotEmpty)
              Text(
                showRateText,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Số tiền nhận được:',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
                      'Lưu ý về tỷ giá quy đổi áp dụng',
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
                '• Quy đổi ở danh sách chính được tính dựa trên Tỷ giá Bán (Sell Rate) hoặc tỷ giá chéo quy đổi giữa các ngoại tệ qua đồng VND.\n'
                '• Khi mở rộng từng mục, bạn sẽ thấy thêm chi tiết theo Tỷ giá Mua tiền mặt và Mua chuyển khoản để dễ dàng đối chiếu.\n'
                '• Tỷ giá chéo được tính toán tự động dựa trên tỷ giá của ngân hàng Vietcombank cập nhật thời gian thực.',
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
