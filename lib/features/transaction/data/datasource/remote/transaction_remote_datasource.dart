import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/transaction/data/models/transaction_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'transaction_remote_datasource.g.dart';

@RestApi()
abstract class TransactionApiService {
  factory TransactionApiService(Dio dio) = _TransactionApiService;

  @GET(ApiEndpoints.transactions)
  Future<BaseResponseDto<List<TransactionDto>>> getRemoteTransactions({
    @Query('search') String? search,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('category_id') String? categoryId,
    @Query('type') String? type,
    @Query('min_amount') double? minAmount,
    @Query('max_amount') double? maxAmount,
    @Query('wallet_id') String? walletId,
    @Query('sort_by') String? sortBy,
    @Query('sort_order') String? sortOrder,
    @Query('per_page') int? perPage,
  });

  @POST(ApiEndpoints.transactions)
  @MultiPart()
  Future<BaseResponseDto<TransactionDto>> createRemoteTransaction({
    @Part(name: 'wallet_id') required String walletId,
    @Part(name: 'category_id') String? categoryId,
    @Part(name: 'type') required String type,
    @Part(name: 'amount') required double amount,
    @Part(name: 'title') required String title,
    @Part(name: 'notes') String? notes,
    @Part(name: 'transaction_date') String? transactionDate,
    @Part(name: 'currency_code') String? currencyCode,
    @Part(name: 'exchange_rate') double? exchangeRate,
    @Part(name: 'timezone') String? timezone,
    @Part(name: 'attachment') MultipartFile? attachment,
    @Part(name: 'payee_id') String? payeeId,
  });
}
