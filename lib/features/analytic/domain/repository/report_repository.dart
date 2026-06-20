import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_wallet_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';

abstract class ReportRepository {
  Future<ReportSummaryDto> getSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  });

  Future<ReportCategoryDto> getCategories({
    int? month,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  });

  Future<List<ReportTrendEntryDto>> getTrends({
    required DateTime startDate,
    required DateTime endDate,
    required String groupBy,
  });

  Future<ReportWalletDto> getWallets({
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  });
}
