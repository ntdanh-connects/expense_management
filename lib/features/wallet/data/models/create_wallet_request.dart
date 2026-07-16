import 'package:json_annotation/json_annotation.dart';

part 'create_wallet_request.g.dart';

@JsonSerializable()
class CreateWalletRequest {
  final String name;
  final String type;
  final String icon;
  final String color;
  @JsonKey(name: 'is_hidden')
  final bool? isHidden;
  @JsonKey(name: 'available_balance', includeIfNull: false)
  final String? availableBalance;
  @JsonKey(name: 'currency_code')
  final String? currencyCode;
  @JsonKey(name: 'minimum_balance', includeIfNull: false)
  final double? minimumBalance;
  @JsonKey(name: 'is_minimum_balance_alert_enabled', includeIfNull: false)
  final bool? isMinimumBalanceAlertEnabled;

  CreateWalletRequest({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isHidden,
    this.availableBalance,
    this.currencyCode,
    this.minimumBalance,
    this.isMinimumBalanceAlertEnabled,
  });


  factory CreateWalletRequest.fromJson(Map<String, dynamic> json) => _$CreateWalletRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateWalletRequestToJson(this);
}