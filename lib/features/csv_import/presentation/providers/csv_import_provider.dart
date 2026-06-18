import 'dart:async';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/csv_import/data/datasource/remote/csv_import_api_service.dart';
import 'package:expense_management/features/csv_import/data/models/csv_import_dto.dart';
import 'package:expense_management/features/csv_import/data/repository_impl/csv_import_repository_impl.dart';
import 'package:expense_management/features/csv_import/domain/repositories/csv_import_repository.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final csvImportApiServiceProvider = Provider<CsvImportApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CsvImportApiService(dio);
});

final csvImportRepositoryProvider = Provider<CsvImportRepository>((ref) {
  final apiService = ref.watch(csvImportApiServiceProvider);
  return CsvImportRepositoryImpl(apiService);
});

class CsvImportHistoryNotifier extends AsyncNotifier<List<CsvImportDto>> {
  Timer? _pollingTimer;

  @override
  Future<List<CsvImportDto>> build() async {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    final repo = ref.watch(csvImportRepositoryProvider);
    final list = await repo.fetchImports();

    // Filter by client-side deleted import IDs for current user
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final prefsKey = userId.isNotEmpty ? 'deleted_import_ids_$userId' : 'deleted_import_ids';

    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList(prefsKey) ?? [];

    final filteredList = list.where((dto) => !deletedIds.contains(dto.id)).toList();

    // Auto-polling refresh after 8 seconds if there are jobs processing
    final hasPending = filteredList.any((dto) => dto.status == 'pending' || dto.status == 'processing');
    if (hasPending) {
      _pollingTimer?.cancel();
      _pollingTimer = Timer(const Duration(seconds: 8), () {
        ref.invalidateSelf();
      });
    }

    return filteredList;
  }

  Future<void> deleteImport(String id) async {
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? '';
    final prefsKey = userId.isNotEmpty ? 'deleted_import_ids_$userId' : 'deleted_import_ids';

    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList(prefsKey) ?? [];
    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList(prefsKey, deletedIds);
    }
    ref.invalidateSelf();
  }
}

final csvImportHistoryProvider =
    AsyncNotifierProvider<CsvImportHistoryNotifier, List<CsvImportDto>>(() {
  return CsvImportHistoryNotifier();
});
