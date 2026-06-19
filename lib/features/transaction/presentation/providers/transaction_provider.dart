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
import 'package:expense_management/features/transaction/data/datasource/remote/transaction_remote_datasource.dart';
import 'package:expense_management/features/transaction/data/repository_impl/transaction_repository_impl.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/features/transaction/domain/use_case/add_transaction_usecase.dart';
import 'package:expense_management/features/transaction/domain/use_case/get_transactions_usecase.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';

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

TransactionEntity _mapLocalTransactionToEntity(
    LocalTransaction row,
    List<Category> categories,
    List<Wallet> wallets,
  ) {
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
      sourceId: row.sourceId,
      transactionDate: row.transactionDate,
      createdAt: row.createdAt,
      categoryName: category?.name,
      categoryIcon: category?.icon,
      categoryColor: category?.color,
      walletName: wallet?.name,
      walletIcon: wallet?.icon,
      walletColor: wallet?.color,
      attachmentUrls: const [],
      payeeId: row.payeeId,
      payeeName: row.payeeName,
      payeeAccountNumber: row.payeeAccountNumber,
      payeeBankName: row.payeeBankName,
    );
  }

class TransactionListNotifier extends AsyncNotifier<List<TransactionEntity>> {
  Timer? _syncTimer;
  bool _isSyncing = false;

  TransactionFilter get currentFilter => TransactionFilter();

  void _invalidateBudgets() {
    ref.invalidate(budgetListProvider);
    ref.invalidate(currentMonthBudgetsProvider);
    // Force rebuild to trigger budget threshold checks
    ref.read(currentMonthBudgetsProvider.future).catchError((_) => []);
  }

  @override
  FutureOr<List<TransactionEntity>> build() async {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    if (userId.isEmpty) return [];

    final database = ref.read(appDatabaseProvider);
    
    final cachedRows = await database.getCachedTransactions(userId);
    final pendingRows = await database.getPendingTransactions(userId);
    final categories = await database.getAllCategories();
    final wallets = await database.select(database.wallets).get();

    final cachedData = cachedRows.map((r) => _mapLocalTransactionToEntity(r, categories, wallets)).toList();
    final pendingData = pendingRows.map((r) => _mapLocalTransactionToEntity(r, categories, wallets)).toList();

    final initialList = [...pendingData, ...cachedData];

    ref.onDispose(() {
      _syncTimer?.cancel();
    });
    _startSyncTimer();

    if (userId.isNotEmpty) {
      Future.microtask(() => refreshTransactions(silent: initialList.isNotEmpty));
    }

    return initialList;
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
      final pendingList = pendingRows.map((r) => _mapLocalTransactionToEntity(r, categories, wallets)).toList();

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

          AppLogger.info("🔄 [Sync] Bắt đầu đồng bộ transaction: title='${tx.title}', sourceType='${tx.sourceType}', walletId='${tx.walletId}', payeeId='${tx.payeeId}'");

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
            payeeId: tx.payeeId,
            sourceType: tx.sourceType,
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
            sourceId: newTx.sourceId,
            createdAt: newTx.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: true,
            payeeId: newTx.payeeId,
            payeeName: newTx.payeeName,
            payeeAccountNumber: newTx.payeeAccountNumber,
            payeeBankName: newTx.payeeBankName,
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

    // Chặn request trùng lặp nếu đang trong quá trình tải dữ liệu
    if (state.isLoading) return;

    if (!silent) {
      await ref.read(cacheStoreProvider).clean();
      state = const AsyncValue.loading();
    }
    final newState = await AsyncValue.guard(() async {
      final useCase = ref.read(getTransactionsUseCaseProvider);
      final filter = currentFilter;
      final isUncategorized = filter.categoryId == 'uncategorized';
      
      final result = await useCase.execute(
        search: filter.search,
        startDate: filter.startDate,
        endDate: filter.endDate,
        categoryId: isUncategorized ? null : filter.categoryId,
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

      final user = ref.read(currentUserProvider);
      final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
      final pendingRows = await database.getPendingTransactions(userId);
      final pendingData = pendingRows.map((r) => _mapLocalTransactionToEntity(r, categories, wallets)).toList();
      
      final filteredPending = _filterLocalList(pendingData, filter, tzName, categories);
      
      if (pendingData.isNotEmpty) {
        _syncPendingTransactions();
      }

      var items = result.items;
      if (isUncategorized) {
        items = items.where((tx) => tx.categoryId == null || tx.categoryName == null).toList();
      }

      return [...filteredPending, ...items];
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
      final filter = currentFilter;
      final isUncategorized = filter.categoryId == 'uncategorized';
      
      final result = await useCase.execute(
        search: filter.search,
        startDate: filter.startDate,
        endDate: filter.endDate,
        categoryId: isUncategorized ? null : filter.categoryId,
        type: filter.type,
        walletId: filter.walletId,
        minAmount: filter.minAmount,
        maxAmount: filter.maxAmount,
        sortBy: filter.sortBy,
        sortOrder: filter.sortOrder,
        perPage: 20,
        cursor: pagination.nextCursor,
      );

      var items = result.items;
      if (isUncategorized) {
        items = items.where((tx) => tx.categoryId == null || tx.categoryName == null).toList();
      }

      state = AsyncValue.data([
        ...(state.value ?? []),
        ...items,
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
        sourceId: transaction.sourceId,
        createdAt: transaction.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: true,
        payeeId: transaction.payeeId,
        payeeName: transaction.payeeName,
        payeeAccountNumber: transaction.payeeAccountNumber,
        payeeBankName: transaction.payeeBankName,
      );
      await database.saveTransaction(localTx);

      final currentList = state.value ?? [];
      final newList = [transaction, ...currentList];
      return newList;
    });

    _notifyTransaction(
      type: transaction.type,
      amount: transaction.amount,
      currencyCode: transaction.currencyCode ?? 'VND',
      walletName: transaction.walletName,
      title: transaction.title,
    );

    _invalidateBudgets();
    ref.invalidate(filteredTransactionListProvider);
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
      sourceType: params.sourceType ?? 'manual',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      payeeId: params.payeeId,
      payeeName: params.payeeName,
      payeeAccountNumber: params.payeeAccountNumber,
      payeeBankName: params.payeeBankName,
    );
    await database.saveTransaction(localTx);

    final categories = await database.getAllCategories();
    final wallets = await database.select(database.wallets).get();
    final tempTx = _mapLocalTransactionToEntity(localTx, categories, wallets);

    state = await AsyncValue.guard(() async {
      final currentList = state.value ?? [];
      return [tempTx, ...currentList];
    });

    _notifyTransaction(
      type: params.type,
      amount: params.amount,
      currencyCode: params.currencyCode ?? 'VND',
      walletName: params.walletName,
      title: params.title,
    );

    _invalidateBudgets();
    ref.invalidate(filteredTransactionListProvider);
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
    ref.invalidate(filteredTransactionListProvider);
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
    final response = await dio.post(url, data: formData);

    try {
      final responseData = response.data;
      if (responseData != null && responseData['data'] != null) {
        final dto = TransactionDto.fromJson(responseData['data'] as Map<String, dynamic>);
        final entity = TransactionMapper.toEntity(dto);
        final database = ref.read(appDatabaseProvider);
        final userId = ref.read(currentUserProvider)?.id ?? '';
        
        final localTx = LocalTransaction(
          id: entity.id,
          userId: userId,
          walletId: entity.walletId,
          categoryId: entity.categoryId,
          amount: entity.amount,
          amountInUserCurrency: entity.amount * (entity.exchangeRate ?? 1.0),
          type: entity.type,
          title: entity.title,
          notes: entity.notes,
          transactionDate: entity.transactionDate,
          sourceType: entity.sourceType,
          sourceId: entity.sourceId,
          createdAt: entity.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );
        await database.saveTransaction(localTx);
      }
    } catch (e) {
      AppLogger.error('🚨 [updateTransaction] Failed to update local DB: $e');
    }

    ref.invalidate(transactionListProvider);
    ref.invalidate(filteredTransactionListProvider);
    await ref.read(walletNotifierProvider.notifier).refreshWallets();
    _invalidateBudgets();
  }

  void _notifyTransaction({
    required String type,
    required double amount,
    required String currencyCode,
    required String? walletName,
    required String title,
  }) async {
    try {
      final currencySymbol = AppConstant.getCurrencySymbol(currencyCode);
      final formattedAmount = AppConstant.formatMoney(amount, currencyCode);
      final walletPart = walletName != null ? ' ví "$walletName"' : '';

      String notifTitle = 'Biến động số dư';
      String notifBody = '';

      if (type.toLowerCase() == 'income') {
        notifBody = '+$formattedAmount $currencySymbol vào$walletPart. Nội dung: $title';
      } else if (type.toLowerCase() == 'expense') {
        notifBody = '-$formattedAmount $currencySymbol từ$walletPart. Nội dung: $title';
      } else if (type.toLowerCase() == 'transfer') {
        notifTitle = 'Chuyển tiền';
        notifBody = 'Chuyển $formattedAmount $currencySymbol từ$walletPart. Nội dung: $title';
      } else {
        notifBody = 'Giao dịch mới: $formattedAmount $currencySymbol - $title';
      }

      await LocalNotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
        title: notifTitle,
        body: notifBody,
      );

      final userId = ref.read(currentUserProvider)?.id ?? '';
      if (userId.isNotEmpty) {
        final localNotif = await LocalNotificationStorage.createAndSave(
          userId: userId,
          type: 'transaction',
          title: notifTitle,
          body: notifBody,
        );
        if (localNotif != null) {
          ref.read(notificationNotifierProvider.notifier).addLocalNotification(localNotif);
        }
      }
    } catch (_) {}
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          categoryId == other.categoryId &&
          type == other.type &&
          walletId == other.walletId &&
          minAmount == other.minAmount &&
          maxAmount == other.maxAmount &&
          sortBy == other.sortBy &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      Object.hash(
        search,
        startDate,
        endDate,
        categoryId,
        type,
        walletId,
        minAmount,
        maxAmount,
        sortBy,
        sortOrder,
      );
}

List<TransactionEntity> _filterLocalList(
  List<TransactionEntity> list,
  TransactionFilter filter,
  String tzName,
  List<Category> categories,
) {
  var result = List<TransactionEntity>.from(list);

  // 1. Tìm kiếm theo tiêu đề hoặc ghi chú (không phân biệt hoa thường)
  if (filter.search != null && filter.search!.isNotEmpty) {
    final query = filter.search!.toLowerCase();
    result = result.where((tx) =>
        tx.title.toLowerCase().contains(query) ||
        (tx.notes?.toLowerCase().contains(query) ?? false)).toList();
  }

  // 2. Lọc theo khoảng ngày
  if (filter.startDate != null || filter.endDate != null) {
    try {
      final location = tz.getLocation(tzName);
      if (filter.startDate != null) {
        final parsed = DateTime.parse(filter.startDate!);
        final startPart = parsed.isUtc
            ? tz.TZDateTime.from(parsed, location)
            : tz.TZDateTime(location, parsed.year, parsed.month, parsed.day);
        final start = tz.TZDateTime(
          location,
          startPart.year,
          startPart.month,
          startPart.day,
        );
        result = result.where((tx) {
          final txTime = tz.TZDateTime.from(tx.transactionDate.toUtc(), location);
          return txTime.isAfter(start) || txTime.isAtSameMomentAs(start);
        }).toList();
      }
      if (filter.endDate != null) {
        final parsed = DateTime.parse(filter.endDate!);
        final endPart = parsed.isUtc
            ? tz.TZDateTime.from(parsed, location)
            : tz.TZDateTime(location, parsed.year, parsed.month, parsed.day);
        final end = tz.TZDateTime(
          location,
          endPart.year,
          endPart.month,
          endPart.day,
          23,
          59,
          59,
          999,
        );
        result = result.where((tx) {
          final txTime = tz.TZDateTime.from(tx.transactionDate.toUtc(), location);
          return txTime.isBefore(end) || txTime.isAtSameMomentAs(end);
        }).toList();
      }
    } catch (_) {
      if (filter.startDate != null) {
        final start = DateTime.parse(filter.startDate!);
        result = result.where((tx) {
          final txLocal = tx.transactionDate.toLocal();
          return txLocal.isAfter(start) || txLocal.isAtSameMomentAs(start);
        }).toList();
      }
      if (filter.endDate != null) {
        final end = DateTime.parse(filter.endDate!).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
        result = result.where((tx) {
          final txLocal = tx.transactionDate.toLocal();
          return txLocal.isBefore(end) || txLocal.isAtSameMomentAs(end);
        }).toList();
      }
    }
  }

  // 3. Lọc theo danh mục (bao gồm cả danh mục con trực thuộc danh mục được chọn)
  if (filter.categoryId != null) {
    if (filter.categoryId == 'uncategorized') {
      result = result.where((tx) => tx.categoryId == null || tx.categoryName == null).toList();
    } else {
      final childCategoryIds = categories
          .where((c) => c.parentId == filter.categoryId)
          .map((c) => c.id)
          .toList();
      result = result.where((tx) =>
          tx.categoryId == filter.categoryId ||
          childCategoryIds.contains(tx.categoryId)).toList();
    }
  }

  // 4. Lọc theo loại (income, expense, transfer)
  if (filter.type != null) {
    final typeQuery = filter.type!.toLowerCase();
    if (typeQuery == 'transfer') {
      result = result.where((tx) => tx.type.toLowerCase() == 'transfer' || tx.sourceType?.toLowerCase() == 'transfer').toList();
    } else {
      result = result.where((tx) => tx.type.toLowerCase() == typeQuery && tx.sourceType?.toLowerCase() != 'transfer').toList();
    }
  }

  // 5. Lọc theo ví
  if (filter.walletId != null) {
    result = result.where((tx) => tx.walletId == filter.walletId).toList();
  }

  // 6. Lọc theo số tiền tối thiểu/tối đa
  if (filter.minAmount != null) {
    result = result.where((tx) => tx.amount >= filter.minAmount!).toList();
  }
  if (filter.maxAmount != null) {
    result = result.where((tx) => tx.amount <= filter.maxAmount!).toList();
  }

  // 7. Sắp xếp theo lựa chọn
  result.sort((a, b) {
    final aPending = a.status == 'pending';
    final bPending = b.status == 'pending';
    if (aPending && !bPending) return -1;
    if (!aPending && bPending) return 1;

    int comparison = 0;
    if (filter.sortBy == 'amount') {
      comparison = a.amount.compareTo(b.amount);
    } else if (filter.sortBy == 'category') {
      comparison = (a.categoryName ?? '').compareTo(b.categoryName ?? '');
    } else {
      comparison = a.transactionDate.compareTo(b.transactionDate);
    }

    return filter.sortOrder == 'asc' ? comparison : -comparison;
  });

  return result;
}

class FilteredTransactionListNotifier extends TransactionListNotifier {
  @override
  TransactionFilter get currentFilter => ref.read(transactionFilterProvider);

  @override
  FutureOr<List<TransactionEntity>> build() async {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    if (userId.isEmpty) return [];

    final filter = ref.watch(transactionFilterProvider);

    final database = ref.read(appDatabaseProvider);
    
    final cachedRows = await database.getCachedTransactions(userId);
    final pendingRows = await database.getPendingTransactions(userId);
    final categories = await database.getAllCategories();
    final wallets = await database.select(database.wallets).get();

    final cachedData = cachedRows.map((r) => _mapLocalTransactionToEntity(r, categories, wallets)).toList();
    final pendingData = pendingRows.map((r) => _mapLocalTransactionToEntity(r, categories, wallets)).toList();

    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    final filteredCached = _filterLocalList(cachedData, filter, tzName, categories);
    final filteredPending = _filterLocalList(pendingData, filter, tzName, categories);

    final initialList = [...filteredPending, ...filteredCached];

    ref.onDispose(() {
      _syncTimer?.cancel();
    });
    _startSyncTimer();

    if (userId.isNotEmpty) {
      Future.microtask(() => refreshTransactions(silent: initialList.isNotEmpty));
    }

    return initialList;
  }
}

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter());

final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<TransactionEntity>>(() {
  return TransactionListNotifier();
});

final filteredTransactionListProvider =
    AsyncNotifierProvider<FilteredTransactionListNotifier, List<TransactionEntity>>(() {
  return FilteredTransactionListNotifier();
});
