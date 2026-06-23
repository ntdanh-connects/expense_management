import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:expense_management/core/network/api_endpoints.dart';

part 'reporting_export_api_service.g.dart';

@RestApi()
abstract class ReportingExportApiService {
  factory ReportingExportApiService(Dio dio) = _ReportingExportApiService;

  @POST(ApiEndpoints.exportTransactions)
  Future<dynamic> requestExport(
    @Body() Map<String, dynamic> body,
  );

  @GET(ApiEndpoints.listExports)
  Future<dynamic> listExports({
    @Query('page') int? page,
  });

  @DELETE('${ApiEndpoints.listExports}/{id}')
  Future<dynamic> deleteExport(
    @Path('id') String id,
  );

  @DELETE(ApiEndpoints.listExports)
  Future<dynamic> clearAllExports();
}
