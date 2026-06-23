import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/reporting_export/data/datasource/remote/reporting_export_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportingExportApiServiceProvider = Provider<ReportingExportApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ReportingExportApiService(dio);
});
