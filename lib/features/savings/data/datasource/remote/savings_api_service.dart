import 'package:dio/dio.dart';

class SavingsApiService {
  final Dio _dio;

  SavingsApiService(this._dio);

  /// GET /api/savings
  Future<Map<String, dynamic>> getSavingsGoals() async {
    final response = await _dio.get('api/savings');
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/savings
  Future<Map<String, dynamic>> createSavingsGoal({
    required String name,
    required double targetAmount,
    String? targetDate,
    String? autoSaveFrequency,
    double? autoSaveAmount,
    String? sourceWalletId,
  }) async {
    final response = await _dio.post(
      'api/savings',
      data: {
        'name': name,
        'target_amount': targetAmount,
        if (targetDate != null) 'target_date': targetDate,
        if (autoSaveFrequency != null) 'auto_save_frequency': autoSaveFrequency,
        if (autoSaveAmount != null) 'auto_save_amount': autoSaveAmount,
        if (sourceWalletId != null) 'source_wallet_id': sourceWalletId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/savings/{id}
  Future<Map<String, dynamic>> getSavingsGoalDetail(String id) async {
    final response = await _dio.get('api/savings/$id');
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/savings/{id}/deposit
  Future<Map<String, dynamic>> depositSavingsGoal({
    required String id,
    required double amount,
    required String sourceWalletId,
    String? notes,
  }) async {
    final response = await _dio.post(
      'api/savings/$id/deposit',
      data: {
        'amount': amount,
        'source_wallet_id': sourceWalletId,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/savings/{id}/withdraw
  Future<Map<String, dynamic>> withdrawSavingsGoal({
    required String id,
    required double amount,
    required String sourceWalletId,
    String? notes,
  }) async {
    final response = await _dio.post(
      'api/savings/$id/withdraw',
      data: {
        'amount': amount,
        'source_wallet_id': sourceWalletId,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /api/savings/{id}
  Future<Map<String, dynamic>> deleteSavingsGoal(String id) async {
    final response = await _dio.delete('api/savings/$id');
    return response.data as Map<String, dynamic>;
  }
}
