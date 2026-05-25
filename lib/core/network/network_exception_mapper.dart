import 'package:dio/dio.dart';
import 'package:expense_management/core/network/network_failure.dart';

extension DioExceptionMapper on DioException{
  NetworkFailure toNetworkFailure(){
    if(type == DioExceptionType.connectionTimeout || type == DioExceptionType.receiveTimeout){
      return const NetworkFailure.timeout();
    }

    final isAuthRequest = requestOptions.path.contains('login') || requestOptions.path.contains('register');
    if (response?.statusCode == 401 && !isAuthRequest) {
      return const NetworkFailure.unauthorized();
    }
    if (response != null) {
      String errorMessage = 'Đã xảy ra lỗi hệ thống';
      final responseData = response?.data;
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['error'] ?? responseData['message'] ?? errorMessage;
      } else if (responseData is String) {
        errorMessage = responseData;
      } else if (error is String) {
        errorMessage = error as String;
      }
      return NetworkFailure.serverError(code: response?.statusCode ?? 500, message: errorMessage);
    }

    return NetworkFailure.unknown(message: message ?? 'Lỗi không xác định');
  }

}