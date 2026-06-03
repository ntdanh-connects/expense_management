import 'package:expense_management/features/profile/data/models/category_dto.dart';

abstract class CategoryRepository {
  Future<List<CategoryDto>> getCategories();
  Future<List<String>> getSupportedIcons();
  Future<CategoryDto> createCategory({
    required String name,
    required String parentId,
    required String icon,
    required String color,
    int? sortOrder,
  });
  Future<CategoryDto> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  });
  Future<void> deleteCategory(String id);
  Future<void> mergeCategories({
    required String fromCategoryId,
    required String toCategoryId,
  });
}
