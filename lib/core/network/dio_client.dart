import 'package:dio/dio.dart';
import 'package:expense_management/core/config/app_config.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioClientProvider = Provider<Dio>((ref){
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    )
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async{
        final storage = ref.read(secureStorageServiceProvider);
        final token = await storage.get(key: AppConstant.accessToken);

        if(token != null){
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },

      onError: (DioException e, handler) async{
        if(e.response?.statusCode == 401) {
          final prefs = ref.read(secureStorageServiceProvider);
          final refreshToken = await prefs.get(key: AppConstant.refreshToken);
          
          if(refreshToken != null){
            try{
              final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
              final respone = await refreshDio.post(
                ApiEndpoints.refreshToken,
                data: {'refresh_token': refreshToken}
              );
              if(respone.statusCode==200){
                final newAccessToken = respone.data['access_token'];
                final newRefreshToken = respone.data['refresh_token'];

                await prefs.save(key: AppConstant.accessToken, value: newAccessToken);
                await prefs.save(key: AppConstant.refreshToken, value: newRefreshToken);

                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                final retryRequest = await dio.request(
                  e.requestOptions.path,
                  options: Options(
                    method:e.requestOptions.method,
                    headers: e.requestOptions.headers
                  ),
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters
                );
                return handler.resolve(retryRequest);
              }
            }catch (RefreshError){
              //clear storage
              //Return user LoginScreen
            }
          }
        }

        String errorMessage = 'Đã xảy ra lỗi kết nối mạng vui lòng thử lại nè !';

        if(e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout){
          errorMessage = 'Kết nối mạng quá hạn (Timeout). Vui lòng kiểm tra lại internet!';
        }else if(e.response != null){
          final responseData = e.response?.data;
          if(responseData is Map<String, dynamic>){
            errorMessage = responseData['message'] ?? errorMessage;
          }
        }
        return handler.reject(
          DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: errorMessage
          )
        );
      },
    )
  );
  if (AppConfig.enableLogging) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
  return dio;
});
