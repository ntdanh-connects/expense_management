import 'package:expense_management/features/savings/data/datasource/remote/savings_api_service.dart';
import 'package:expense_management/features/savings/data/models/savings_goal_dto.dart';
import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';
import 'package:expense_management/features/savings/domain/repository/savings_repository.dart';
import 'package:expense_management/core/utils/app_logger.dart';

class SavingsRepositoryImpl implements SavingsRepository {
  final SavingsApiService _apiService;

  SavingsRepositoryImpl(this._apiService);

  @override
  Future<List<SavingsGoalEntity>> getSavingsGoals() async {
    try {
      final response = await _apiService.getSavingsGoals();
      final List<dynamic> dataList = response['data'] ?? [];
      return dataList
          .map((json) => SavingsGoalDto.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SavingsRepository] Lỗi lấy danh sách mục tiêu: $e", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<SavingsGoalEntity> createSavingsGoal({
    required String name,
    required double targetAmount,
    String? targetDate,
    String? autoSaveFrequency,
    double? autoSaveAmount,
    String? sourceWalletId,
  }) async {
    try {
      final response = await _apiService.createSavingsGoal({
        'name': name,
        'target_amount': targetAmount,
        if (targetDate != null) 'target_date': targetDate,
        if (autoSaveFrequency != null) 'auto_save_frequency': autoSaveFrequency,
        if (autoSaveAmount != null) 'auto_save_amount': autoSaveAmount,
        if (sourceWalletId != null) 'source_wallet_id': sourceWalletId,
      });
      final dataMap = response['data'] as Map<String, dynamic>;
      return SavingsGoalDto.fromJson(dataMap).toEntity();
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SavingsRepository] Lỗi tạo mục tiêu tiết kiệm: $e", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<SavingsGoalEntity> getSavingsGoalDetail(String id) async {
    try {
      final response = await _apiService.getSavingsGoalDetail(id);
      final dataMap = response['data'] as Map<String, dynamic>;
      return SavingsGoalDto.fromJson(dataMap).toEntity();
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SavingsRepository] Lỗi lấy chi tiết mục tiêu: $e", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<SavingsGoalEntity> depositSavingsGoal({
    required String id,
    required double amount,
    required String sourceWalletId,
    String? notes,
  }) async {
    try {
      final response = await _apiService.depositSavingsGoal(
        id,
        {
          'amount': amount,
          'source_wallet_id': sourceWalletId,
          if (notes != null) 'notes': notes,
        },
      );
      final dataMap = response['data'] as Map<String, dynamic>;
      return SavingsGoalDto.fromJson(dataMap).toEntity();
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SavingsRepository] Lỗi nạp tiền ví tiết kiệm: $e", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<SavingsGoalEntity> withdrawSavingsGoal({
    required String id,
    required double amount,
    required String sourceWalletId,
    String? notes,
  }) async {
    try {
      final response = await _apiService.withdrawSavingsGoal(
        id,
        {
          'amount': amount,
          'source_wallet_id': sourceWalletId,
          if (notes != null) 'notes': notes,
        },
      );
      final dataMap = response['data'] as Map<String, dynamic>;
      return SavingsGoalDto.fromJson(dataMap).toEntity();
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SavingsRepository] Lỗi rút tiền ví tiết kiệm: $e", stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteSavingsGoal(String id) async {
    try {
      await _apiService.deleteSavingsGoal(id);
    } catch (e, stackTrace) {
      AppLogger.error("🚨 [SavingsRepository] Lỗi xóa mục tiêu tiết kiệm: $e", stackTrace: stackTrace);
      rethrow;
    }
  }
}
