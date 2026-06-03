import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String fullName,
    String? avatarUrl,
    required String currency,
    required String language,
    required String theme,
    required String timezone,
  }) = _UserEntity;
}