import 'package:expense_management/features/savings/data/di/data_providers.dart';
import 'package:expense_management/features/savings/data/repository_impl/savings_repository_impl.dart';
import 'package:expense_management/features/savings/domain/repository/savings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  final apiService = ref.watch(savingsApiServiceProvider);
  return SavingsRepositoryImpl(apiService);
});
