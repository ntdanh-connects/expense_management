import 'package:expense_management/core/network/network_failure.dart';

class AppException implements Exception{
  final NetworkFailure failure;
  AppException(this.failure);

  @override
  String toString() {
    return failure.when(
      serverError:  (code, message) => message,
      noInternet: () => 'Không có kết nối Internet',
      timeout: () => 'Kết nối quá hạn, vui lòng thử lại sau...',
      unauthorized: () => 'Phiên đăng nhập hết hạn hoặc không hợp lệ',
      unknown: (message) => message
    );
  }

}