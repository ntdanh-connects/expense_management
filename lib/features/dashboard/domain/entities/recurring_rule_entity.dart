class RecurringRuleEntity {
  final String id;
  final String userId;
  final String walletId;
  final String? categoryId;
  final String type; // income, expense
  final double amount;
  final String title;
  final String frequency; // daily, weekly, monthly, yearly
  final int intervalValue;
  final DateTime? startDate;
  final DateTime? nextRunAt;
  final DateTime? endAt;
  final bool isActive;

  // Helper fields (from joins)
  final String? walletName;
  final String? walletIcon;
  final String? walletColor;
  final String? walletCurrencyCode;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  RecurringRuleEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.title,
    required this.frequency,
    this.intervalValue = 1,
    this.startDate,
    this.nextRunAt,
    this.endAt,
    required this.isActive,
    this.walletName,
    this.walletIcon,
    this.walletColor,
    this.walletCurrencyCode,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      case 'yearly':
        return 'Hàng năm';
      default:
        return 'Hàng tháng';
    }
  }
}