import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/features/ai_assistant/data/di/data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';

// ------------------------------------------------------------------
// Simple model
// ------------------------------------------------------------------
class HabitAnalysisEntry {
  final String id;
  final String type; // 'daily' | 'monthly' | 'yearly'
  final String analysisDate;
  final Map<String, dynamic> analysisData;
  final bool isRead;
  final String createdAt;
  final double actualAmount;
  final double baselineAmount;
  final double diffAmount;
  final double percentChange;
  final String status;
  final String periodRange;

  HabitAnalysisEntry({
    required this.id,
    required this.type,
    required this.analysisDate,
    required this.analysisData,
    required this.isRead,
    required this.createdAt,
    required this.actualAmount,
    required this.baselineAmount,
    required this.diffAmount,
    required this.percentChange,
    required this.status,
    required this.periodRange,
  });

  factory HabitAnalysisEntry.fromJson(Map<String, dynamic> json) {
    return HabitAnalysisEntry(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'daily',
      analysisDate: json['analysis_date']?.toString() ?? '',
      analysisData: (json['analysis_data'] is Map<String, dynamic>)
          ? json['analysis_data'] as Map<String, dynamic>
          : {},
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at']?.toString() ?? '',
      actualAmount:
          double.tryParse(json['actual_amount']?.toString() ?? '') ?? 0.0,
      baselineAmount:
          double.tryParse(json['baseline_amount']?.toString() ?? '') ?? 0.0,
      diffAmount: double.tryParse(json['diff_amount']?.toString() ?? '') ?? 0.0,
      percentChange:
          double.tryParse(json['percent_change']?.toString() ?? '') ?? 0.0,
      status: json['status']?.toString() ?? 'normal',
      periodRange: json['period_range']?.toString() ?? '',
    );
  }

  HabitAnalysisEntry copyWith({bool? isRead}) {
    return HabitAnalysisEntry(
      id: id,
      type: type,
      analysisDate: analysisDate,
      analysisData: analysisData,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actualAmount: actualAmount,
      baselineAmount: baselineAmount,
      diffAmount: diffAmount,
      percentChange: percentChange,
      status: status,
      periodRange: periodRange,
    );
  }
}

// ------------------------------------------------------------------
// State
// ------------------------------------------------------------------
class HabitAnalysisState {
  final List<HabitAnalysisEntry> entries;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const HabitAnalysisState({
    this.entries = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  HabitAnalysisState copyWith({
    List<HabitAnalysisEntry>? entries,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return HabitAnalysisState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

// ------------------------------------------------------------------
// Notifier
// ------------------------------------------------------------------
class HabitAnalysisNotifier extends StateNotifier<HabitAnalysisState> {
  final Ref _ref;
  String? _activeType;

  HabitAnalysisNotifier(this._ref) : super(const HabitAnalysisState());

  Future<void> load({String? type, bool refresh = false}) async {
    if (state.isLoading) return;
    if (refresh) {
      _activeType = type;
      state = const HabitAnalysisState();
    }
    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(aiAssistantApiServiceProvider);
      final resp = await api.getHabitAnalyses(
        type: _activeType,
        page: state.page,
        perPage: 15,
      );

      final responseMap = resp is Map ? resp : {};
      final dataMap = responseMap['data'] is Map
          ? responseMap['data'] as Map
          : {};
      final rawList = dataMap['data'] as List? ?? [];
      final now = DateTime.now();

      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(HabitAnalysisEntry.fromJson)
          .where((entry) {
            // Rule 1: Không có giao dịch chi tiêu mới thì không hiện phân tích hàng ngày
            if (entry.type == 'daily' && entry.actualAmount == 0) {
              return false;
            }

            // Rule 2: Chưa tới cuối tháng / cuối năm thì ẩn
            try {
              final dt = DateTime.parse(entry.analysisDate);
              if (entry.type == 'monthly') {
                if (dt.year == now.year && dt.month == now.month) {
                  final lastDay = DateTime(now.year, now.month + 1, 0).day;
                  if (now.day < lastDay) {
                    return false;
                  }
                }
              } else if (entry.type == 'yearly') {
                if (dt.year == now.year) {
                  if (now.month < 12 || now.day < 31) {
                    return false;
                  }
                }
              }
            } catch (_) {}

            return true;
          })
          .toList();

      final lastPage = (dataMap['last_page'] as int?) ?? 1;
      final currentPage = (dataMap['current_page'] as int?) ?? state.page;

      state = state.copyWith(
        entries: [...state.entries, ...items],
        isLoading: false,
        hasMore: currentPage < lastPage,
        page: currentPage + 1,
      );

      // Check and show background local notifications for newly fetched unread entries
      if (items.isNotEmpty) {
        _checkNotifications(items);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _checkNotifications(List<HabitAnalysisEntry> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in items) {
        if (entry.isRead) continue;

        final notifiedKey = 'notified_habit_analysis_${entry.id}';
        final alreadyNotified = prefs.getBool(notifiedKey) ?? false;

        if (!alreadyNotified) {
          final typeLabel = entry.type == 'daily'
              ? 'Hàng ngày'
              : (entry.type == 'monthly' ? 'Hàng tháng' : 'Hàng năm');

          final title = 'Phân tích thói quen mới';
          final body =
              'Đã có báo cáo phân tích thói quen $typeLabel ngày ${entry.analysisDate}.';

          // 1. Show native background local notification
          await LocalNotificationService.showNotification(
            id: entry.id.hashCode & 0x7FFFFFFF,
            title: title,
            body: body,
          );

          // Mark notified locally to avoid duplicate notifications
          await prefs.setBool(notifiedKey, true);

          // 2. Save notification to SQLite to show inside app's Notification sidebar
          final userId = _ref.read(currentUserProvider)?.id ?? '';
          if (userId.isNotEmpty) {
            final localNotif = await LocalNotificationStorage.createAndSave(
              userId: userId,
              type: 'habit_analysis',
              title: title,
              body: body,
            );
            if (localNotif != null) {
              _ref
                  .read(notificationNotifierProvider.notifier)
                  .addLocalNotification(localNotif);
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    try {
      final api = _ref.read(aiAssistantApiServiceProvider);
      await api.markHabitAnalysisRead(id);
      state = state.copyWith(
        entries: state.entries
            .map((e) => e.id == id ? e.copyWith(isRead: true) : e)
            .toList(),
      );
    } catch (_) {}
  }
}

// ------------------------------------------------------------------
// Provider
// ------------------------------------------------------------------
final habitAnalysisProvider =
    StateNotifierProvider<HabitAnalysisNotifier, HabitAnalysisState>((ref) {
      return HabitAnalysisNotifier(ref);
    });
