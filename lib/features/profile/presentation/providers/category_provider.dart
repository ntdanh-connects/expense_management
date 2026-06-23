import 'package:expense_management/core/error/error_handler_mixin.dart';
import 'package:expense_management/features/profile/domain/di/domain_providers.dart';
export 'package:expense_management/features/profile/domain/di/domain_providers.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesNotifier extends AsyncNotifier<List<CategoryDto>> with ErrorHandlerMixin {
  @override
  Future<List<CategoryDto>> build() async {
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
    } catch (e, stack) {
      logException(e, stack, tag: 'CategoriesNotifier_background');
    }
  }

  Future<void> refreshCategories() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(categoryRepositoryProvider);
      final remoteCategories = await repo.getCategories();
      state = AsyncValue.data(remoteCategories);
    } catch (e, stackTrace) {
      logException(e, stackTrace, tag: 'CategoriesNotifier_refresh');
      // Nếu load bị lỗi (ví dụ mất mạng khi đổi ngôn ngữ), cố gắng lấy từ database local để fallback tránh màn hình trắng/lỗi
      final repo = ref.read(categoryRepositoryProvider);
      final localCategories = await repo.getCategoriesFromLocal();
      if (localCategories.isNotEmpty) {
        state = AsyncValue.data(localCategories);
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
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
