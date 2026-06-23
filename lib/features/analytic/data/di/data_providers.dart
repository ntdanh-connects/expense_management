import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/analytic/data/datasource/remote/report_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportApiServiceProvider = Provider<ReportApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ReportApiService(dio);
});
