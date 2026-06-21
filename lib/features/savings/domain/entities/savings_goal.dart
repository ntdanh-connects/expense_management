class SavingsGoalEntity {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String status;
  final String? autoSaveFrequency;
  final double? autoSaveAmount;
  final String? sourceWalletId;
  final String? sourceWalletName;
  final List<SavingsTransactionEntity>? transactions;

  SavingsGoalEntity({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.status,
    this.autoSaveFrequency,
    this.autoSaveAmount,
    this.sourceWalletId,
    this.sourceWalletName,
    this.transactions,
  });

  double get progressPercent {
    if (targetAmount <= 0) return 0.0;
    final percent = (currentAmount / targetAmount) * 100;
    return percent > 100 ? 100.0 : percent;
  }

  int get daysRemaining {
    if (targetDate == null) return 0;
    final nowLocal = DateTime.now();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final targetLocalDate = targetDate!.toLocal();
    final targetDay = DateTime(targetLocalDate.year, targetLocalDate.month, targetLocalDate.day);
    final difference = targetDay.difference(today).inDays;
    return difference < 0 ? 0 : difference;
  }
}

class SavingsTransactionEntity {
  final String id;
  final String savingsGoalId;
  final String type; // deposit, withdraw
  final double amount;
  final String sourceWalletId;
  final DateTime transactionDate;
  final String? notes;

  SavingsTransactionEntity({
    required this.id,
    required this.savingsGoalId,
    required this.type,
    required this.amount,
    required this.sourceWalletId,
    required this.transactionDate,
    this.notes,
  });
}
