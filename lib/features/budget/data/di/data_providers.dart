import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/budget/data/data_source/remote/budget_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetApiServiceProvider = Provider<BudgetApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return BudgetApiService(dio);
});
