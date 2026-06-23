import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/transaction/data/di/data_providers.dart';
import 'package:expense_management/features/transaction/data/repository_impl/transaction_repository_impl.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/features/transaction/domain/use_case/add_transaction_usecase.dart';
import 'package:expense_management/features/transaction/domain/use_case/get_transactions_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final apiService = ref.watch(transactionApiServiceProvider);
  final dio = ref.watch(dioClientProvider);
  final database = ref.watch(appDatabaseProvider);
  return TransactionRepositoryImpl(
    apiService,
    dio,
    database,
    () => ref.read(currentUserProvider)?.id ?? '',
  );
});

final addTransactionUseCaseProvider = Provider<AddTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return AddTransactionUseCase(repository);
});

final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetTransactionsUseCase(repository);
});
