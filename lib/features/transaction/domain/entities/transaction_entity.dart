
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
  final String? sourceId;
  final bool isTransferLocked;
  final DateTime transactionDate;
  final DateTime? createdAt;
  
  // Custom helper fields populated from joins
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? walletName;
  final String? walletIcon;
  final String? walletColor;
  final List<String> attachmentUrls;

  // Beneficiary fields
  final String? payeeId;
  final String? payeeName;
  final String? payeeAccountNumber;
  final String? payeeBankName;

  // Payer/Sender fields (for income transactions)
  final String? senderName;
  final String? senderWalletName;
  final String? senderIdentifier;

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
    this.sourceId,
    this.isTransferLocked = false,
    required this.transactionDate,
    this.createdAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.walletName,
    this.walletIcon,
    this.walletColor,
    this.attachmentUrls = const [],
    this.payeeId,
    this.payeeName,
    this.payeeAccountNumber,
    this.payeeBankName,
    this.senderName,
    this.senderWalletName,
    this.senderIdentifier,
  });

  bool get isIncome => type == 'income';

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    final payee = json['payee'] as Map<String, dynamic>?;
    final sender = json['sender'] as Map<String, dynamic>?;
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
      sourceId: json['source_id'] as String?,
      isTransferLocked: json['is_transfer_locked'] as bool? ?? false,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
      walletName: json['wallet_name'] as String?,
      walletIcon: json['wallet_icon'] as String?,
      walletColor: json['wallet_color'] as String?,
      attachmentUrls: List<String>.from(json['attachment_urls'] ?? []),
      payeeId: json['payee_id'] as String?,
      payeeName: payee != null ? payee['payee_name'] as String? : null,
      payeeAccountNumber: payee != null ? payee['identifier'] as String? : null,
      payeeBankName: payee != null ? payee['bank_name'] as String? : null,
      senderName: sender != null ? sender['name'] as String? : null,
      senderWalletName: sender != null ? sender['wallet_name'] as String? : null,
      senderIdentifier: sender != null ? sender['identifier'] as String? : null,
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
      'source_id': sourceId,
      'is_transfer_locked': isTransferLocked,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'category_color': categoryColor,
      'wallet_name': walletName,
      'wallet_icon': walletIcon,
      'wallet_color': walletColor,
      'attachment_urls': attachmentUrls,
      'payee_id': payeeId,
      'payee': payeeId != null ? {
        'id': payeeId,
        'payee_name': payeeName,
        'identifier': payeeAccountNumber,
        'bank_name': payeeBankName,
      } : null,
      'sender': senderName != null ? {
        'name': senderName,
        'wallet_name': senderWalletName,
        'identifier': senderIdentifier,
      } : null,
    };
  }

  TransactionEntity copyWith({
    String? id,
    String? walletId,
    String? categoryId,
    String? type,
    String? status,
    double? amount,
    String? currencyCode,
    double? exchangeRate,
    String? title,
    String? notes,
    String? timezone,
    String? sourceType,
    String? sourceId,
    bool? isTransferLocked,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? walletName,
    String? walletIcon,
    String? walletColor,
    List<String>? attachmentUrls,
    String? payeeId,
    String? payeeName,
    String? payeeAccountNumber,
    String? payeeBankName,
    String? senderName,
    String? senderWalletName,
    String? senderIdentifier,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      timezone: timezone ?? this.timezone,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isTransferLocked: isTransferLocked ?? this.isTransferLocked,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      walletName: walletName ?? this.walletName,
      walletIcon: walletIcon ?? this.walletIcon,
      walletColor: walletColor ?? this.walletColor,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      payeeId: payeeId ?? this.payeeId,
      payeeName: payeeName ?? this.payeeName,
      payeeAccountNumber: payeeAccountNumber ?? this.payeeAccountNumber,
      payeeBankName: payeeBankName ?? this.payeeBankName,
      senderName: senderName ?? this.senderName,
      senderWalletName: senderWalletName ?? this.senderWalletName,
      senderIdentifier: senderIdentifier ?? this.senderIdentifier,
    );
  }
}
