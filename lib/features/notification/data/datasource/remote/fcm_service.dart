import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/remote/notification_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';

class FcmService {
  final NotificationApiService _apiService;
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  VoidCallback? onDataChanged;

  FcmService(this._apiService, this._ref);

  Future<void> initialize() async {
    // 1. Xin quyền thông báo (iOS & Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Lấy FCM Token và gửi lên backend
      await syncTokenToServer();

      // 3. Lắng nghe nếu FCM Token thay đổi
      _messaging.onTokenRefresh.listen((token) {
        _sendTokenToServer(token);
      });

      // 4. Lắng nghe thông báo khi ứng dụng đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        String? title = message.notification?.title;
        String? body = message.notification?.body;

        // Nếu thông báo là dạng data-only (không có payload notification nhưng có title/body trong data)
        if (title == null && body == null) {
          title = message.data['title'];
          body = message.data['body'];
        }

        if (title != null && body != null) {
          // Hiển thị notification dạng banner sử dụng LocalNotificationService hiện tại của bạn
          final pref = _ref.read(notificationPreferencesProvider).value;
          final pushEnabled = pref?.pushEnabled ?? true;
          if (pushEnabled) {
            LocalNotificationService.showNotification(
              id: message.hashCode,
              title: title,
              body: body,
              payload: message.data.toString(),
            );
          }
        }
        // Tự động tải lại dữ liệu khi nhận thông báo trong foreground
        onDataChanged?.call();
      });

      // 5. Lắng nghe khi người dùng click vào thông báo khi app đang chạy ngầm (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });

      // 6. Kiểm tra xem app có được mở từ thông báo khi đã tắt hoàn toàn hay không (Terminated)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }
    }
  }

  Future<void> syncTokenToServer() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint("Không lấy được FCM Token: $e");
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      String deviceType = 'web';
      if (!kIsWeb) {
        if (Platform.isAndroid) deviceType = 'android';
        if (Platform.isIOS) deviceType = 'ios';
      }
      await _apiService.registerDeviceToken({
        'device_token': token,
        'device_type': deviceType,
      });
      debugPrint("Đã đăng ký FCM Token thành công lên server: $token");
    } catch (e) {
      debugPrint("Lỗi gửi FCM Token lên server: $e");
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint("User clicked notification: ${message.data}");
    // Tự động tải lại dữ liệu khi người dùng click vào thông báo
    onDataChanged?.call();
  }
}
