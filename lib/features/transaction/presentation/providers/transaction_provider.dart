import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/transaction/data/mappers/transaction_mapper.dart';
import 'package:expense_management/features/transaction/data/models/transaction_dto.dart';
import 'package:flutter/material.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/transaction/data/datasource/remote/transaction_remote_datasource.dart';
import 'package:expense_management/features/transaction/data/repository_impl/transaction_repository_impl.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/features/transaction/domain/use_case/add_transaction_usecase.dart';
import 'package:expense_management/features/transaction/domain/use_case/get_transactions_usecase.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionApiServiceProvider = Provider<TransactionApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TransactionApiService(dio);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final apiService = ref.watch(transactionApiServiceProvider);
  final dio = ref.watch(dioClientProvider);
  return TransactionRepositoryImpl(apiService, dio);
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
  Timer? _syncTimer;
  bool _isSyncing = false;

  @override
  Future<List<TransactionEntity>> build() async {
    final storage = ref.read(localStoreHelperProvider);
    final cachedData = storage.getCachedTransactions();
    final pendingData = storage.getPendingTransactions();

    final initialList = [...pendingData, ...cachedData];
    if (initialList.isNotEmpty) {
      state = AsyncValue.data(initialList);
    }

    ref.onDispose(() {
      _syncTimer?.cancel();
    });
    _startSyncTimer();

    final useCase = ref.watch(getTransactionsUseCaseProvider);
    try {
      final freshList = await useCase.execute(perPage: 200);
      storage.saveCachedTransactions(freshList.take(20).toList());

      if (pendingData.isNotEmpty) {
        _syncPendingTransactions();
      }

      return [...pendingData, ...freshList];
    } catch (e) {
      if (initialList.isNotEmpty) {
        return initialList;
      }
      rethrow;
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      final storage = ref.read(localStoreHelperProvider);
      if (storage.getPendingTransactions().isNotEmpty) {
        _syncPendingTransactions();
      }
    });
  }

  bool _isNetworkError(dynamic error) {
    if (error is DioException) {
      final type = error.type;
      return type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.sendTimeout ||
          type == DioExceptionType.receiveTimeout ||
          type == DioExceptionType.connectionError ||
          error.error is SocketException ||
          error.message?.contains('SocketException') == true;
    }
    if (error is SocketException) {
      return true;
    }
    return false;
  }

  Future<void> _syncPendingTransactions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final storage = ref.read(localStoreHelperProvider);
      final pendingList = storage.getPendingTransactions();
      if (pendingList.isEmpty) return;

      final addTxUseCase = ref.read(addTransactionUseCaseProvider);
      final List<TransactionEntity> remainingPending = List.from(pendingList);
      bool anySuccess = false;

      for (final tx in pendingList) {
        try {
          MultipartFile? attachmentFile;
          if (tx.attachmentUrls.isNotEmpty) {
            final localPath = tx.attachmentUrls.first;
            final file = File(localPath);
            if (await file.exists()) {
              attachmentFile = await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              );
            }
          }

          await addTxUseCase.execute(
            walletId: tx.walletId,
            categoryId: tx.categoryId,
            type: tx.type,
            amount: tx.amount,
            title: tx.title,
            notes: tx.notes,
            transactionDate: tx.transactionDate.toIso8601String(),
            currencyCode: tx.currencyCode,
            exchangeRate: tx.exchangeRate,
            timezone: tx.timezone,
            attachment: attachmentFile,
          );

          remainingPending.removeWhere((item) => item.id == tx.id);
          await storage.savePendingTransactions(remainingPending);
          anySuccess = true;

          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            ElegantNotification.success(
              title: Text(
                'sync_success_title'.tr(ref),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              description: Text(
                'sync_success_desc'.tr(ref).replaceFirst('{title}', tx.title),
              ),
              animation: AnimationType.fromTop,
            ).show(context);
          }
        } catch (e) {
          if (_isNetworkError(e)) {
            break;
          }
          // Remove bad transaction from queue so sync isn't permanently blocked
          remainingPending.removeWhere((item) => item.id == tx.id);
          await storage.savePendingTransactions(remainingPending);

          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            ElegantNotification.error(
              title: Text(
                'sync_failed_title'.tr(ref),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              description: Text(
                'sync_failed_desc'.tr(ref).replaceFirst('{title}', tx.title),
              ),
              animation: AnimationType.fromTop,
            ).show(context);
          }
        }
      }

      if (anySuccess) {
        await ref.read(walletNotifierProvider.notifier).refreshWallets();
        await refreshTransactions();
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> refreshTransactions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getTransactionsUseCaseProvider);
      final freshList = await useCase.execute(perPage: 200);

      final storage = ref.read(localStoreHelperProvider);
      storage.saveCachedTransactions(freshList.take(20).toList());

      final pendingData = storage.getPendingTransactions();
      if (pendingData.isNotEmpty) {
        _syncPendingTransactions();
      }

      return [...pendingData, ...freshList];
    });
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    state = await AsyncValue.guard(() async {
      final currentList = state.value ?? [];
      final newList = [transaction, ...currentList];
      ref.read(localStoreHelperProvider).saveCachedTransactions(newList.take(20).toList());
      return newList;
    });
  }

  Future<void> addPendingTransaction(TransactionParams params) async {
    final storage = ref.read(localStoreHelperProvider);
    final currentPending = storage.getPendingTransactions();

    final tempTx = TransactionEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      walletId: params.walletId,
      categoryId: params.categoryId.isEmpty ? null : params.categoryId,
      type: params.type,
      status: 'pending',
      amount: params.amount,
      title: params.title,
      notes: params.notes,
      transactionDate: DateTime.parse(params.transactionDate),
      currencyCode: params.currencyCode,
      exchangeRate: params.exchangeRate,
      timezone: params.timezone,
      walletName: params.walletName,
      categoryName: params.categoryName,
      attachmentUrls: params.attachmentPath != null ? [params.attachmentPath!] : const [],
    );

    final newPending = [tempTx, ...currentPending];
    await storage.savePendingTransactions(newPending);

    state = await AsyncValue.guard(() async {
      final currentList = state.value ?? [];
      return [tempTx, ...currentList];
    });

    _syncPendingTransactions();
  }

  Future<TransactionEntity> getTransactionById(String transactionId) async {
    final dio = ref.read(dioClientProvider);
    final url = ApiEndpoints.showTransaction.replaceAll('{id}', transactionId);

    try {
      final response = await dio.get(url);
      final responseData = response.data;
      
      if (responseData != null && responseData['data'] != null) {
        final dto = TransactionDto.fromJson(responseData['data'] as Map<String, dynamic>);
        return TransactionMapper.toEntity(dto);
      } else {
        throw Exception('Không tìm thấy dữ liệu giao dịch hợp lệ');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[TransactionNotifier] getTransactionById error: $e',
        tag: 'TransactionNotifier',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final dio = ref.read(dioClientProvider);
    final url = ApiEndpoints.deleteTransaction.replaceAll('{id}', transactionId);
    await dio.delete(url);

    state = await AsyncValue.guard(() async {
      final currentList = state.value ?? [];
      return currentList.where((tx) => tx.id != transactionId).toList();
    });

    ref.invalidate(walletNotifierProvider);
  }

  Future<void> updateTransaction({
    required String transactionId,
    required String title,
    String? categoryId,
    String? notes,
    MultipartFile? attachment,
  }) async {
    final dio = ref.read(dioClientProvider);

    final Map<String, dynamic> data = {
      'title': title,
      if (categoryId != null) 'category_id': categoryId,
      if (notes != null) 'notes': notes,
      if (attachment != null) 'attachment': attachment,
    };

    final formData = FormData.fromMap(data);
    final url = ApiEndpoints.updateTransaction.replaceAll('{id}', transactionId);

    await dio.post(url, data: formData);

    ref.invalidate(transactionListProvider);
    ref.invalidate(walletNotifierProvider);
  }
}

final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<TransactionEntity>>(() {
  return TransactionListNotifier();
});
