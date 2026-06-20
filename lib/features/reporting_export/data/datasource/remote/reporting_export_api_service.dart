import 'package:dio/dio.dart';
import 'package:expense_management/core/network/api_endpoints.dart';

class ReportingExportApiService {
  final Dio _dio;

  ReportingExportApiService(this._dio);

  /// POST /api/transactions/export
  /// Triggers a background CSV export job on the Laravel backend.
  Future<Map<String, dynamic>> requestExport({
    required String startDate,
    required String endDate,
    String? walletId,
    String? categoryId,
    String? transactionType,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.exportTransactions,
      data: {
        'start_date': startDate,
        'end_date': endDate,
        if (walletId != null) 'wallet_id': walletId,
        if (categoryId != null) 'category_id': categoryId,
        if (transactionType != null) 'type': transactionType,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/transactions/exports
  /// Retrieves a paginated history list of export jobs from the backend.
  Future<Map<String, dynamic>> listExports({int page = 1}) async {
    final response = await _dio.get(
      ApiEndpoints.listExports,
      queryParameters: {
        'page': page,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /api/transactions/exports/{id}
  /// Deletes a specific export record (and its file) on the backend.
  Future<Map<String, dynamic>> deleteExport(String exportId) async {
    final response = await _dio.delete(
      '${ApiEndpoints.listExports}/$exportId',
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /api/transactions/exports
  /// Deletes all export records (and their files) on the backend.
  Future<Map<String, dynamic>> clearAllExports() async {
    final response = await _dio.delete(
      ApiEndpoints.listExports,
    );
    return response.data as Map<String, dynamic>;
  }
}
