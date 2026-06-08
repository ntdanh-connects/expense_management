import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/dashboard/data/models/recurring_rule_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'recurring_api_service.g.dart';

@RestApi()
abstract class RecurringApiService {
  factory RecurringApiService(Dio dio) = _RecurringApiService;

  @GET(ApiEndpoints.recurringRules)
  Future<BaseResponseDto<List<RecurringRuleDto>>> getRules();

  @POST(ApiEndpoints.recurringRulesCreate)
  Future<BaseResponseDto<RecurringRuleDto>> createRule(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiEndpoints.recurringRulesUpdate)
  Future<BaseResponseDto<RecurringRuleDto>> updateRule(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(ApiEndpoints.recurringRulesDelete)
  Future<BaseResponseDto<void>> deleteRule(@Path('id') String id);

  @POST(ApiEndpoints.recurringRulesToggle)
  Future<BaseResponseDto<RecurringRuleDto>> toggleRule(@Path('id') String id);
}
