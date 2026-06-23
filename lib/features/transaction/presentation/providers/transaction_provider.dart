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
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/features/transaction/domain/di/domain_providers.dart';
export 'package:expense_management/features/transaction/domain/di/domain_providers.dart';
import 'package:expense_management/features/transaction/data/di/data_providers.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:expense_management/core/error/error_handler_mixin.dart';

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
    exchangeRate: row.amount > 0
        ? (row.amountInUserCurrency / row.amount)
        : 1.0,
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

class TransactionListNotifier extends AsyncNotifier<List<TransactionEntity>> with ErrorHandlerMixin {
  Timer? _syncTimer;
  bool _isSyncing = false;

  TransactionFilter get currentFilter => TransactionFilter();

  void _invalidateBudgets() {
    ref.invalidate(budgetListProvider);
    ref.invalidate(currentMonthBudgetsProvider);
    // Force rebuild to trigger budget threshold checks
    ref
        .read(currentMonthBudgetsProvider.future)
        .catchError((_) => <BudgetDto>[]);
  }

  @override
  FutureOr<List<TransactionEntity>> build() async {
    final userId = ref.watch(currentUserProvider.select((u) => u?.id)) ?? '';
    if (userId.isEmpty) return [];

    final database = ref.read(appDatabaseProvider);

    final cachedRows = await database.getCachedTransactions(userId);
    final pendingRows = await database.getPendingTransactions(userId);
    final categories = await database.getAllCategories();
    final wallets = await database.select(database.wallets).get();

    final cachedData = cachedRows
        .map((r) => _mapLocalTransactionToEntity(r, categories, wallets))
        .toList();
    final pendingData = pendingRows
        .map((r) => _mapLocalTransactionToEntity(r, categories, wallets))
        .toList();

    final initialList = [...pendingData, ...cachedData];

    ref.onDispose(() {
      _syncTimer?.cancel();
    });
    _startSyncTimer();

    if (userId.isNotEmpty) {
      Future.microtask(
        () => refreshTransactions(silent: initialList.isNotEmpty),
      );
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

  String _deterministicUuid(String input) {
    int h1 = 0x811c9dc5;
    int h2 = 0xcbf29ce4;
    int h3 = 0x5831307b;
    int h4 = 0x12c5b34a;

    for (int i = 0; i < input.length; i++) {
      int char = input.codeUnitAt(i);
      h1 = ((h1 ^ char) * 16777619) & 0xffffffff;
      h2 = ((h2 ^ char) * 0x01000193) & 0xffffffff;
      h3 = ((h3 ^ char) * 19) & 0xffffffff;
      h4 = ((h4 ^ char) * 31) & 0xffffffff;
    }

    final hex =
        h1.toRadixString(16).padLeft(8, '0') +
        h2.toRadixString(16).padLeft(8, '0') +
        h3.toRadixString(16).padLeft(8, '0') +
        h4.toRadixString(16).padLeft(8, '0');

    final part1 = hex.substring(0, 8);
    final part2 = hex.substring(8, 12);
    final part3 = '4${hex.substring(13, 16)}';
    final part4 = '8${hex.substring(17, 20)}';
    final part5 = hex.substring(20, 32);

    return '$part1-$part2-$part3-$part4-$part5';
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
      final pendingList = pendingRows
          .map((r) => _mapLocalTransactionToEntity(r, categories, wallets))
          .toList();

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

          final isNewTransaction = tx.id.startsWith('temp_');

          if (isNewTransaction) {
            final deterministicId = _deterministicUuid(tx.id);
            AppLogger.info(
              "🔄 [Sync] Bắt đầu đồng bộ transaction (Tạo mới): tempId='${tx.id}', deterministicId='$deterministicId', title='${tx.title}', sourceType='${tx.sourceType}'",
            );

            String? activePayeeId = tx.payeeId;
            String? activeSourceType = tx.sourceType;
            if (tx.type == 'income' && (activeSourceType == 'manual' || activeSourceType == null)) {
              activePayeeId = null;
              activeSourceType = 'transfer';
            }

            final newTx = await addTxUseCase.execute(
              id: deterministicId,
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
              payeeId: activePayeeId,
              sourceType: activeSourceType,
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
              isTransferLocked: newTx.isTransferLocked,
            );
            await database.saveTransaction(localTx);
            anySuccess = true;
          } else {
            AppLogger.info(
              "🔄 [Sync] Bắt đầu đồng bộ transaction (Cập nhật): id='${tx.id}', title='${tx.title}', categoryId='${tx.categoryId}'",
            );

            String? activePayeeId = tx.payeeId;
            String? activeSourceType = tx.sourceType;
            if (tx.type == 'income' && (activeSourceType == 'manual' || activeSourceType == null)) {
              activePayeeId = null;
              activeSourceType = 'transfer';
            }

            final repository = ref.read(transactionRepositoryProvider);
            final entity = await repository.updateTransaction(
              id: tx.id,
              title: tx.title,
              categoryId: tx.categoryId,
              notes: tx.notes,
              payeeId: activePayeeId,
              sourceType: activeSourceType,
              type: tx.type,
              attachment: attachmentFile,
            );

            final localTx = LocalTransaction(
              id: entity.id,
              userId: userId,
              walletId: entity.walletId,
              categoryId: entity.categoryId,
              amount: entity.amount,
              amountInUserCurrency:
                  entity.amount * (entity.exchangeRate ?? 1.0),
              type: entity.type,
              title: entity.title,
              notes: entity.notes,
              transactionDate: entity.transactionDate,
              sourceType: entity.sourceType,
              sourceId: entity.sourceId,
              createdAt: entity.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
              isSynced: true,
              payeeId: entity.payeeId,
              payeeName: entity.payeeName,
              payeeAccountNumber: entity.payeeAccountNumber,
              payeeBankName: entity.payeeBankName,
              isTransferLocked: entity.isTransferLocked,
            );
            await database.saveTransaction(localTx);
            anySuccess = true;
          }

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
          _notifySyncResult(tx.title, true);
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
          _notifySyncResult(tx.title, false);
        }
      }

      if (anySuccess) {
        await ref.read(walletNotifierProvider.notifier).refreshWallets();
        await refreshTransactions();
        _invalidateBudgets();
        try {
          await ref
              .read(filteredTransactionListProvider.notifier)
              .refreshTransactions(silent: true);
        } catch (_) {}
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
      final pendingData = pendingRows
          .map((r) => _mapLocalTransactionToEntity(r, categories, wallets))
          .toList();

      final filteredPending = _filterLocalList(
        pendingData,
        filter,
        tzName,
        categories,
      );

      if (pendingData.isNotEmpty) {
        _syncPendingTransactions();
      }

      var items = result.items;
      if (isUncategorized) {
        items = items
            .where(
              (tx) =>
                  (tx.categoryId == null || tx.categoryName == null) &&
                  tx.sourceType?.toLowerCase() != 'transfer',
            )
            .toList();
      }

      // Loại bỏ các giao dịch trùng lặp đã tồn tại ở local pending
      final pendingIds = filteredPending.map((p) => p.id).toSet();
      items = items.where((item) => !pendingIds.contains(item.id)).toList();

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

    ref.read(transactionPaginationProvider.notifier).state = pagination
        .copyWith(isLoadingMore: true);

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
        items = items
            .where(
              (tx) =>
                  (tx.categoryId == null || tx.categoryName == null) &&
                  tx.sourceType?.toLowerCase() != 'transfer',
            )
            .toList();
      }

      // Loại bỏ các giao dịch đã có trong state hiện tại để tránh duplicate
      final existingIds = (state.value ?? []).map((tx) => tx.id).toSet();
      items = items.where((item) => !existingIds.contains(item.id)).toList();

      state = AsyncValue.data([...(state.value ?? []), ...items]);

      ref.read(transactionPaginationProvider.notifier).state = PaginationState(
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        isLoadingMore: false,
      );
    } catch (e) {
      ref.read(transactionPaginationProvider.notifier).state = pagination
          .copyWith(isLoadingMore: false);
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
        amountInUserCurrency:
            transaction.amount * (transaction.exchangeRate ?? 1.0),
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
        isTransferLocked: transaction.isTransferLocked,
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

  Future<String> addPendingTransaction(TransactionParams params, {bool notify = true}) async {
    await ref.read(cacheStoreProvider).clean();
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final database = ref.read(appDatabaseProvider);
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    String? activeSourceType = params.sourceType ?? 'manual';
    String? activePayeeId = params.payeeId;
    String? activePayeeName = params.payeeName;
    String? activePayeeAccountNumber = params.payeeAccountNumber;
    String? activePayeeBankName = params.payeeBankName;

    if (params.type == 'income' && (activeSourceType == 'manual' || activeSourceType == null)) {
      activePayeeId = null;
      activePayeeName = null;
      activePayeeAccountNumber = null;
      activePayeeBankName = null;
      activeSourceType = 'transfer';
    }

    final localTx = LocalTransaction(
      id: tempId,
      userId: userId,
      walletId: params.walletId,
      categoryId: params.categoryId == null || params.categoryId!.isEmpty
          ? null
          : params.categoryId,
      amount: params.amount,
      amountInUserCurrency: params.amount * (params.exchangeRate ?? 1.0),
      type: params.type,
      title: params.title,
      notes: params.notes,
      transactionDate: DateTime.parse(params.transactionDate),
      sourceType: activeSourceType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      payeeId: activePayeeId,
      payeeName: activePayeeName,
      payeeAccountNumber: activePayeeAccountNumber,
      payeeBankName: activePayeeBankName,
      isTransferLocked: false,
    );
    await database.saveTransaction(localTx);

    final categories = await database.getAllCategories();
    final wallets = await database.select(database.wallets).get();
    final tempTx = _mapLocalTransactionToEntity(localTx, categories, wallets);

    state = await AsyncValue.guard(() async {
      final currentList = state.value ?? [];
      return [tempTx, ...currentList];
    });

    if (notify) {
      _notifyTransaction(
        type: params.type,
        amount: params.amount,
        currencyCode: params.currencyCode ?? 'VND',
        walletName: params.walletName,
        title: params.title,
      );
    }

    _invalidateBudgets();
    ref.invalidate(filteredTransactionListProvider);
    _syncPendingTransactions();
    return tempId;
  }

  Future<TransactionEntity> getTransactionById(String transactionId) async {
    if (transactionId.isEmpty) {
      throw Exception('ID giao dịch trống');
    }

    // 1. Check local loaded list (state.value) first
    if (state.value != null) {
      final tx = state.value!.where((t) => t.id == transactionId).firstOrNull;
      if (tx != null) {
        return tx;
      }
    }

    // 2. Check local database (especially for temp_ / pending or offline transactions)
    final database = ref.read(appDatabaseProvider);
    try {
      final localTxRow = await (database.select(database.localTransactions)
            ..where((t) => t.id.equals(transactionId)))
          .getSingleOrNull();
      if (localTxRow != null) {
        final categories = await database.getAllCategories();
        final wallets = await database.select(database.wallets).get();
        return _mapLocalTransactionToEntity(localTxRow, categories, wallets);
      }
    } catch (e) {
      debugPrint('[TransactionNotifier] Local database lookup failed: $e');
    }

    // If it's a temp ID and not found locally, do not query backend
    if (transactionId.startsWith('temp_')) {
      throw Exception('Không tìm thấy giao dịch tạm thời: $transactionId');
    }

    // 3. Fallback to API call
    try {
      final repository = ref.read(transactionRepositoryProvider);
      return await repository.getTransactionById(transactionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        '[TransactionNotifier] getTransactionById error: $e',
        tag: 'TransactionNotifier',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<TransactionEntity?> findTransactionByNotificationMetadata({
    required String type,
    required double amount,
    required String? senderName,
  }) async {
    // 1. Scan in current loaded list (state.value)
    final localList = state.value ?? [];
    for (final tx in localList) {
      if (tx.type == type && (tx.amount - amount).abs() < 0.01) {
        if (senderName != null && tx.title.toLowerCase().contains(senderName.toLowerCase())) {
          return tx;
        }
      }
    }

    // 2. Fetch/Query from remote API
    try {
      final api = ref.read(transactionApiServiceProvider);
      final response = await api.getRemoteTransactions(
        type: type,
        minAmount: amount - 0.01,
        maxAmount: amount + 0.01,
        search: senderName,
      );
      if (response.data != null && response.data!.isNotEmpty) {
        final dto = response.data!.first;
        return TransactionMapper.toEntity(dto);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[TransactionNotifier] findTransactionByNotificationMetadata error: $e',
        tag: 'TransactionNotifier',
        stackTrace: stackTrace,
      );
    }
    return null;
  }


  Future<void> deleteTransaction(String transactionId) async {
    await ref.read(cacheStoreProvider).clean();

    final currentList = state.value ?? [];
    final tx = currentList.where((t) => t.id == transactionId).firstOrNull;

    if (tx != null &&
        (tx.status != 'pending' || !transactionId.startsWith('temp_'))) {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTransaction(transactionId);
    }

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
    String? payeeId,
    String? sourceType,
    String? type,
  }) async {
    await ref.read(cacheStoreProvider).clean();
    final database = ref.read(appDatabaseProvider);

    String? activePayeeId = payeeId;
    String? activeSourceType = sourceType;
    String? activeType = type;

    if (categoryId != null) {
      try {
        final allCategories = await database.getAllCategories();
        final cat = allCategories.where((c) => c.id == categoryId).firstOrNull;
        if (cat != null) {
          activeType = cat.type;
        }
      } catch (_) {}
    }

    if (activePayeeId == null ||
        activeSourceType == null ||
        activeType == null) {
      try {
        final serverTx = await getTransactionById(transactionId);
        activePayeeId ??= serverTx.payeeId;
        activeSourceType ??= serverTx.sourceType;
        activeType ??= serverTx.type;
      } catch (_) {}
    }

    final wallets = await database.select(database.wallets).get();
    final tx = await getTransactionById(transactionId);
    final wallet = wallets.where((w) => w.id == tx.walletId).firstOrNull;
    final isCash = wallet?.type.toLowerCase() == 'cash';

    if (activeType == 'income' && !isCash && (activeSourceType == 'manual' || activeSourceType == null)) {
      activeSourceType = 'transfer';
    }

    try {
      final repository = ref.read(transactionRepositoryProvider);
      final entity = await repository.updateTransaction(
        id: transactionId,
        title: title,
        categoryId: categoryId,
        notes: notes,
        payeeId: activePayeeId,
        sourceType: activeSourceType,
        type: activeType,
        attachment: (attachments != null && attachments.isNotEmpty) ? attachments.first : null,
      );

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
        payeeId: entity.payeeId,
        payeeName: entity.payeeName,
        payeeAccountNumber: entity.payeeAccountNumber,
        payeeBankName: entity.payeeBankName,
        isTransferLocked: entity.isTransferLocked,
      );
      await database.saveTransaction(localTx);
    } catch (e) {
      AppLogger.error('🚨 [updateTransaction] Failed to update transaction: $e');
    }

    ref.invalidate(transactionListProvider);
    ref.invalidate(filteredTransactionListProvider);
    await ref.read(walletNotifierProvider.notifier).refreshWallets();
    _invalidateBudgets();
  }

  Future<void> updateTransactionCategoryOptimistic({
    required String transactionId,
    required String categoryId,
  }) async {
    // 1. Cập nhật local DB ngay lập tức
    final database = ref.read(appDatabaseProvider);
    final userId = ref.read(currentUserProvider)?.id ?? '';

    // Tìm transaction hiện tại từ DB hoặc state để lấy thông tin đầy đủ
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((tx) => tx.id == transactionId);

    TransactionEntity? targetTx;
    if (index != -1) {
      targetTx = currentList[index];
    } else {
      // Fallback từ database nếu không có trong state
      try {
        targetTx = await getTransactionById(transactionId);
      } catch (_) {}
    }

    if (targetTx == null) return;

    // Nếu thông tin người thụ hưởng hoặc nguồn giao dịch bị thiếu do lỗi đồng bộ trước đó, khôi phục từ server
    if (targetTx.payeeId == null || targetTx.sourceType == null) {
      try {
        final serverTx = await getTransactionById(transactionId);
        targetTx = targetTx.copyWith(
          payeeId: serverTx.payeeId,
          payeeName: serverTx.payeeName,
          payeeAccountNumber: serverTx.payeeAccountNumber,
          payeeBankName: serverTx.payeeBankName,
          sourceType: serverTx.sourceType,
        );
      } catch (_) {}
    }

    final tx = targetTx;
    if (tx == null) return;

    // Lấy thông tin chi tiết danh mục mới từ local DB để cập nhật UI
    final allCategories = await database.getAllCategories();
    final newCat = allCategories.where((c) => c.id == categoryId).firstOrNull;
    final newType = newCat?.type ?? tx.type;

    // Determine the source type
    String? resolvedSourceType = tx.sourceType;
    if (newType == 'income' && (resolvedSourceType == 'manual' || resolvedSourceType == null)) {
      resolvedSourceType = 'transfer';
    }

    final updatedEntity = TransactionEntity(
      id: tx.id,
      walletId: tx.walletId,
      categoryId: categoryId,
      type: newType,
      status: 'pending',
      amount: tx.amount,
      currencyCode: tx.currencyCode,
      exchangeRate: tx.exchangeRate,
      title: tx.title,
      notes: tx.notes,
      timezone: tx.timezone,
      sourceType: resolvedSourceType,
      sourceId: tx.sourceId,
      isTransferLocked: tx.isTransferLocked,
      transactionDate: tx.transactionDate,
      createdAt: tx.createdAt,
      categoryName: newCat?.name,
      categoryIcon: newCat?.icon,
      categoryColor: newCat?.color,
      walletName: tx.walletName,
      walletIcon: tx.walletIcon,
      walletColor: tx.walletColor,
      attachmentUrls: tx.attachmentUrls,
      payeeId: newType == 'income' ? null : tx.payeeId,
      payeeName: newType == 'income' ? null : tx.payeeName,
      payeeAccountNumber: newType == 'income' ? null : tx.payeeAccountNumber,
      payeeBankName: newType == 'income' ? null : tx.payeeBankName,
      senderName: tx.senderName,
      senderWalletName: tx.senderWalletName,
      senderIdentifier: tx.senderIdentifier,
    );

    // Cập nhật state list lập tức để UI render thay đổi ngay (kể cả khi index == -1)
    if (state.hasValue) {
      if (index != -1) {
        final newList = List<TransactionEntity>.from(currentList);
        newList[index] = updatedEntity;
        state = AsyncValue.data(newList);
      } else {
        final newList = [updatedEntity, ...currentList];
        state = AsyncValue.data(newList);
      }
    }

    // Lưu DB local với isSynced = false
    final localTx = LocalTransaction(
      id: tx.id,
      userId: userId,
      walletId: tx.walletId,
      categoryId: categoryId,
      amount: tx.amount,
      amountInUserCurrency: tx.amount * (tx.exchangeRate ?? 1.0),
      type: newType,
      title: tx.title,
      notes: tx.notes,
      transactionDate: tx.transactionDate,
      sourceType: resolvedSourceType,
      sourceId: tx.sourceId,
      createdAt: tx.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      payeeId: newType == 'income' ? null : tx.payeeId,
      payeeName: newType == 'income' ? null : tx.payeeName,
      payeeAccountNumber: newType == 'income' ? null : tx.payeeAccountNumber,
      payeeBankName: newType == 'income' ? null : tx.payeeBankName,
      isTransferLocked: tx.isTransferLocked,
    );
    await database.saveTransaction(localTx);

    // Cập nhật in-memory state của filteredTransactionListProvider ngay lập tức
    try {
      final filteredNotifier = ref.read(
        filteredTransactionListProvider.notifier,
      );
      if (filteredNotifier.state.hasValue) {
        final filteredList = filteredNotifier.state.value ?? [];
        final filteredIndex = filteredList.indexWhere(
          (tx) => tx.id == transactionId,
        );

        final filter = ref.read(transactionFilterProvider);
        final tzName =
            ref.read(currentUserProvider)?.timezone ?? 'Asia/Ho_Chi_Minh';
        final match = _filterLocalList(
          [updatedEntity],
          filter,
          tzName,
          allCategories,
        );

        final newFilteredList = List<TransactionEntity>.from(filteredList);
        if (filteredIndex != -1) {
          if (match.isNotEmpty) {
            newFilteredList[filteredIndex] = updatedEntity;
          } else {
            newFilteredList.removeAt(filteredIndex);
          }
          filteredNotifier.state = AsyncValue.data(newFilteredList);
        } else if (match.isNotEmpty) {
          newFilteredList.insert(0, updatedEntity);
          filteredNotifier.state = AsyncValue.data(newFilteredList);
        }
      }
    } catch (_) {}

    // Kích hoạt làm mới các notifier liên quan
    ref.invalidate(filteredTransactionListProvider);
    _invalidateBudgets();

    // Chạy ngầm việc đồng bộ lên server bằng cách sử dụng hàng đợi đồng bộ chung
    _syncPendingTransactions();
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
        notifBody =
            '+$formattedAmount $currencySymbol vào$walletPart. Nội dung: $title';
      } else if (type.toLowerCase() == 'expense') {
        notifBody =
            '-$formattedAmount $currencySymbol từ$walletPart. Nội dung: $title';
      } else if (type.toLowerCase() == 'transfer') {
        notifTitle = 'Chuyển tiền';
        notifBody =
            'Chuyển $formattedAmount $currencySymbol từ$walletPart. Nội dung: $title';
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
          ref
              .read(notificationNotifierProvider.notifier)
              .addLocalNotification(localNotif);
        }
      }
    } catch (_) {}
  }

  void _notifySyncResult(String title, bool isSuccess) async {
    try {
      final notifTitle = isSuccess ? 'Đồng bộ thành công' : 'Đồng bộ thất bại';
      final notifBody = isSuccess
          ? 'Giao dịch "$title" đã được đồng bộ lên máy chủ.'
          : 'Không thể đồng bộ giao dịch "$title" lên máy chủ.';

      await LocalNotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
        title: notifTitle,
        body: notifBody,
      );

      final userId = ref.read(currentUserProvider)?.id ?? '';
      if (userId.isNotEmpty) {
        final localNotif = await LocalNotificationStorage.createAndSave(
          userId: userId,
          type: 'sync',
          title: notifTitle,
          body: notifBody,
        );
        if (localNotif != null) {
          ref
              .read(notificationNotifierProvider.notifier)
              .addLocalNotification(localNotif);
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

final transactionPaginationProvider = StateProvider<PaginationState>(
  (ref) => PaginationState(),
);

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
  int get hashCode => Object.hash(
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
    result = result
        .where(
          (tx) =>
              tx.title.toLowerCase().contains(query) ||
              (tx.notes?.toLowerCase().contains(query) ?? false),
        )
        .toList();
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
          final txTime = tz.TZDateTime.from(
            tx.transactionDate.toUtc(),
            location,
          );
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
          final txTime = tz.TZDateTime.from(
            tx.transactionDate.toUtc(),
            location,
          );
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
        final end = DateTime.parse(filter.endDate!)
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1));
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
      result = result
          .where(
            (tx) =>
                (tx.categoryId == null || tx.categoryName == null) &&
                tx.sourceType?.toLowerCase() != 'transfer',
          )
          .toList();
    } else {
      final childCategoryIds = categories
          .where((c) => c.parentId == filter.categoryId)
          .map((c) => c.id)
          .toList();
      result = result
          .where(
            (tx) =>
                tx.categoryId == filter.categoryId ||
                childCategoryIds.contains(tx.categoryId),
          )
          .toList();
    }
  }

  // 4. Lọc theo loại (income, expense, transfer)
  if (filter.type != null) {
    final typeQuery = filter.type!.toLowerCase();
    if (typeQuery == 'transfer') {
      result = result
          .where(
            (tx) =>
                tx.type.toLowerCase() == 'transfer' ||
                tx.sourceType?.toLowerCase() == 'transfer',
          )
          .toList();
    } else {
      result = result
          .where(
            (tx) =>
                tx.type.toLowerCase() == typeQuery &&
                tx.sourceType?.toLowerCase() != 'transfer',
          )
          .toList();
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
  void _startSyncTimer() {
    // Disable sync timer in FilteredTransactionListNotifier to avoid duplicate syncs
  }

  @override
  Future<void> _syncPendingTransactions() async {
    // Disable direct sync in FilteredTransactionListNotifier to avoid duplicate syncs
  }

  @override
  Future<void> refreshTransactions({bool silent = false}) async {
    if (currentFilter.isEmpty) {
      await ref.read(transactionListProvider.notifier).refreshTransactions(silent: silent);
      return;
    }
    await super.refreshTransactions(silent: silent);
  }

  @override
  FutureOr<List<TransactionEntity>> build() async {
    final userId = ref.watch(currentUserProvider.select((u) => u?.id)) ?? '';
    if (userId.isEmpty) return [];

    final filter = ref.watch(transactionFilterProvider);

    // Dùng chung dữ liệu từ transactionListProvider nếu bộ lọc rỗng để tránh gọi API trùng lặp
    if (filter.isEmpty) {
      final mainState = ref.watch(transactionListProvider);
      return mainState.value ?? [];
    }

    final database = ref.read(appDatabaseProvider);

    final cachedRows = await database.getCachedTransactions(userId);
    final pendingRows = await database.getPendingTransactions(userId);
    final categories = await database.getAllCategories();
    final wallets = await database.select(database.wallets).get();

    final cachedData = cachedRows
        .map((r) => _mapLocalTransactionToEntity(r, categories, wallets))
        .toList();
    final pendingData = pendingRows
        .map((r) => _mapLocalTransactionToEntity(r, categories, wallets))
        .toList();

    final tzName =
        ref.watch(currentUserProvider.select((u) => u?.timezone)) ??
        'Asia/Ho_Chi_Minh';
    final filteredCached = _filterLocalList(
      cachedData,
      filter,
      tzName,
      categories,
    );
    final filteredPending = _filterLocalList(
      pendingData,
      filter,
      tzName,
      categories,
    );

    final initialList = [...filteredPending, ...filteredCached];

    if (userId.isNotEmpty) {
      Future.microtask(
        () => refreshTransactions(silent: initialList.isNotEmpty),
      );
    }

    return initialList;
  }
}

final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => TransactionFilter(),
);

final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<TransactionEntity>>(() {
      return TransactionListNotifier();
    });

final filteredTransactionListProvider =
    AsyncNotifierProvider<
      FilteredTransactionListNotifier,
      List<TransactionEntity>
    >(() {
      return FilteredTransactionListNotifier();
    });
