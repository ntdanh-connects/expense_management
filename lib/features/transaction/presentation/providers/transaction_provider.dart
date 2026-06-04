import 'package:dio/dio.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/transaction/data/datasource/remote/transaction_remote_datasource.dart';
import 'package:expense_management/features/transaction/data/repository_impl/transaction_repository_impl.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/features/transaction/domain/use_case/add_transaction_usecase.dart';
import 'package:expense_management/features/transaction/domain/use_case/get_transactions_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionApiServiceProvider = Provider<TransactionApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TransactionApiService(dio);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final apiService = ref.watch(transactionApiServiceProvider);
  return TransactionRepositoryImpl(apiService);
});

final addTransactionUseCaseProvider = Provider<AddTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return AddTransactionUseCase(repository);
});

final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetTransactionsUseCase(repository);
});

class TransactionListNotifier extends AsyncNotifier<List<TransactionEntity>> {
  @override
  Future<List<TransactionEntity>> build() async {
    final useCase = ref.watch(getTransactionsUseCaseProvider);
    return useCase.execute(perPage: 50); // Get first 50 transactions
  }

  Future<void> refreshTransactions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getTransactionsUseCaseProvider);
      return useCase.execute(perPage: 50);
    });
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    state = await AsyncValue.guard(() async {
      final currentList = state.value ?? [];
      return [transaction, ...currentList];
    });
  }
}

final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<TransactionEntity>>(() {
  return TransactionListNotifier();
});
