import 'package:dio/dio.dart';
import 'package:expense_management/core/error/app_exception.dart';
import 'package:expense_management/core/network/network_exception_mapper.dart';
import 'package:expense_management/features/profile/data/datasource/remote/category_api_service.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/domain/repositories/category_repository.dart';
import 'package:expense_management/core/database/app_database.dart' as db;

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryApiService _apiService;
  final db.AppDatabase _db;

  CategoryRepositoryImpl(this._apiService, this._db);

  @override
  Future<List<CategoryDto>> getCategoriesFromLocal() async {
    final rows = await _db.getAllCategories();
    return _reconstructTree(rows);
  }

  @override
  Future<List<CategoryDto>> getCategories() async {
    try {
      final response = await _apiService.getCategories();
      final remoteDtos = response.data;
      
      // Flatten the tree and save to local db
      final flatRows = _flattenCategories(remoteDtos);
      await _db.saveAllCategories(flatRows);
      
      return remoteDtos;
    } on DioException catch (e) {
      throw AppException(e.toNetworkFailure());
    }
  }

  List<db.Category> _flattenCategories(List<CategoryDto> dtos) {
    final List<db.Category> flat = [];
    for (final dto in dtos) {
      flat.add(db.Category(
        id: dto.id,
        userId: dto.userId,
        parentId: dto.parentId,
        type: dto.type,
        name: dto.name,
        icon: dto.icon,
        color: dto.color,
        sortOrder: dto.sortOrder,
        isDefault: dto.isDefault,
      ));
      if (dto.children != null && dto.children!.isNotEmpty) {
        flat.addAll(_flattenCategories(dto.children!));
      }
    }
    return flat;
  }

  List<CategoryDto> _reconstructTree(List<db.Category> flatRows) {
    final Map<String?, List<db.Category>> grouped = {};
    for (final row in flatRows) {
      grouped.putIfAbsent(row.parentId, () => []).add(row);
    }

    CategoryDto buildDto(db.Category row) {
      final childrenRows = grouped[row.id] ?? [];
      childrenRows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final children = childrenRows.map(buildDto).toList();

      return CategoryDto(
        id: row.id,
        userId: row.userId,
        parentId: row.parentId,
        type: row.type,
        name: row.name,
        icon: row.icon,
        color: row.color,
        sortOrder: row.sortOrder,
        isDefault: row.isDefault,
        children: children.isEmpty ? null : children,
      );
    }

    final rootRows = grouped[null] ?? [];
    rootRows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rootRows.map(buildDto).toList();
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

  @override
  Future<String?> classifyCategory({
    String? title,
    String? notes,
    required String type,
  }) async {
    try {
      final body = {
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
        'type': type,
      };
      final response = await _apiService.classifyCategory(body);
      return response.data.categoryId;
    } on DioException catch (e) {
      throw AppException(e.toNetworkFailure());
    }
  }
}
