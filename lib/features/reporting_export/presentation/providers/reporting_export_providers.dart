import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/reporting_export/data/datasource/remote/reporting_export_api_service.dart';
import 'package:expense_management/features/reporting_export/data/models/report_export_dto.dart';
import 'package:expense_management/features/reporting_export/data/repository_impl/reporting_export_repository_impl.dart';
import 'package:expense_management/features/reporting_export/domain/repositories/reporting_export_repository.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:expense_management/features/profile/user_provider.dart';

// 1. Api Service Provider
final reportingExportApiServiceProvider = Provider<ReportingExportApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ReportingExportApiService(dio);
});

// 2. Repository Provider
final reportingExportRepositoryProvider = Provider<ReportingExportRepository>((ref) {
  final apiService = ref.watch(reportingExportApiServiceProvider);
  final reportRepo = ref.watch(reportRepositoryProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  return ReportingExportRepositoryImpl(
    apiService: apiService,
    reportRepository: reportRepo,
    transactionRepository: transactionRepo,
  );
});

// 3. Entity representing items in history lists
class ExportHistoryItem {
  final String name;
  final String pathOrUrl;
  final DateTime date;
  final double sizeInMb;
  final bool isLocal; // true for local PDF report, false for backend CSV export
  final String status; // pending, processing, completed, failed
  final String? remoteId;

  ExportHistoryItem({
    required this.name,
    required this.pathOrUrl,
    required this.date,
    required this.sizeInMb,
    required this.isLocal,
    required this.status,
    this.remoteId,
  });
}

// 4. Combined export history notifier (Server CSV + Local PDF)
class ExportHistoryNotifier extends AsyncNotifier<List<ExportHistoryItem>> {
  Timer? _pollingTimer;

  @override
  Future<List<ExportHistoryItem>> build() async {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    final repo = ref.watch(reportingExportRepositoryProvider);

    // Fetch remote history
    List<ReportExportDto> remoteList = [];
    try {
      remoteList = await repo.fetchRemoteExports();
    } catch (e) {
      // Allow local file viewing even if offline/server error
    }

    _checkRemoteExportNotifications(remoteList);

    final hasPending = remoteList.any((dto) => dto.status == 'pending' || dto.status == 'processing');
    if (hasPending) {
      _pollingTimer?.cancel();
      _pollingTimer = Timer(const Duration(seconds: 10), () {
        ref.invalidateSelf();
      });
    }

    // Fetch local files history
    List<File> localFiles = [];
    try {
      localFiles = await repo.getLocalPdfHistory();
    } catch (e) {
      // Ignore
    }

    // Read client-side deleted remote export IDs
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final prefsKey = userId.isNotEmpty ? 'deleted_remote_export_ids_$userId' : 'deleted_remote_export_ids';

    final prefs = await SharedPreferences.getInstance();
    final deletedRemoteIds = List<String>.from(prefs.getStringList(prefsKey) ?? []);

    final List<ExportHistoryItem> items = [];

    // Map remote CSV files
    for (final dto in remoteList) {
      if (deletedRemoteIds.contains(dto.id)) {
        continue; // skip deleted remote items
      }

      // Generate readable name based on filters if available
      String dateLabel = 'Giao dịch';
      if (dto.filters != null) {
        final start = dto.filters!['start_date']?.toString().split('T').first;
        final end = dto.filters!['end_date']?.toString().split('T').first;
        if (start != null && end != null) {
          dateLabel = 'gd_${start}_to_$end';
        }
      }
      final name = '$dateLabel.csv';
      final date = DateTime.tryParse(dto.createdAt) ?? DateTime.now();

      items.add(ExportHistoryItem(
        name: name,
        pathOrUrl: dto.fileUrl ?? '',
        date: date,
        sizeInMb: 0.8, // Backend doesn't return file size, using standard placeholder
        isLocal: false,
        status: dto.status,
        remoteId: dto.id,
      ));
    }

    // Map local PDF files
    for (final file in localFiles) {
      try {
        final stat = file.statSync();
        final sizeMb = stat.size / (1024 * 1024);
        items.add(ExportHistoryItem(
          name: file.path.split('/').last.split('\\').last,
          pathOrUrl: file.path,
          date: file.lastModifiedSync(),
          sizeInMb: sizeMb,
          isLocal: true,
          status: 'completed',
        ));
      } catch (_) {
        // Skip inaccessible files
      }
    }

    // Sort by date descending
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> deleteItem(ExportHistoryItem item) async {
    final repo = ref.read(reportingExportRepositoryProvider);
    if (item.isLocal) {
      await repo.deleteLocalPdf(item.pathOrUrl);
    } else {
      if (item.remoteId != null) {
        final user = ref.read(currentUserProvider);
        final userId = user?.id ?? '';
        final prefsKey = userId.isNotEmpty ? 'deleted_remote_export_ids_$userId' : 'deleted_remote_export_ids';

        final prefs = await SharedPreferences.getInstance();
        final deletedRemoteIds = List<String>.from(prefs.getStringList(prefsKey) ?? []);
        if (!deletedRemoteIds.contains(item.remoteId)) {
          deletedRemoteIds.add(item.remoteId!);
          await prefs.setStringList(prefsKey, deletedRemoteIds);
        }
      }
    }
    ref.invalidateSelf();
  }

  Future<void> clearAllLocalHistory() async {
    final repo = ref.read(reportingExportRepositoryProvider);
    
    // Clear local PDFs
    final localFiles = await repo.getLocalPdfHistory();
    for (var f in localFiles) {
      await repo.deleteLocalPdf(f.path);
    }

    // Clear remote items locally by adding them to deletedRemoteIds
    try {
      final remoteList = await repo.fetchRemoteExports();
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';
      final prefsKey = userId.isNotEmpty ? 'deleted_remote_export_ids_$userId' : 'deleted_remote_export_ids';

      final prefs = await SharedPreferences.getInstance();
      final deletedRemoteIds = List<String>.from(prefs.getStringList(prefsKey) ?? []);
      for (final dto in remoteList) {
        if (!deletedRemoteIds.contains(dto.id)) {
          deletedRemoteIds.add(dto.id);
        }
      }
      await prefs.setStringList(prefsKey, deletedRemoteIds);
    } catch (_) {}

    ref.invalidateSelf();
  }

  Future<void> _checkRemoteExportNotifications(List<ReportExportDto> remoteList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final dto in remoteList) {
        final completedKey = 'notified_export_${dto.id}_completed';
        final failedKey = 'notified_export_${dto.id}_failed';

        if (dto.status == 'completed') {
          final alreadyNotified = prefs.getBool(completedKey) ?? false;
          if (!alreadyNotified) {
            String dateLabel = 'Báo cáo CSV';
            if (dto.filters != null) {
              final start = dto.filters!['start_date']?.toString().split('T').first;
              final end = dto.filters!['end_date']?.toString().split('T').first;
              if (start != null && end != null) {
                dateLabel = 'Báo cáo từ $start đến $end';
              }
            }
            final title = 'Xuất dữ liệu thành công';
            final body = '$dateLabel đã được xuất xong và sẵn sàng tải về.';

            await LocalNotificationService.showNotification(
              id: dto.id.hashCode,
              title: title,
              body: body,
            );
            await prefs.setBool(completedKey, true);

            final userId = ref.read(currentUserProvider)?.id ?? '';
            if (userId.isNotEmpty) {
              final localNotif = await LocalNotificationStorage.createAndSave(
                userId: userId,
                type: 'transaction',
                title: title,
                body: body,
              );
              if (localNotif != null) {
                ref.read(notificationNotifierProvider.notifier).addLocalNotification(localNotif);
              }
            }
          }
        } else if (dto.status == 'failed') {
          final alreadyNotified = prefs.getBool(failedKey) ?? false;
          if (!alreadyNotified) {
            String dateLabel = 'Báo cáo CSV';
            if (dto.filters != null) {
              final start = dto.filters!['start_date']?.toString().split('T').first;
              final end = dto.filters!['end_date']?.toString().split('T').first;
              if (start != null && end != null) {
                dateLabel = 'Báo cáo từ $start đến $end';
              }
            }
            final title = 'Xuất dữ liệu thất bại';
            final body = 'Xuất dữ liệu $dateLabel gặp lỗi.';

            await LocalNotificationService.showNotification(
              id: dto.id.hashCode,
              title: title,
              body: body,
            );
            await prefs.setBool(failedKey, true);

            final userId = ref.read(currentUserProvider)?.id ?? '';
            if (userId.isNotEmpty) {
              final localNotif = await LocalNotificationStorage.createAndSave(
                userId: userId,
                type: 'transaction',
                title: title,
                body: body,
              );
              if (localNotif != null) {
                ref.read(notificationNotifierProvider.notifier).addLocalNotification(localNotif);
              }
            }
          }
        }
      }
    } catch (_) {}
  }
}

final exportHistoryListProvider =
    AsyncNotifierProvider<ExportHistoryNotifier, List<ExportHistoryItem>>(() {
  return ExportHistoryNotifier();
});
