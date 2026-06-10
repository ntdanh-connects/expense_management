import 'dart:async';
import 'package:dio/dio.dart';
import 'package:expense_management/core/config/app_config.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/log_console_interceptor.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import '../storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/auth/auth_provider.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


final cacheStoreProvider = Provider<CacheStore>((ref) {
  throw UnimplementedError('cacheStoreProvider must be overridden in ProviderScope');
});

final dioClientProvider = Provider<Dio>((ref) {
  final cacheStore = ref.watch(cacheStoreProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Accept': 'application/json',
        // 'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    RefreshTokenInterceptor(ref, dio),
    ErrorHandlingInterceptor(ref),
  ]);

  final cacheOptions = CacheOptions(
    store: cacheStore,
    policy: CachePolicy.request, // Tôn trọng Header Cache-Control mặc định
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 7),
    priority: CachePriority.normal,
    keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    allowPostMethod: false,
  );

  // Thêm custom Interceptor để tự động force cache 10 phút cho các API Báo cáo & Danh mục
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.method == 'GET' && 
          (options.path.contains('reports') || options.path.contains('categories'))) {
        // Ép buộc cache 10 phút (600 giây)
        final customOptions = cacheOptions.copyWith(
          policy: CachePolicy.forceCache,
          maxStale: Nullable(const Duration(minutes: 10)),
        );
        options.extra.addAll(customOptions.toExtra());
      }
      return handler.next(options);
    },
  ));

  // Thêm DioCacheInterceptor chính vào sau cùng
  dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

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

    // 2. Đính kèm ngôn ngữ hiện tại của App qua Header Accept-Language
    final currentLocale = ref.read(localeProvider);
    options.headers['Accept-Language'] = currentLocale;

    // 3. Lấy và đính kèm Access Token nếu có
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

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

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
              error: data['error'] ?? data['message'] ?? 'Thao tác thất bại!',
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
      // 1. Kiểm tra cờ đồng bộ ngay lập tức để chặn đứng các cuộc gọi đồng thời (Race Condition)
      if (_isRefreshing) {
        try {
          final newAccessToken = await _refreshCompleter?.future;
          if (newAccessToken != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryRequest = await mainDio.fetch(err.requestOptions);
            return handler.resolve(retryRequest);
          }
        } catch (_) {
          // Bỏ qua lỗi, tiếp tục trượt xuống để lan truyền lỗi 401 ban đầu
        }
        return handler.next(err);
      }

      // Đánh dấu bắt đầu tiến trình gia hạn token
      _isRefreshing = true;
      _refreshCompleter = Completer<String?>();

      final storage = ref.read(secureStorageServiceProvider);
      final userId = await storage.get(key: AppConstant.userId);
      final refreshToken = await storage.get(key: AppConstant.refreshToken);
      
      if (refreshToken != null) {
        String? newAccessToken;
        bool refreshSuccessful = false;

        try {
          final refreshDio = Dio(BaseOptions(
            baseUrl: AppConfig.baseUrl,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ));
          
          final response = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {
              'user_id': userId,
              'refresh_token': refreshToken
            },
          );

          if (response.statusCode == 200 && response.data != null) {
            final String? token = response.data['access_token']?.toString();
            final String? refresh = response.data['refresh_token']?.toString();

            if (token != null && refresh != null) {
              newAccessToken = token;
              await storage.save(key: AppConstant.accessToken, value: token);
              await storage.save(key: AppConstant.refreshToken, value: refresh);
              refreshSuccessful = true;
            }
          }
        } catch (refreshError) {
          // Chỉ giải quyết lỗi của cuộc gọi API refresh token
          _refreshCompleter?.completeError(refreshError);
          _isRefreshing = false;
          _refreshCompleter = null;

          await storage.clearAll();
          Future.microtask(() {
            ref.read(authNotifierProvider.notifier).logout();
          });
          return handler.next(err);
        }

        // Hoàn tất completer ngoài try-catch để tránh lỗi 'Future already completed' khi retry thất bại
        if (refreshSuccessful && newAccessToken != null) {
          _refreshCompleter?.complete(newAccessToken);
          _isRefreshing = false;
          _refreshCompleter = null;

          // Thực hiện cuộc gọi lại (retry) và tự bắt lỗi của nó riêng biệt
          try {
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryRequest = await mainDio.fetch(err.requestOptions);
            return handler.resolve(retryRequest);
          } on DioException catch (retryError) {
            return handler.reject(retryError);
          } catch (retryError) {
            return handler.next(DioException(
              requestOptions: err.requestOptions,
              error: retryError,
            ));
          }
        } else {
          _refreshCompleter?.complete(null);
          _isRefreshing = false;
          _refreshCompleter = null;
        }
      } else {
        // Không tìm thấy refresh token trong bộ nhớ tạm
        _isRefreshing = false;
        _refreshCompleter = null;
      }
    }
    return handler.next(err); 
  }
}

class ErrorHandlingInterceptor extends Interceptor {
  final Ref ref;
  ErrorHandlingInterceptor(this.ref);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final translations = ref.read(translationsProvider);
    String errorMessage = translations['network_error'] ?? 'Đã xảy ra lỗi kết nối mạng, vui lòng thử lại sau ít phút';

    if (err.type == DioExceptionType.connectionTimeout || err.type == DioExceptionType.receiveTimeout) {
      errorMessage = translations['timeout_error'] ?? 'Kết nối mạng quá hạn (Timeout). Vui lòng kiểm tra lại mạng internet của bạn !';
    } else if (err.response != null) {
      final responseData = err.response?.data;
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? responseData['error'] ?? errorMessage;
      }
    }

    // Trả ra một bản Exception có bọc thông báo sạch sẽ
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