import 'package:dio/dio.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'budget_api_service.g.dart';

@RestApi()
abstract class BudgetApiService {
  factory BudgetApiService(Dio dio) = _BudgetApiService;

  @GET('api/budgets')
  Future<BaseResponseDto<List<BudgetDto>>> getBudgets(
    @Query('month') int month,
    @Query('year') int year,
  );

  @POST('api/budgets')
  Future<BaseResponseDto<BudgetDto>> createOrUpdateBudget(
    @Body() Map<String, dynamic> body,
  );

  @DELETE('api/budgets/{id}')
  Future<BaseResponseDto<void>> deleteBudget(
    @Path('id') String id,
  );

  @POST('api/budgets/copy')
  Future<BaseResponseDto<List<BudgetDto>>> copyBudgets(
    @Body() Map<String, dynamic> body,
  );
}
