import 'package:dio/dio.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/budget/data/data_source/remote/budget_api_service.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetApiService _apiService;

  BudgetRepositoryImpl(this._apiService);

  @override
  Future<List<BudgetDto>> getBudgets(int month, int year) async {
    try {
      final response = await _apiService.getBudgets(month, year);
      return response.data;
    } on DioException catch (e, stackTrace) {
      final serverError = e.response?.data?['message'] ?? e.message;
      AppLogger.error("🚨 [Budget-Repo] Lỗi getBudgets: $serverError", tag: "Budget", stackTrace: stackTrace, details: e.response?.data);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [Budget-Repo] Lỗi getBudgets không xác định: $e", tag: "Budget", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<BudgetDto> createOrUpdateBudget({
    String? categoryId,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _apiService.createOrUpdateBudget({
        if (categoryId != null) 'category_id': categoryId,
        'limit_amount': limitAmount,
        'month': month,
        'year': year,
      });
      return response.data;
    } on DioException catch (e, stackTrace) {
      final serverError = e.response?.data?['message'] ?? e.message;
      AppLogger.error("🚨 [Budget-Repo] Lỗi createOrUpdateBudget: $serverError", tag: "Budget", stackTrace: stackTrace, details: e.response?.data);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [Budget-Repo] Lỗi createOrUpdateBudget không xác định: $e", tag: "Budget", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _apiService.deleteBudget(id);
    } on DioException catch (e, stackTrace) {
      final serverError = e.response?.data?['message'] ?? e.message;
      AppLogger.error("🚨 [Budget-Repo] Lỗi deleteBudget: $serverError", tag: "Budget", stackTrace: stackTrace, details: e.response?.data);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [Budget-Repo] Lỗi deleteBudget không xác định: $e", tag: "Budget", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<BudgetDto>> copyBudgets({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) async {
    try {
      final response = await _apiService.copyBudgets({
        'from_month': fromMonth,
        'from_year': fromYear,
        'to_month': toMonth,
        'to_year': toYear,
      });
      return response.data;
    } on DioException catch (e, stackTrace) {
      final serverError = e.response?.data?['message'] ?? e.message;
      AppLogger.error("🚨 [Budget-Repo] Lỗi copyBudgets: $serverError", tag: "Budget", stackTrace: stackTrace, details: e.response?.data);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [Budget-Repo] Lỗi copyBudgets không xác định: $e", tag: "Budget", stackTrace: stackTrace);
      rethrow;
    }
  }
}
