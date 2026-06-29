import 'package:flutter/material.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_card.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/constants/app_constant.dart';

class TransactionDaySection extends StatelessWidget {
  final MapEntry<String, List<TransactionEntity>> group;
  final String userCurrency;
  final String currencySymbol;
  final dynamic ratesData;

  const TransactionDaySection({
    super.key,
    required this.group,
    required this.userCurrency,
    required this.currencySymbol,
    required this.ratesData,
  });

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
      'USD': 1.0,
      'VND': 25400.0,
      'EUR': 0.92,
      'GBP': 0.78,
      'JPY': 156.0,
    };

    final base = (ratesData?.base ?? 'USD').toUpperCase();
    final rates = ratesData?.rates.map(
          (k, v) => MapEntry(k.toUpperCase(), v.toDouble()),
        ) ??
        fallbackRates;

    final fromRate = from == base ? 1.0 : (rates[from] ?? 1.0);
    final toRate = to == base ? 1.0 : (rates[to] ?? 1.0);

    return amount * (toRate / fromRate);
  }

  String _fmt(double value, String currencyCode) {
    return AppConstant.formatMoney(value, currencyCode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final txList = group.value;

    double dayIncome = 0;
    double dayExpense = 0;

    for (final tx in txList) {
      if (tx.sourceType == 'transfer') {
        final hasCounterpart = tx.sourceId != null &&
            txList.any((other) =>
                other.id != tx.id &&
                other.sourceId == tx.sourceId &&
                other.walletId != tx.walletId);
        if (hasCounterpart) continue;
      }
      final txCurrency = (tx.currencyCode ?? 'VND').toUpperCase();

      final converted = _convertToUserCurrency(
        tx.amount,
        txCurrency,
        userCurrency,
        ratesData,
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
}
