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
  @JsonKey(name: 'available_balance')
  final String availableBalance;

  CreateWalletRequest({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isHidden,
    required this.availableBalance,
  });


  factory CreateWalletRequest.fromJson(Map<String, dynamic> json) => _$CreateWalletRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateWalletRequestToJson(this);
}