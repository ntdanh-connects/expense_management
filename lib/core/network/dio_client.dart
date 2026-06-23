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
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';


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
    RetryOnTimeoutInterceptor(dio: dio),
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

  // Thêm custom Interceptor để tự động cấu hình chính sách cache cho các API đặc thù
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (options.method == 'GET') {
        if (options.path.contains('categories')) {
          // Ép buộc cache 10 phút (600 giây) cho danh mục
          final customOptions = cacheOptions.copyWith(
            policy: CachePolicy.forceCache,
            maxStale: Nullable(const Duration(minutes: 10)),
          );
          options.extra.addAll(customOptions.toExtra());
        } else if (options.path.contains('wallets') || 
                   options.path.contains('transactions') || 
                   options.path.contains('notifications') ||
                   options.path.contains('dashboard') ||
                   options.path.contains('reports')) {
          // Bỏ qua cache hoàn toàn cho ví, giao dịch, thông báo, dashboard và báo cáo (reports) để đảm bảo dữ liệu luôn mới nhất
          final customOptions = cacheOptions.copyWith(
            policy: CachePolicy.noCache,
          );
          options.extra.addAll(customOptions.toExtra());
        }
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

    // 3. Lấy và đính kèm Access Token & User ID nếu có
    final storage = ref.read(secureStorageServiceProvider);
    final accessToken = await storage.get(key: AppConstant.accessToken);
    final userId = await storage.get(key: AppConstant.userId);

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (userId != null) {
      options.extra['request_user_id'] = userId;
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

  void _triggerSessionExpired() {
    final authState = ref.read(authNotifierProvider);
    final isUnauthenticated = authState.maybeWhen(
      unauthenticated: () => true,
      orElse: () => false,
    );
    final sessionExpired = ref.read(sessionExpiredProvider);

    if (!sessionExpired && !isUnauthenticated) {
      ref.read(sessionExpiredProvider.notifier).state = true;
      Future.microtask(() {
        ref.read(authNotifierProvider.notifier).logout();
      });
    }
  }

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
    final path = err.requestOptions.path;
    final isAuthOrTokenOrLogout = path.contains('login') || 
                                  path.contains('register') || 
                                  path.contains('refresh-token') || 
                                  path.contains('logout');

    if (err.response?.statusCode == 401 && !isAuthOrTokenOrLogout) {
      final storage = ref.read(secureStorageServiceProvider);
      final currentAccessToken = await storage.get(key: AppConstant.accessToken);
      final currentUserId = await storage.get(key: AppConstant.userId);

      // Lấy token và user_id của request bị lỗi 401 này
      final requestTokenHeader = err.requestOptions.headers['Authorization']?.toString();
      final requestToken = requestTokenHeader?.replaceAll('Bearer ', '').trim();
      final requestUserId = err.requestOptions.extra['request_user_id']?.toString();

      // Trường hợp 1: Nếu requestUserId khác currentUserId, nghĩa là user đã thay đổi (đã logout và đăng nhập nick khác).
      // Chúng ta lập tức bỏ qua request cũ này để tránh gây đăng xuất nhầm tài khoản mới.
      if (requestUserId != null && currentUserId != null && requestUserId != currentUserId) {
        AppLogger.warning("⚠️ Request 401 thuộc về tài khoản cũ. Bỏ qua không gọi logout tài khoản hiện tại.");
        return handler.next(err);
      }

      // Trường hợp 2: Nếu cùng user nhưng token của request này đã cũ hơn token hiện tại đang lưu ở storage
      // (nghĩa là token đã được refresh thành công bởi một request song song khác từ trước).
      if (requestToken != null && currentAccessToken != null && requestToken != currentAccessToken) {
        final authState = ref.read(authNotifierProvider);
        final isAuthenticated = authState.maybeWhen(
          authenticated: (_) => true,
          orElse: () => false,
        );

        if (isAuthenticated) {
          AppLogger.info("🔄 Token đã được gia hạn bởi request khác. Tự động thử lại request này với token mới...");
          try {
            err.requestOptions.headers['Authorization'] = 'Bearer $currentAccessToken';
            final retryRequest = await mainDio.fetch(err.requestOptions);
            return handler.resolve(retryRequest);
          } catch (e) {
            return handler.next(err);
          }
        } else {
          AppLogger.warning("⚠️ Request 401 thuộc về phiên đăng nhập đã bị hủy. Bỏ qua.");
          return handler.next(err);
        }
      }

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
              'user_id': currentUserId,
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

          _triggerSessionExpired();
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

          // Khi gia hạn thất bại (API trả về 200 nhưng không đúng định dạng token) -> Tiến hành logout
          _triggerSessionExpired();
        }
      } else {
        // Không tìm thấy refresh token trong bộ nhớ tạm -> Đăng xuất người dùng luôn
        _isRefreshing = false;
        _refreshCompleter = null;

        _triggerSessionExpired();
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

class RetryOnTimeoutInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration delay;

  RetryOnTimeoutInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.delay = const Duration(seconds: 2),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isTimeout = err.type == DioExceptionType.connectionTimeout || 
                      err.type == DioExceptionType.receiveTimeout;
    
    final isGetMethod = err.requestOptions.method.toUpperCase() == 'GET';

    if (isTimeout && isGetMethod) {
      int retryCount = err.requestOptions.extra['retry_count'] ?? 0;

      if (retryCount < maxRetries) {
        retryCount++;
        err.requestOptions.extra['retry_count'] = retryCount;

        AppLogger.warning(
          "🔄 [Network] Request tới ${err.requestOptions.path} bị timeout. Đang tự động thử lại lần $retryCount/$maxRetries sau ${delay.inSeconds} giây..."
        );

        await Future.delayed(delay);

        try {
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (retryErr) {
          // Lan truyền lỗi để ErrorInterceptor có thể xử lý tiếp (hoặc retry lần sau)
          return super.onError(retryErr, handler);
        } catch (e) {
          return super.onError(
            DioException(requestOptions: err.requestOptions, error: e),
            handler,
          );
        }
      }
    }

    return super.onError(err, handler);
  }
}