import 'package:expense_management/features/dashboard/data/models/dashboard_summary_dto.dart';

abstract class DashboardRepository {
  Future<DashboardSummaryDto> getSummary();
}
