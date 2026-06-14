import 'package:expense_management/features/profile/domain/repositories/user_repository.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final changePasswordProvider = StateNotifierProvider<ChangePasswordNotifier, AsyncValue<void>>((ref) {
  final userRepository = ref.read(userRepositoryProvider); 
  return ChangePasswordNotifier(userRepository);
});

class ChangePasswordNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repository;

  ChangePasswordNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      // _repository.logoutAllDevices().then((_) {
      //   AppLogger.info("Đã gửi yêu cầu đăng xuất các thiết bị khác thành công.");
      // }).catchError((logoutError) {
      //   AppLogger.warning("Không thể dọn session thiết bị cũ (Chạy ngầm): $logoutError");
      // });

      state = const AsyncValue.data(null);
      return true; 
    } catch (e, stackTrace) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      
      state = AsyncValue.error(errorMsg, stackTrace);
      return false;
    }
  }
}