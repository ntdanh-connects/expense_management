import 'package:flutter_test/flutter_test.dart';
import 'package:expense_management/core/constants/app_constant.dart';

void main() {
  group('AppConstant Tests', () {
    test('formatMoney formats VND correctly without decimals', () {
      expect(AppConstant.formatMoney(1000000, 'VND'), '1.000.000');
      expect(AppConstant.formatMoney(500, 'VND'), '500');
      expect(AppConstant.formatMoney(0, 'VND'), '0');
    });

    test('formatMoney formats USD correctly with decimals', () {
      expect(AppConstant.formatMoney(1234.56, 'USD'), '1,234.56');
      expect(AppConstant.formatMoney(0.5, 'USD'), '0.50');
      expect(AppConstant.formatMoney(1000, 'USD'), '1,000.00');
    });

    test('getCurrencySymbol returns correct symbols', () {
      expect(AppConstant.getCurrencySymbol('VND'), 'đ');
      expect(AppConstant.getCurrencySymbol('USD'), '\$');
      expect(AppConstant.getCurrencySymbol('EUR'), '€');
      expect(AppConstant.getCurrencySymbol('JPY'), '¥');
      expect(AppConstant.getCurrencySymbol('GBP'), '£');
      expect(AppConstant.getCurrencySymbol(null), 'đ');
    });
  });
}
