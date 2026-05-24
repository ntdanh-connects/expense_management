import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_request_dto.freezed.dart';
part 'register_request_dto.g.dart';

@freezed
abstract class RegisterRequestDto with _$RegisterRequestDto {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory RegisterRequestDto({
    required String fullName, 
    required String email,
    required String password,
    required String passwordConfirmation
  }) = _RegisterRequestDto;

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) => 
      _$RegisterRequestDtoFromJson(json);
}