import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/wallet/data/models/wallet_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_dto.g.dart';

@JsonSerializable()
class TransactionAttachmentDto {
  final String id;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @JsonKey(name: 'mime_type')
  final String? mimeType;

  TransactionAttachmentDto({
    required this.id,
    required this.fileUrl,
    this.mimeType,
  });

  factory TransactionAttachmentDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionAttachmentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionAttachmentDtoToJson(this);
}

@JsonSerializable()
class TransactionDto {
  final String id;
  @JsonKey(name: 'wallet_id')
  final String walletId;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  final String type;
  final String status;
  @JsonKey(fromJson: _amountFromJson)
  final double amount;
  @JsonKey(name: 'currency_code')
  final String? currencyCode;
  @JsonKey(name: 'exchange_rate', fromJson: _exchangeRateFromJson)
  final double? exchangeRate;
  final String title;
  final String? notes;
  final String? timezone;
  @JsonKey(name: 'source_type')
  final String? sourceType;
  @JsonKey(name: 'source_id')
  final String? sourceId;
  @JsonKey(name: 'transaction_date', fromJson: _dateTimeFromJson)
  final DateTime transactionDate;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime? createdAt;
  final CategoryDto? category;
  final WalletDto? wallet;
  final List<TransactionAttachmentDto>? attachments;

  @JsonKey(name: 'is_transfer_locked')
  final bool? isTransferLocked;
  @JsonKey(name: 'payee_id')
  final String? payeeId;
  final TransactionPayeeDto? payee;
  final TransactionSenderDto? sender;

  TransactionDto({
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
    required this.transactionDate,
    this.createdAt,
    this.category,
    this.wallet,
    this.attachments,
    this.isTransferLocked,
    this.payeeId,
    this.payee,
    this.sender,
  });

  static double _amountFromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _exchangeRateFromJson(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _dateTimeFromJson(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      if (!value.contains('Z') && !value.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(value)) {
        String formatted = value.replaceAll(' ', 'T');
        try {
          return DateTime.parse(formatted);
        } catch (_) {}
      }
      return DateTime.parse(value);
    }
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return DateTime.now();
  }

  factory TransactionDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionDtoToJson(this);
}

@JsonSerializable()
class TransactionPayeeDto {
  final String id;
  @JsonKey(name: 'payee_name')
  final String payeeName;
  @JsonKey(name: 'payee_type')
  final String payeeType;
  final String identifier;
  @JsonKey(name: 'bank_code')
  final String? bankCode;
  @JsonKey(name: 'bank_name')
  final String? bankName;

  TransactionPayeeDto({
    required this.id,
    required this.payeeName,
    required this.payeeType,
    required this.identifier,
    this.bankCode,
    this.bankName,
  });

  factory TransactionPayeeDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionPayeeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionPayeeDtoToJson(this);
}

@JsonSerializable()
class TransactionSenderDto {
  final String name;
  @JsonKey(name: 'wallet_name')
  final String? walletName;
  final String? identifier;

  TransactionSenderDto({
    required this.name,
    this.walletName,
    this.identifier,
  });

  factory TransactionSenderDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionSenderDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionSenderDtoToJson(this);
}
