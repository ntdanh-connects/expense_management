import 'package:dio/dio.dart';
import 'package:expense_management/core/config/app_config.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/log_console_interceptor.dart';
import '../storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';


final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    RefreshTokenInterceptor(ref, dio),
    ErrorHandlingInterceptor(),
  ]);

  if (AppConfig.enableLogging) {
    dio.interceptors.add(LogConsoleInterceptor());
    dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
    ));
  }

  return dio;
});

class AuthInterceptor extends Interceptor {
  final Ref ref;
  AuthInterceptor(this.ref);

  String? _deviceType;
  String? _userAgent;

  // Khởi tạo thông tin thiết bị một lần duy nhất để tối ưu hóa hiệu năng (caching)
  Future<void> _initDeviceInfo() async {
    if (_deviceType != null && _userAgent != null) return;
    
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Lấy tên hãng + model (Ví dụ: Samsung SM-S918B)
        _userAgent = "${androidInfo.manufacturer} ${androidInfo.model}";
        _deviceType = "android";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Lấy tên iPhone (Ví dụ: iPhone 15 Pro)
        _userAgent = iosInfo.name;
        _deviceType = "ios";
      }
    } catch (e) {
      _userAgent = "Unknown Mobile";
      _deviceType = "mobile";
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Tự động lấy và đính kèm thông tin thiết bị
    await _initDeviceInfo();
    if (_deviceType != null) {
      options.headers['X-Device-Type'] = _deviceType;
    }
    if (_userAgent != null) {
      options.headers['User-Agent'] = _userAgent;
    }

    // 2. Lấy và đính kèm Access Token nếu có
    final storage = ref.read(secureStorageServiceProvider);
    final accessToken = await storage.get(key: AppConstant.accessToken);

    if(accessToken != null){
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }
}

class RefreshTokenInterceptor extends Interceptor {
  final Ref ref;
  final Dio mainDio;
  RefreshTokenInterceptor(this.ref, this.mainDio);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if(response.statusCode==200 && response.data is Map<String,dynamic>){
      final data = response.data as Map<String,dynamic>;
      final path = response.requestOptions.path;
      final isAuth = path.contains('login') || path.contains('register');
      if(isAuth){
        final hasError = data.containsKey('error') && data['error'] != null;
        final isMissingToken = path.contains('login') && !data.containsKey('access_token');
        
        if (hasError || isMissingToken) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: data['error'] ?? data['message'] ?? 'Thao tác thất bại rồi ní!',
            ),
          );
        }
      }
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final storage = ref.read(secureStorageServiceProvider);
      final refreshToken = await storage.get(key: AppConstant.refreshToken);
      final userId = await storage.get(key: AppConstant.userId);
      
      if (refreshToken != null) {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
          final response = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {
              'user_id': userId,
              'refresh_token': refreshToken
              },
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['access_token'];
            final newRefreshToken = response.data['refresh_token'];

            await storage.save(key: AppConstant.accessToken, value: newAccessToken);
            await storage.save(key: AppConstant.refreshToken, value: newRefreshToken);

            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryRequest = await mainDio.fetch(err.requestOptions);
            return handler.resolve(retryRequest);
          }
        } catch (refreshError) {
          await storage.clearAll();
          ref.read(authNotifierProvider.notifier).logout();
        }
      }
    }
    return handler.next(err); 
  }
}

class ErrorHandlingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = 'Đã xảy ra lỗi kết nối mạng, vui lòng thử lại sau ít phút';

    if (err.type == DioExceptionType.connectionTimeout || err.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Kết nối mạng quá hạn (Timeout). Vui lòng kiểm tra lại mạng internet của bạn !';
    } else if (err.response != null) {
      final responseData = err.response?.data;
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['error'] ?? responseData['message'] ?? errorMessage;
      }
    }

    // Trả ra một bản Exception có bọc thông báo tiếng Việt sạch sẽ
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: errorMessage,
      ),
    );
  }
}