import 'package:dio/dio.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/network/network_exception_mapper.dart';
import 'package:expense_management/features/profile/data/datasource/remote/category_api_service.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryApiService _apiService;

  CategoryRepositoryImpl(this._apiService);

  @override
  Future<List<CategoryDto>> getCategories() async {
    try {
      final response = await _apiService.getCategories();
      return response.data;
    } on DioException catch (e) {
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<List<String>> getSupportedIcons() async {
    try {
      final response = await _apiService.getSupportedIcons();
      return response.data;
    } on DioException catch (e) {
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<CategoryDto> createCategory({
    required String name,
    required String parentId,
    required String icon,
    required String color,
    int? sortOrder,
  }) async {
    try {
      final body = {
        'name': name,
        'parent_id': parentId,
        'icon': icon,
        'color': color,
        if (sortOrder != null) 'sort_order': sortOrder,
      };
      final response = await _apiService.createCategory(body);
      return response.data;
    } on DioException catch (e) {
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<CategoryDto> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    try {
      final body = {
        if (name != null) 'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        if (sortOrder != null) 'sort_order': sortOrder,
      };
      final response = await _apiService.updateCategory(id, body);
      return response.data;
    } on DioException catch (e) {
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _apiService.deleteCategory(id);
    } on DioException catch (e) {
      throw AppException(e.toNetworkFailure());
    }
  }

  @override
  Future<void> mergeCategories({
    required String fromCategoryId,
    required String toCategoryId,
  }) async {
    try {
      final body = {
        'from_category_id': fromCategoryId,
        'to_category_id': toCategoryId,
      };
      await _apiService.mergeCategories(body);
    } on DioException catch (e) {
      throw AppException(e.toNetworkFailure());
    }
  }
}
