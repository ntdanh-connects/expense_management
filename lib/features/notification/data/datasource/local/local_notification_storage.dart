import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';

class LocalNotificationStorage {
  static const String _storageKey = 'local_in_app_notifications';

  static Future<List<NotificationDto>> getNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('${_storageKey}_$userId');
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => NotificationDto.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNotification(String userId, NotificationDto notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getNotifications(userId);
      final updated = [notification, ...existing];
      final jsonStr = jsonEncode(updated.map((n) => n.toJson()).toList());
      await prefs.setString('${_storageKey}_$userId', jsonStr);
    } catch (_) {}
  }

  static Future<NotificationDto?> createAndSave({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    if (userId.isEmpty) return null;
    final notification = NotificationDto(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
      userId: userId,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      metadata: metadata,
    );
    await saveNotification(userId, notification);
    return notification;
  }

  static Future<void> markAsRead(String userId, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getNotifications(userId);
      final updated = existing.map((n) {
        if (n.id == id) {
          return NotificationDto(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            readAt: DateTime.now().toIso8601String(),
            metadata: n.metadata,
            createdAt: n.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
        return n;
      }).toList();
      final jsonStr = jsonEncode(updated.map((n) => n.toJson()).toList());
      await prefs.setString('${_storageKey}_$userId', jsonStr);
    } catch (_) {}
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getNotifications(userId);
      final now = DateTime.now().toIso8601String();
      final updated = existing.map((n) {
        if (!n.isRead) {
          return NotificationDto(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            readAt: now,
            metadata: n.metadata,
            createdAt: n.createdAt,
            updatedAt: now,
          );
        }
        return n;
      }).toList();
      final jsonStr = jsonEncode(updated.map((n) => n.toJson()).toList());
      await prefs.setString('${_storageKey}_$userId', jsonStr);
    } catch (_) {}
  }

  static Future<void> deleteNotification(String userId, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getNotifications(userId);
      final updated = existing.where((n) => n.id != id).toList();
      final jsonStr = jsonEncode(updated.map((n) => n.toJson()).toList());
      await prefs.setString('${_storageKey}_$userId', jsonStr);
    } catch (_) {}
  }
}
