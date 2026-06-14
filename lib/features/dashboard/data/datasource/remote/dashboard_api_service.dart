import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'dashboard_api_service.g.dart';

@RestApi()
abstract class DashboardApiService {
  factory DashboardApiService(Dio dio) = _DashboardApiService;

  @GET(ApiEndpoints.dashboardSummary)
  Future<BaseResponseDto<DashboardSummaryDto>> getDashboardSummary();
}
