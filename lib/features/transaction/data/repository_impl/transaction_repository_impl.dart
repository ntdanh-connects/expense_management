import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/features/transaction/data/datasource/remote/transaction_remote_datasource.dart';
import 'package:expense_management/features/transaction/data/mappers/transaction_mapper.dart';
import 'package:expense_management/features/transaction/data/models/transaction_dto.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/domain/entities/paginated_transactions.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/core/utils/app_logger.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionApiService _apiService;
  final Dio _dio;
  final AppDatabase _database;
  final String Function() _getUserId;

  TransactionRepositoryImpl(this._apiService, this._dio, this._database, this._getUserId);

  @override
  Future<PaginatedTransactions> getTransactions({
    String? search,
    String? startDate,
    String? endDate,
    String? categoryId,
    String? type,
    double? minAmount,
    double? maxAmount,
    String? walletId,
    String? sortBy,
    String? sortOrder,
    int? perPage,
    String? cursor,
  }) async {
    try {
      // Dùng Dio trực tiếp để xử lý đúng cả hai dạng response:
      //  1. plain array  (->get())
      //  2. paginator object  (->paginate() / ->cursorPaginate())
      final queryParams = <String, dynamic>{
        if (search != null) 'search': search,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (categoryId != null) 'category_id': categoryId,
        if (type != null) 'type': type,
        if (minAmount != null) 'min_amount': minAmount,
        if (maxAmount != null) 'max_amount': maxAmount,
        if (walletId != null) 'wallet_id': walletId,
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (perPage != null) 'per_page': perPage,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );

      final body = response.data;
      if (body == null) return PaginatedTransactions(items: []);

      // body['data'] có thể là:
      //  • List<dynamic>          → ->get()
      //  • Map {data:[...], ...}  → ->paginate() hoặc ->cursorPaginate()
      final dataField = body['data'];
      List<dynamic> items;
      String? nextCursor;

      if (dataField is List) {
        items = dataField;
      } else if (dataField is Map<String, dynamic>) {
        final nested = dataField['data'];
        items = nested is List ? nested : [];
        final nextPageUrl = dataField['next_page_url'] as String?;
        if (nextPageUrl != null) {
          try {
            final uri = Uri.parse(nextPageUrl);
            nextCursor = uri.queryParameters['cursor'];
          } catch (_) {}
        }
      } else {
        items = [];
      }

      final transactionItems = items
          .map((i) => TransactionMapper.toEntity(
              TransactionDto.fromJson(i as Map<String, dynamic>)))
          .toList();

      // Lưu cache vào DB Drift local
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        final localTxs = transactionItems.map((tx) {
          return LocalTransaction(
            id: tx.id,
            userId: userId,
            walletId: tx.walletId,
            categoryId: tx.categoryId,
            amount: tx.amount,
            amountInUserCurrency: tx.amount * (tx.exchangeRate ?? 1.0),
            type: tx.type,
            title: tx.title,
            notes: tx.notes,
            transactionDate: tx.transactionDate,
            sourceType: tx.sourceType,
            sourceId: tx.sourceId,
            createdAt: tx.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: true,
            payeeId: tx.payeeId,
            payeeName: tx.payeeName,
            payeeAccountNumber: tx.payeeAccountNumber,
            payeeBankName: tx.payeeBankName,
          );
        }).toList();
        
        _database.saveAllTransactions(localTxs).catchError((err) {
          AppLogger.error('🚨 [TransactionRepo] Lỗi lưu cache Drift: $err', tag: 'TransactionRepo');
        });
      }

      return PaginatedTransactions(
        items: transactionItems,
        nextCursor: nextCursor,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [TransactionRepo] getTransactions error: $e',
        tag: 'TransactionRepo',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<TransactionEntity> createTransaction({
    required String walletId,
    String? categoryId,
    required String type,
    required double amount,
    required String title,
    String? notes,
    String? transactionDate,
    String? currencyCode,
    double? exchangeRate,
    String? timezone,
    MultipartFile? attachment,
    String? payeeId,
  }) async {
    try {
      final response = await _apiService.createRemoteTransaction(
        walletId: walletId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        title: title,
        notes: notes,
        transactionDate: transactionDate,
        currencyCode: currencyCode,
        exchangeRate: exchangeRate,
        timezone: timezone,
        attachment: attachment,
        payeeId: payeeId,
      );
      return TransactionMapper.toEntity(response.data);
    } catch (e, stackTrace) {
      AppLogger.error(
        '🚨 [TransactionRepo] createTransaction error: $e',
        tag: 'TransactionRepo',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
