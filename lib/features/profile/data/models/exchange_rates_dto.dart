import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rates_dto.freezed.dart';
part 'exchange_rates_dto.g.dart';

@freezed
abstract class ExchangeRatesDto with _$ExchangeRatesDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory ExchangeRatesDto({
    required String base,
    required Map<String, double> rates,
  }) = _ExchangeRatesDto;

  factory ExchangeRatesDto.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRatesDtoFromJson(json);
}
