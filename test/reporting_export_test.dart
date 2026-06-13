import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_management/features/reporting_export/presentation/providers/reporting_export_providers.dart';
import 'package:expense_management/features/reporting_export/domain/repositories/reporting_export_repository.dart';
import 'package:expense_management/features/reporting_export/data/models/report_export_dto.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/shared/domain/user_entity.dart';
import 'dart:io';

class FakeReportingExportRepository implements ReportingExportRepository {
  @override
  Future<void> triggerRemoteExport({
    required String startDate,
    required String endDate,
    String? walletId,
    String? categoryId,
    String? transactionType,
  }) async {}

  @override
  Future<List<ReportExportDto>> fetchRemoteExports({int page = 1}) async {
    return [
      ReportExportDto(
        id: 'export_1',
        userId: 'user_1',
        status: 'completed',
        fileUrl: 'http://example.com/file1.csv',
        createdAt: '2026-06-13T12:00:00Z',
      ),
      ReportExportDto(
        id: 'export_2',
        userId: 'user_1',
        status: 'completed',
        fileUrl: 'http://example.com/file2.csv',
        createdAt: '2026-06-13T12:00:00Z',
      ),
    ];
  }

  @override
  Future<File> generateLocalPdfReport({
    required String title,
    required DateTimeRange dateRange,
    String? walletId,
    String? categoryId,
    String? transactionType,
    required String userCurrency,
    required dynamic ratesData,
    Map<String, String>? translations,
  }) async {
    return File('dummy.pdf');
  }

  @override
  Future<List<File>> getLocalPdfHistory() async {
    return [];
  }

  @override
  Future<void> deleteLocalPdf(String filePath) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportHistoryNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          reportingExportRepositoryProvider.overrideWithValue(FakeReportingExportRepository()),
          currentUserProvider.overrideWithValue(
            UserEntity(
              id: 'user_123',
              email: 'test@example.com',
              fullName: 'Test User',
              currency: 'VND',
              language: 'vi',
              theme: 'light',
              timezone: 'Asia/Ho_Chi_Minh',
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Loads items and deletes remote item with user scoping', () async {
      // 1. Initial load
      final list = await container.read(exportHistoryListProvider.future);
      expect(list.length, 2);
      expect(list[0].remoteId, 'export_1');
      expect(list[1].remoteId, 'export_2');

      // 2. Delete first item
      final notifier = container.read(exportHistoryListProvider.notifier);
      await notifier.deleteItem(list[0]);

      // 3. Verify it is skipped in next build
      final updatedList = await container.read(exportHistoryListProvider.future);
      expect(updatedList.length, 1);
      expect(updatedList[0].remoteId, 'export_2');

      // 4. Verify shared preferences persistence with user-scoped key
      final prefs = await SharedPreferences.getInstance();
      final deleted = prefs.getStringList('deleted_remote_export_ids_user_123');
      expect(deleted, contains('export_1'));
    });
  });
}
