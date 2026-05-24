
import 'package:expense_management/features/auth/domain/entities/user_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = _Unauthenticated;

  // 2. Trạng thái đang gửi request lên Laravel (UI sẽ bật Skeleton/Shimmer hoặc khóa nút bấm)
  const factory AuthState.authenticating() = _Authenticating;

  // 3. Đăng nhập thành công, ôm cục dữ liệu người dùng sạch (UserEntity) để UI hốt xài
  const factory AuthState.authenticated({required UserEntity user}) = _Authenticated;

  // 4. Đăng nhập thất bại, ôm chuỗi thông báo lỗi Tiếng Việt sạch từ Core Dio nhổ ra
  const factory AuthState.error({required String message}) = _Error;

  const factory AuthState.registered({String? message}) = _Registered;
}