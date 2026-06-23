import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/savings/data/datasource/remote/savings_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final savingsApiServiceProvider = Provider<SavingsApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return SavingsApiService(dio);
});
