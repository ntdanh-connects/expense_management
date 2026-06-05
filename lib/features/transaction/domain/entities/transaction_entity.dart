class TransactionEntity {
  final String id;
  final String walletId;
  final String? categoryId;
  final String type; // income, expense
  final String status;
  final double amount;
  final String? currencyCode;
  final double? exchangeRate;
  final String title;
  final String? notes;
  final String? timezone;
  final String? sourceType;
  final DateTime transactionDate;
  
  // Custom helper fields populated from joins
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? walletName;
  final String? walletIcon;
  final String? walletColor;
  final List<String> attachmentUrls;

  TransactionEntity({
    required this.id,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.status,
    required this.amount,
    this.currencyCode,
    this.exchangeRate,
    required this.title,
    this.notes,
    this.timezone,
    this.sourceType,
    required this.transactionDate,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.walletName,
    this.walletIcon,
    this.walletColor,
    this.attachmentUrls = const [],
  });

  bool get isIncome => type == 'income';

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      categoryId: json['category_id'] as String?,
      type: json['type'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currency_code'] as String?,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble(),
      title: json['title'] as String,
      notes: json['notes'] as String?,
      timezone: json['timezone'] as String?,
      sourceType: json['source_type'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
      walletName: json['wallet_name'] as String?,
      walletIcon: json['wallet_icon'] as String?,
      walletColor: json['wallet_color'] as String?,
      attachmentUrls: List<String>.from(json['attachment_urls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type,
      'status': status,
      'amount': amount,
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
      'title': title,
      'notes': notes,
      'timezone': timezone,
      'source_type': sourceType,
      'transaction_date': transactionDate.toIso8601String(),
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'category_color': categoryColor,
      'wallet_name': walletName,
      'wallet_icon': walletIcon,
      'wallet_color': walletColor,
      'attachment_urls': attachmentUrls,
    };
  }
}
