import 'package:json_annotation/json_annotation.dart';

part 'wallet_dto.g.dart';

@JsonSerializable()
class WalletDto {
  final String id;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  @JsonKey(name: 'is_hidden')
  final bool? isHidden;
  @JsonKey(name: 'available_balance', fromJson: _balanceFromJson)
  final double availableBalance;
  @JsonKey(name: 'currency_code')
  final String? currencyCode;
  @JsonKey(name: 'is_default_receiving')
  final bool? isDefaultReceiving;
  @JsonKey(name: 'minimum_balance', fromJson: _balanceFromJson)
  final double? minimumBalance;
  @JsonKey(name: 'is_minimum_balance_alert_enabled')
  final bool? isMinimumBalanceAlertEnabled;

  WalletDto({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isHidden,
    required this.availableBalance,
    this.currencyCode,
    this.isDefaultReceiving,
    this.minimumBalance,
    this.isMinimumBalanceAlertEnabled,
  });

  static double _balanceFromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory WalletDto.fromJson(Map<String, dynamic> json) => _$WalletDtoFromJson(json);
  Map<String, dynamic> toJson() => _$WalletDtoToJson(this);
}