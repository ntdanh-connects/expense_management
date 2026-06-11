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
import 'package:expense_management/core/database/app_database.dart';
import 'package:drift/drift.dart';
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
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';

final transactionApiServiceProvider = Provider<TransactionApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TransactionApiService(dio);
});

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

class TransactionListNotifier extends AsyncNotifier<List<TransactionEntity>> {
  Timer? _syncTimer;
  bool _isSyncing = false;

  void _invalidateBudgets() {
    ref.invalidate(budgetListProvider);
    ref.invalidate(currentMonthBudgetsProvider);
  }

  @override
  FutureOr<List<TransactionEntity>> build() async {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    if (userId.isEmpty) return [];

    final database = ref.read(appDatabaseProvider);
    
    // Đọc cache và các giao dịch đang chờ sync từ Drift DB local
    final cachedRows = await database.getCachedTransactions(userId);
    final pendingRows = await database.getPendingTransactions(userId);
    final categories = await database.getAllCategories();
    final wallets = await database.select(database.wallets).get();

    final cachedData = cachedRows.map((r) => _mapLocalToEntity(r, categories, wallets)).toList();
    final pendingData = pendingRows.map((r) => _mapLocalToEntity(r, categories, wallets)).toList();

    final initialList = [...pendingData, ...cachedData];

    ref.onDispose(() {
      _syncTimer?.cancel();
    });
    _startSyncTimer();

    // Tự động tải lại ngầm (silent) từ API nếu đã có cache và userId hợp lệ
    if (userId.isNotEmpty) {
      Future.microtask(() => refreshTransactions(silent: initialList.isNotEmpty));
    }

    return initialList;
  }

  TransactionEntity _mapLocalToEntity(
    LocalTransaction row,
    List<Category> categories,
    List<Wallet> wallets,
  ) {
    // Look-up category và wallet local để lấy thông tin hiển thị (tên, icon, màu sắc)
    final categoryList = categories.where((c) => c.id == row.categoryId);
    final category = categoryList.isNotEmpty ? categoryList.first : null;

    final walletList = wallets.where((w) => w.id == row.walletId);
    final wallet = walletList.isNotEmpty ? walletList.first : null;

    return TransactionEntity(
      id: row.id,
      walletId: row.walletId,
      categoryId: row.categoryId,
      type: row.type,
      status: row.isSynced ? 'success' : 'pending',
      amount: row.amount,
      currencyCode: wallet?.currencyCode,
      exchangeRate: row.amount > 0 ? (row.amountInUserCurrency / row.amount) : 1.0,
      title: row.title,
      notes: row.notes,
      sourceType: row.sourceType,
      transactionDate: row.transactionDate,
      createdAt: row.createdAt,
      categoryName: category?.name,
      categoryIcon: category?.icon,
      categoryColor: category?.color,
      walletName: wallet?.name,
      walletIcon: wallet?.icon,
      walletColor: wallet?.color,
      attachmentUrls: const [],
    );
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      if (userId.isEmpty) return;
      final database = ref.read(appDatabaseProvider);
      final pending = await database.getPendingTransactions(userId);
      if (pending.isNotEmpty) {
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
      if (userId.isEmpty) return;
      final database = ref.read(appDatabaseProvider);
      
      final pendingRows = await database.getPendingTransactions(userId);
      if (pendingRows.isEmpty) return;

      final categories = await database.getAllCategories();
      final wallets = await database.select(database.wallets).get();
      final pendingList = pendingRows.map((r) => _mapLocalToEntity(r, categories, wallets)).toList();

      final addTxUseCase = ref.read(addTransactionUseCaseProvider);
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

          final newTx = await addTxUseCase.execute(
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

          // Xóa dòng pending cũ khỏi DB và lưu lại transaction mới từ BE trả về
          await database.deleteTransaction(tx.id);
          
          final localTx = LocalTransaction(
            id: newTx.id,
            userId: userId,
            walletId: newTx.walletId,
            categoryId: newTx.categoryId,
            amount: newTx.amount,
            amountInUserCurrency: newTx.amount * (newTx.exchangeRate ?? 1.0),
            type: newTx.type,
            title: newTx.title,
            notes: newTx.notes,
            transactionDate: newTx.transactionDate,
            sourceType: newTx.sourceType,
            createdAt: newTx.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: true,
          );
          await database.saveTransaction(localTx);
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
          // Lỗi nghiệp vụ (bad request/validations...) -> xóa khỏi DB pending để tránh nghẽn
          await database.deleteTransaction(tx.id);

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
        _invalidateBudgets();
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> refreshTransactions({bool silent = false}) async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    if (userId.isEmpty) return;

    if (!silent) {
      await ref.read(cacheStoreProvider).clean();
      state = const AsyncValue.loading();
    }
    final newState = await AsyncValue.guard(() async {
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

      final database = ref.read(appDatabaseProvider);
      final categories = await database.getAllCategories();
      final wallets = await database.select(database.wallets).get();

      ref.read(transactionPaginationProvider.notifier).state = PaginationState(
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        isLoadingMore: false,
      );

      final pendingRows = await database.getPendingTransactions(userId);
      final pendingData = pendingRows.map((r) => _mapLocalToEntity(r, categories, wallets)).toList();
      
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
    final userId = ref.read(currentUserProvider)?.id ?? '';
    if (userId.isEmpty) return;

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
    await ref.read(cacheStoreProvider).clean();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final database = ref.read(appDatabaseProvider);

      final localTx = LocalTransaction(
        id: transaction.id,
        userId: userId,
        walletId: transaction.walletId,
        categoryId: transaction.categoryId,
        amount: transaction.amount,
        amountInUserCurrency: transaction.amount * (transaction.exchangeRate ?? 1.0),
        type: transaction.type,
        title: transaction.title,
        notes: transaction.notes,
        transactionDate: transaction.transactionDate,
        sourceType: transaction.sourceType,
        createdAt: transaction.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: true,
      );
      await database.saveTransaction(localTx);

      final currentList = state.value ?? [];
      final newList = [transaction, ...currentList];
      return newList;
    });
    _invalidateBudgets();
  }

  Future<void> addPendingTransaction(TransactionParams params) async {
    await ref.read(cacheStoreProvider).clean();
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final database = ref.read(appDatabaseProvider);
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final localTx = LocalTransaction(
      id: tempId,
      userId: userId,
      walletId: params.walletId,
      categoryId: params.categoryId.isEmpty ? null : params.categoryId,
      amount: params.amount,
      amountInUserCurrency: params.amount * (params.exchangeRate ?? 1.0),
      type: params.type,
      title: params.title,
      notes: params.notes,
      transactionDate: DateTime.parse(params.transactionDate),
      sourceType: 'manual',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await database.saveTransaction(localTx);

    final categories = await database.getAllCategories();
    final wallets = await database.select(database.wallets).get();
    final tempTx = _mapLocalToEntity(localTx, categories, wallets);

    state = await AsyncValue.guard(() async {
      final currentList = state.value ?? [];
      return [tempTx, ...currentList];
    });

    _invalidateBudgets();
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
    await ref.read(cacheStoreProvider).clean();
    final dio = ref.read(dioClientProvider);
    final url = ApiEndpoints.deleteTransaction.replaceAll('{id}', transactionId);
    await dio.delete(url);

    // Xóa local
    final database = ref.read(appDatabaseProvider);
    await database.deleteTransaction(transactionId);

    state = await AsyncValue.guard(() async {
      final currentList = state.value ?? [];
      return currentList.where((tx) => tx.id != transactionId).toList();
    });

    await ref.read(walletNotifierProvider.notifier).refreshWallets();
    _invalidateBudgets();
  }

  Future<void> updateTransaction({
    required String transactionId,
    required String title,
    String? categoryId,
    String? notes,
    List<MultipartFile>? attachments,
  }) async {
    await ref.read(cacheStoreProvider).clean();
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
    _invalidateBudgets();
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
