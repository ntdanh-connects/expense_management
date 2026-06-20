import 'package:expense_management/features/analytic/data/datasource/remote/report_api_service.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_wallet_dto.dart';
import 'package:expense_management/features/analytic/domain/repository/report_repository.dart';
import 'package:intl/intl.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportApiService _apiService;

  ReportRepositoryImpl(this._apiService);

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Future<ReportSummaryDto> getSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) async {
    final response = await _apiService.getSummary(
      startDate: _formatDate(startDate),
      endDate: _formatDate(endDate),
      walletId: walletId,
    );
    return response.data;
  }

  @override
  Future<ReportCategoryDto> getCategories({
    int? month,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    final response = await _apiService.getCategories(
      month: month,
      year: year,
      startDate: startDate != null ? _formatDate(startDate) : null,
      endDate: endDate != null ? _formatDate(endDate) : null,
      type: type,
    );
    return response.data;
  }

  @override
  Future<List<ReportTrendEntryDto>> getTrends({
    required DateTime startDate,
    required DateTime endDate,
    required String groupBy,
  }) async {
    final response = await _apiService.getTrends(
      startDate: _formatDate(startDate),
      endDate: _formatDate(endDate),
      groupBy: groupBy,
    );
    return response.data;
  }

  @override
  Future<ReportWalletDto> getWallets({
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    final response = await _apiService.getWallets(
      startDate: _formatDate(startDate),
      endDate: _formatDate(endDate),
      type: type,
    );
    return response.data;
  }
}
