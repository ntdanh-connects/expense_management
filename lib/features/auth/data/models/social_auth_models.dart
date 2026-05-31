import 'package:json_annotation/json_annotation.dart';
import 'auth_response_dto.dart';

part 'social_auth_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, checked: true)
class SocialLoginRequest {
  final String provider; // 'google' hoặc 'github'
  final String token;    // id_token hoặc access_token từ MXH

  SocialLoginRequest({required this.provider, required this.token});

  factory SocialLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SocialLoginRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, checked: true)
class LinkSocialRequest {
  final String linkToken; // Nhận được từ API login social
  final String password;  // Mật khẩu tài khoản thủ công của user

  LinkSocialRequest({required this.linkToken, required this.password});

  factory LinkSocialRequest.fromJson(Map<String, dynamic> json) =>
      _$LinkSocialRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LinkSocialRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, checked: true)
class SocialAuthResponse {
  final String status;         // 'success' hoặc 'requires_linking'
  final String message;
  final String? accessToken;   // Có khi đăng nhập thành công
  final String? refreshToken;  // Có khi đăng nhập thành công
  final String? linkToken;     // Trả về khi status == 'requires_linking'
  final String? email;         // Trả về khi status == 'requires_linking'
  final UserDataDto? data;     // User info khi đăng nhập thành công

  SocialAuthResponse({
    required this.status,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.linkToken,
    this.email,
    this.data,
  });

  factory SocialAuthResponse.fromJson(Map<String, dynamic> json) =>
      _$SocialAuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SocialAuthResponseToJson(this);
}
