import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';

class SavingsGoalDto {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? targetDate;
  final String status;
  final String? autoSaveFrequency;
  final double? autoSaveAmount;
  final String? sourceWalletId;
  final String? sourceWalletName;
  final List<SavingsTransactionDto>? transactions;

  SavingsGoalDto({
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

  static double _doubleFromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory SavingsGoalDto.fromJson(Map<String, dynamic> json) {
    // Parse nested source_wallet if any
    String? sourceWalletName;
    if (json['source_wallet'] != null && json['source_wallet'] is Map) {
      sourceWalletName = json['source_wallet']['name']?.toString();
    }

    // Parse transactions
    List<SavingsTransactionDto>? transactionsList;
    if (json['transactions'] != null && json['transactions'] is List) {
      transactionsList = (json['transactions'] as List)
          .map((t) => SavingsTransactionDto.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return SavingsGoalDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      targetAmount: _doubleFromJson(json['target_amount']),
      currentAmount: _doubleFromJson(json['current_amount']),
      targetDate: json['target_date']?.toString(),
      status: json['status']?.toString() ?? 'active',
      autoSaveFrequency: json['auto_save_frequency']?.toString(),
      autoSaveAmount: json['auto_save_amount'] != null
          ? _doubleFromJson(json['auto_save_amount'])
          : null,
      sourceWalletId: json['source_wallet_id']?.toString(),
      sourceWalletName: sourceWalletName,
      transactions: transactionsList,
    );
  }

  SavingsGoalEntity toEntity() {
    DateTime? parsedTargetDate;
    if (targetDate != null) {
      parsedTargetDate = DateTime.tryParse(targetDate!);
    }

    return SavingsGoalEntity(
      id: id,
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: parsedTargetDate,
      status: status,
      autoSaveFrequency: autoSaveFrequency,
      autoSaveAmount: autoSaveAmount,
      sourceWalletId: sourceWalletId,
      sourceWalletName: sourceWalletName,
      transactions: transactions?.map((t) => t.toEntity()).toList(),
    );
  }
}

class SavingsTransactionDto {
  final String id;
  final String savingsGoalId;
  final String type;
  final double amount;
  final String sourceWalletId;
  final String transactionDate;
  final String? notes;

  SavingsTransactionDto({
    required this.id,
    required this.savingsGoalId,
    required this.type,
    required this.amount,
    required this.sourceWalletId,
    required this.transactionDate,
    this.notes,
  });

  static double _doubleFromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory SavingsTransactionDto.fromJson(Map<String, dynamic> json) {
    return SavingsTransactionDto(
      id: json['id']?.toString() ?? '',
      savingsGoalId: json['savings_goal_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'deposit',
      amount: _doubleFromJson(json['amount']),
      sourceWalletId: json['source_wallet_id']?.toString() ?? '',
      transactionDate: json['transaction_date']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  static DateTime _parseDateTime(String value) {
    if (value.isEmpty) return DateTime.now();
    if (!value.contains('Z') && !value.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(value)) {
      String formatted = value;
      if (formatted.contains(' ')) {
        formatted = formatted.replaceAll(' ', 'T');
      }
      formatted = '${formatted}Z';
      try {
        return DateTime.parse(formatted);
      } catch (_) {}
    }
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  SavingsTransactionEntity toEntity() {
    return SavingsTransactionEntity(
      id: id,
      savingsGoalId: savingsGoalId,
      type: type,
      amount: amount,
      sourceWalletId: sourceWalletId,
      transactionDate: _parseDateTime(transactionDate),
      notes: notes,
    );
  }
}
