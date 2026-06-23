import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/dashboard/domain/di/domain_providers.dart';
import 'package:expense_management/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';

// Provider gọi API aggregate để fetch & sync toàn bộ Dashboard data
final fetchDashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummaryDto>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  ref.watch(transactionListProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getSummary();
});
