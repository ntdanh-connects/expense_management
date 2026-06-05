import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/profile/data/datasource/remote/category_api_service.dart';
import 'package:expense_management/features/profile/data/repository_impl/category_repository_impl.dart';
import 'package:expense_management/features/profile/domain/repositories/category_repository.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryApiServiceProvider = Provider<CategoryApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CategoryApiService(dio);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiService = ref.watch(categoryApiServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepositoryImpl(apiService, db);
});

class CategoriesNotifier extends AsyncNotifier<List<CategoryDto>> {
  @override
  Future<List<CategoryDto>> build() async {
    ref.watch(localeProvider); // Theo dõi ngôn ngữ để tự động tải lại danh mục khi đổi ngôn ngữ
    final repo = ref.read(categoryRepositoryProvider);
    
    // Tải dữ liệu từ local database trước để UI load lập tức không bị xoay vòng xoay loading
    final localCategories = await repo.getCategoriesFromLocal();
    if (localCategories.isNotEmpty) {
      _fetchRemoteInBackground();
      return localCategories;
    }
    
    // Nếu local rỗng (lần đầu dùng ứng dụng), đợi từ API
    return repo.getCategories();
  }

  Future<void> _fetchRemoteInBackground() async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      final remoteCategories = await repo.getCategories();
      state = AsyncValue.data(remoteCategories);
    } catch (e) {
      // Bỏ qua lỗi ngầm (ví dụ mất kết nối mạng) để giữ nguyên cache local cũ
    }
  }

  Future<void> refreshCategories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(categoryRepositoryProvider);
      return repo.getCategories();
    });
  }

  Future<void> createCategory({
    required String name,
    required String parentId,
    required String icon,
    required String color,
    int? sortOrder,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.createCategory(
      name: name,
      parentId: parentId,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
    );
    await refreshCategories();
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.updateCategory(
      id: id,
      name: name,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
    );
    await refreshCategories();
  }

  Future<void> deleteCategory(String id) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.deleteCategory(id);
    await refreshCategories();
  }

  Future<void> mergeCategories({
    required String fromCategoryId,
    required String toCategoryId,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.mergeCategories(
      fromCategoryId: fromCategoryId,
      toCategoryId: toCategoryId,
    );
    await refreshCategories();
  }
}

final categoriesNotifierProvider = AsyncNotifierProvider<CategoriesNotifier, List<CategoryDto>>(() {
  return CategoriesNotifier();
});

final supportedIconsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getSupportedIcons();
});
