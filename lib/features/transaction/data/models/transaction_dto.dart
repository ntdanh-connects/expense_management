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
  @JsonKey(name: 'transaction_date', fromJson: _dateTimeFromJson)
  final DateTime transactionDate;
  final CategoryDto? category;
  final WalletDto? wallet;
  final List<TransactionAttachmentDto>? attachments;

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
    required this.transactionDate,
    this.category,
    this.wallet,
    this.attachments,
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
    if (value is String) return DateTime.parse(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return DateTime.now();
  }

  factory TransactionDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionDtoToJson(this);
}
