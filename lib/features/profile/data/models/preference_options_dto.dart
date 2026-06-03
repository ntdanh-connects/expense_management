import 'package:freezed_annotation/freezed_annotation.dart';

part 'preference_options_dto.freezed.dart';
part 'preference_options_dto.g.dart';

@freezed
abstract class PreferenceOptionsDto with _$PreferenceOptionsDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory PreferenceOptionsDto({
    required List<CurrencyOptionDto> currencies,
    required List<String> timezones,
    required List<LanguageOptionDto> languages,
    required List<ThemeOptionDto> themes,
  }) = _PreferenceOptionsDto;

  factory PreferenceOptionsDto.fromJson(Map<String, dynamic> json) =>
      _$PreferenceOptionsDtoFromJson(json);
}

@freezed
abstract class CurrencyOptionDto with _$CurrencyOptionDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory CurrencyOptionDto({
    required String code,
    required String name,
    required String symbol,
    required int decimal,
  }) = _CurrencyOptionDto;

  factory CurrencyOptionDto.fromJson(Map<String, dynamic> json) =>
      _$CurrencyOptionDtoFromJson(json);
}

@freezed
abstract class LanguageOptionDto with _$LanguageOptionDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory LanguageOptionDto({
    required String code,
    required String name,
  }) = _LanguageOptionDto;

  factory LanguageOptionDto.fromJson(Map<String, dynamic> json) =>
      _$LanguageOptionDtoFromJson(json);
}

@freezed
abstract class ThemeOptionDto with _$ThemeOptionDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory ThemeOptionDto({
    required String code,
    required String name,
  }) = _ThemeOptionDto;

  factory ThemeOptionDto.fromJson(Map<String, dynamic> json) =>
      _$ThemeOptionDtoFromJson(json);
}
