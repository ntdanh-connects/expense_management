import 'package:expense_management/features/analytic/data/di/data_providers.dart';
import 'package:expense_management/features/analytic/data/repository_impl/report_repository_impl.dart';
import 'package:expense_management/features/analytic/domain/repository/report_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final apiService = ref.watch(reportApiServiceProvider);
  return ReportRepositoryImpl(apiService);
});
