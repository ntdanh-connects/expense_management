import 'package:dio/dio.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/utils/app_logger.dart';

mixin ErrorHandlerMixin {
  String getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.toString();
    }
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        return responseData['message'] ?? responseData['error'] ?? error.message ?? error.toString();
      }
      return error.message ?? error.toString();
    }
    return error.toString();
  }

  void logException(dynamic error, StackTrace? stackTrace, {String? tag}) {
    final message = getErrorMessage(error);
    AppLogger.error("🚨 [$tag] Lỗi xảy ra: $message", tag: tag ?? 'ErrorHandler', stackTrace: stackTrace);
  }
}
