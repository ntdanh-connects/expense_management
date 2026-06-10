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
import 'package:expense_management/features/transaction/domain/entities/paginated_transactions.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/features/transaction/domain/use_case/add_transaction_usecase.dart';
import 'package:expense_management/features/transaction/domain/use_case/get_transactions_usecase.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
  FutureOr<List<TransactionEntity>> build() {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final storage = ref.read(localStoreHelperProvider);
    final cachedData = storage.getCachedTransactions(userId: userId);
    final pendingData = storage.getPendingTransactions(userId: userId);

    final initialList = [...pendingData, ...cachedData];

    ref.onDispose(() {
      _syncTimer?.cancel();
    });
    _startSyncTimer();

    // Tự động tải lại ngầm (silent) từ API nếu đã có cache, để tránh Shimmer gây cảm giác chậm
    Future.microtask(() => refreshTransactions(silent: initialList.isNotEmpty));

    return initialList;
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final storage = ref.read(localStoreHelperProvider);
      if (storage.getPendingTransactions(userId: userId).isNotEmpty) {
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
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final storage = ref.read(localStoreHelperProvider);
      final pendingList = storage.getPendingTransactions(userId: userId);
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
            transactionDate: tx.transactionDate.toUtc().toIso8601String(),
            currencyCode: tx.currencyCode,
            exchangeRate: tx.exchangeRate,
            timezone: tx.timezone,
            attachment: attachmentFile,
          );

          remainingPending.removeWhere((item) => item.id == tx.id);
          await storage.savePendingTransactions(remainingPending, userId: userId);
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
          await storage.savePendingTransactions(remainingPending, userId: userId);

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

  Future<void> refreshTransactions({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
    final newState = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final useCase = ref.read(getTransactionsUseCaseProvider);
      final filter = ref.read(transactionFilterProvider);
      final result = await useCase.execute(
        search: filter.search,
        startDate: filter.startDate,
        endDate: filter.endDate,
        categoryId: filter.categoryId,
        type: filter.type,
        walletId: filter.walletId,
        minAmount: filter.minAmount,
        maxAmount: filter.maxAmount,
        sortBy: filter.sortBy,
        sortOrder: filter.sortOrder,
        perPage: 20,
        cursor: null,
      );

      final storage = ref.read(localStoreHelperProvider);
      if (filter.isEmpty) {
        storage.saveCachedTransactions(result.items.take(20).toList(), userId: userId);
      }

      ref.read(transactionPaginationProvider.notifier).state = PaginationState(
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        isLoadingMore: false,
      );

      final pendingData = storage.getPendingTransactions(userId: userId);
      if (pendingData.isNotEmpty) {
        _syncPendingTransactions();
      }

      return [...pendingData, ...result.items];
    });
    
    // Nếu chạy silent và gặp lỗi, giữ nguyên danh sách hiện tại thay vì hiện màn hình lỗi
    if (silent && newState.hasError && state.hasValue) {
      return;
    }
    state = newState;
  }

  Future<void> loadMoreTransactions() async {
    final pagination = ref.read(transactionPaginationProvider);
    if (pagination.isLoadingMore || !pagination.hasMore) return;

    ref.read(transactionPaginationProvider.notifier).state =
        pagination.copyWith(isLoadingMore: true);

    try {
      final useCase = ref.read(getTransactionsUseCaseProvider);
      final filter = ref.read(transactionFilterProvider);
      final result = await useCase.execute(
        search: filter.search,
        startDate: filter.startDate,
        endDate: filter.endDate,
        categoryId: filter.categoryId,
        type: filter.type,
        walletId: filter.walletId,
        minAmount: filter.minAmount,
        maxAmount: filter.maxAmount,
        sortBy: filter.sortBy,
        sortOrder: filter.sortOrder,
        perPage: 20,
        cursor: pagination.nextCursor,
      );

      state = AsyncValue.data([
        ...(state.value ?? []),
        ...result.items,
      ]);

      ref.read(transactionPaginationProvider.notifier).state = PaginationState(
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        isLoadingMore: false,
      );
    } catch (e) {
      ref.read(transactionPaginationProvider.notifier).state =
          pagination.copyWith(isLoadingMore: false);
    }
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    state = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final currentList = state.value ?? [];
      final newList = [transaction, ...currentList];
      ref.read(localStoreHelperProvider).saveCachedTransactions(newList.take(20).toList(), userId: userId);
      return newList;
    });
  }

  Future<void> addPendingTransaction(TransactionParams params) async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final storage = ref.read(localStoreHelperProvider);
    final currentPending = storage.getPendingTransactions(userId: userId);

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
    await storage.savePendingTransactions(newPending, userId: userId);

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

    await ref.read(walletNotifierProvider.notifier).refreshWallets();
  }

  Future<void> updateTransaction({
    required String transactionId,
    required String title,
    String? categoryId,
    String? notes,
    List<MultipartFile>? attachments,
  }) async {
    final dio = ref.read(dioClientProvider);

    final Map<String, dynamic> data = {
      'title': title,
      if (categoryId != null) 'category_id': categoryId,
      if (notes != null) 'notes': notes,
      if (attachments != null && attachments.isNotEmpty) ...{
        'attachment': attachments.first.clone(),
        'attachments[]': attachments.map((e) => e.clone()).toList(),
      },
    };

    final formData = FormData.fromMap(data);
    final url = ApiEndpoints.updateTransaction.replaceAll('{id}', transactionId);

    await dio.post(url, data: formData);

    ref.invalidate(transactionListProvider);
    await ref.read(walletNotifierProvider.notifier).refreshWallets();
  }
}

class PaginationState {
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  PaginationState({
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginationState copyWith({
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginationState(
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final transactionPaginationProvider = StateProvider<PaginationState>((ref) => PaginationState());

class TransactionFilter {
  final String? search;
  final String? startDate;
  final String? endDate;
  final String? categoryId;
  final String? type;
  final String? walletId;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy; // 'date', 'amount', 'category'
  final String sortOrder; // 'desc', 'asc'

  TransactionFilter({
    this.search,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.type,
    this.walletId,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'date',
    this.sortOrder = 'desc',
  });

  bool get isEmpty =>
      (search == null || search!.isEmpty) &&
      startDate == null &&
      endDate == null &&
      categoryId == null &&
      type == null &&
      walletId == null &&
      minAmount == null &&
      maxAmount == null &&
      sortBy == 'date' &&
      sortOrder == 'desc';

  TransactionFilter copyWith({
    String? search,
    String? startDate,
    String? endDate,
    String? categoryId,
    String? type,
    String? walletId,
    double? minAmount,
    double? maxAmount,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearDate = false,
    bool clearCategory = false,
    bool clearType = false,
    bool clearWallet = false,
    bool clearAmount = false,
  }) {
    return TransactionFilter(
      search: clearSearch ? null : (search ?? this.search),
      startDate: clearDate ? null : (startDate ?? this.startDate),
      endDate: clearDate ? null : (endDate ?? this.endDate),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      type: clearType ? null : (type ?? this.type),
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      minAmount: clearAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmount ? null : (maxAmount ?? this.maxAmount),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter());

final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<TransactionEntity>>(() {
  return TransactionListNotifier();
});
