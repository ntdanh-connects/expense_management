import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rates_dto.freezed.dart';
part 'exchange_rates_dto.g.dart';

@freezed
abstract class VcbRateItemDto with _$VcbRateItemDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory VcbRateItemDto({
    required String currencyCode,
    required String currencyName,
    required double buyCash,
    required double buyTransfer,
    required double sell,
    required double mid,
    required double buyCashFeePercent,
    required double buyTransferFeePercent,
    required double sellFeePercent,
  }) = _VcbRateItemDto;

  factory VcbRateItemDto.fromJson(Map<String, dynamic> json) =>
      _$VcbRateItemDtoFromJson(json);
}

@freezed
abstract class ExchangeRatesDto with _$ExchangeRatesDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory ExchangeRatesDto({
    required String base,
    required Map<String, double> rates,
    Map<String, VcbRateItemDto>? vcbRates,
  }) = _ExchangeRatesDto;

  factory ExchangeRatesDto.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRatesDtoFromJson(json);
}
