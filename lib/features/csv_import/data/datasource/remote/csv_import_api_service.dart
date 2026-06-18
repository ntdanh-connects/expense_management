import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:retrofit/retrofit.dart';

part 'csv_import_api_service.g.dart';

@RestApi()
abstract class CsvImportApiService {
  factory CsvImportApiService(Dio dio) = _CsvImportApiService;

  @POST(ApiEndpoints.importTransactions)
  @MultiPart()
  Future<dynamic> importCsv(
    @Part(name: "file") MultipartFile file,
  );

  @GET(ApiEndpoints.listImports)
  Future<dynamic> listImports(
    @Query("page") int page,
  );
}
