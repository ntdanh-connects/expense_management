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
    if(response != null){
      final message = response?.data['message'] ?? 'Đã xảy ra lỗi hệ thống';
      return NetworkFailure.serverError(code: response?.statusCode ?? 500, message: message);
    }

    return NetworkFailure.unknown(message: message ?? 'Lỗi không xác định');
  }

}