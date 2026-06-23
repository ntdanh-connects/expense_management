import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/reporting_export/data/di/data_providers.dart';
import 'package:expense_management/features/reporting_export/data/repository_impl/reporting_export_repository_impl.dart';
import 'package:expense_management/features/reporting_export/domain/repositories/reporting_export_repository.dart';
import 'package:expense_management/features/analytic/domain/di/domain_providers.dart';
import 'package:expense_management/features/transaction/domain/di/domain_providers.dart';
import 'package:expense_management/features/budget/domain/di/domain_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportingExportRepositoryProvider = Provider<ReportingExportRepository>((ref) {
  final apiService = ref.watch(reportingExportApiServiceProvider);
  final reportRepo = ref.watch(reportRepositoryProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final dio = ref.watch(dioClientProvider);
  return ReportingExportRepositoryImpl(
    apiService: apiService,
    reportRepository: reportRepo,
    transactionRepository: transactionRepo,
    budgetRepository: budgetRepo,
    dio: dio,
  );
});
