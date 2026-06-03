import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';
import 'package:expense_management/core/network/base_response_dto.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'category_api_service.g.dart';

@RestApi()
abstract class CategoryApiService {
  factory CategoryApiService(Dio dio) = _CategoryApiService;

  @GET(ApiEndpoints.categories)
  Future<BaseResponseDto<List<CategoryDto>>> getCategories();

  @GET(ApiEndpoints.categoryIcons)
  Future<BaseResponseDto<List<String>>> getSupportedIcons();

  @POST(ApiEndpoints.categories)
  Future<BaseResponseDto<CategoryDto>> createCategory(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.updateCategory)
  Future<BaseResponseDto<CategoryDto>> updateCategory(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(ApiEndpoints.deleteCategory)
  Future<BaseResponseDto<void>> deleteCategory(@Path('id') String id);

  @POST(ApiEndpoints.mergeCategories)
  Future<BaseResponseDto<void>> mergeCategories(@Body() Map<String, dynamic> body);
}
