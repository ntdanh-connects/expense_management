import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:expense_management/features/auth/data/models/auth_response_dto.dart'; // Nạp UserDataDto có sẵn của bạn

part 'update_profile_response_dto.freezed.dart';
part 'update_profile_response_dto.g.dart';

@freezed
abstract class UpdateProfileResponseDto with _$UpdateProfileResponseDto {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory UpdateProfileResponseDto({
    required String message,
    required UserDataDto data, // Tái sử dụng lại cấu trúc UserDataDto thô từ file Auth của bạn
  }) = _UpdateProfileResponseDto;

  factory UpdateProfileResponseDto.fromJson(Map<String, dynamic> json) => 
      _$UpdateProfileResponseDtoFromJson(json);
}