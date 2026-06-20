import 'package:json_annotation/json_annotation.dart';

part 'report_wallet_dto.g.dart';

@JsonSerializable()
class ReportWalletEntryDto {
  @JsonKey(name: 'wallet_id')
  final String walletId;
  @JsonKey(name: 'wallet_name')
  final String walletName;
  @JsonKey(name: 'wallet_color')
  final String walletColor;
  @JsonKey(name: 'wallet_icon')
  final String walletIcon;
  final double amount;
  final double percentage;

  ReportWalletEntryDto({
    required this.walletId,
    required this.walletName,
    required this.walletColor,
    required this.walletIcon,
    required this.amount,
    required this.percentage,
  });

  factory ReportWalletEntryDto.fromJson(Map<String, dynamic> json) => _$ReportWalletEntryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReportWalletEntryDtoToJson(this);
}

@JsonSerializable()
class ReportWalletDto {
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  final List<ReportWalletEntryDto> wallets;

  ReportWalletDto({
    required this.totalAmount,
    required this.wallets,
  });

  factory ReportWalletDto.fromJson(Map<String, dynamic> json) {
    final rawWallets = json['wallets'];
    List<dynamic> walletsList = [];
    if (rawWallets is List) {
      walletsList = rawWallets;
    } else if (rawWallets is Map) {
      walletsList = rawWallets.values.toList();
    }
    return ReportWalletDto(
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      wallets: walletsList
          .map((e) => ReportWalletEntryDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => _$ReportWalletDtoToJson(this);
}
