
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response_dto.g.dart';
part 'auth_response_dto.freezed.dart';

@freezed
abstract class AuthResponseDto with _$AuthResponseDto{
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory AuthResponseDto({
    required String message,
    required String accessToken,   
    required String refreshToken,  
    required String tokenType,     
    required UserDataDto data,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) => 
      _$AuthResponseDtoFromJson(json);
}

@freezed
abstract class UserDataDto with _$UserDataDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory UserDataDto({
    required String userId,        
    required String email,
    required String status,
    required UserProfileDto profile,
    required UserPreferenceDto preference,
  }) = _UserDataDto;

  factory UserDataDto.fromJson(Map<String, dynamic> json) => 
      _$UserDataDtoFromJson(json);
}

@freezed
abstract class UserProfileDto with _$UserProfileDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory UserProfileDto({required String fullName, String? avatarUrl}) = _UserProfileDto;
  factory UserProfileDto.fromJson(Map<String, dynamic> json) => _$UserProfileDtoFromJson(json);
}

@freezed
abstract class UserPreferenceDto with _$UserPreferenceDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory UserPreferenceDto({
    required String language,
    required String theme,
    required String currency,
    required String timezone,
    int? financialStartDay,
  }) = _UserPreferenceDto;

  factory UserPreferenceDto.fromJson(Map<String, dynamic> json) => 
      _$UserPreferenceDtoFromJson(json);
}