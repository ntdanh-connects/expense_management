import 'package:dio/dio.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'report_api_service.g.dart';

@RestApi()
abstract class ReportApiService {
  factory ReportApiService(Dio dio) = _ReportApiService;

  @GET(ApiEndpoints.reportsSummary)
  Future<BaseResponseDto<ReportSummaryDto>> getSummary({
    @Query('start_date') required String startDate,
    @Query('end_date') required String endDate,
    @Query('wallet_id') String? walletId,
  });

  @GET(ApiEndpoints.reportsCategories)
  Future<BaseResponseDto<ReportCategoryDto>> getCategories({
    @Query('month') int? month,
    @Query('year') int? year,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('type') String? type,
  });

  @GET(ApiEndpoints.reportsTrends)
  Future<BaseResponseDto<List<ReportTrendEntryDto>>> getTrends({
    @Query('start_date') required String startDate,
    @Query('end_date') required String endDate,
    @Query('group_by') required String groupBy,
  });
}
