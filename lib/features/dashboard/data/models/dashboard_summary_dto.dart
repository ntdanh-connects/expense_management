import 'package:json_annotation/json_annotation.dart';
import 'package:expense_management/features/wallet/data/models/wallet_dto.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/transaction/data/models/transaction_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';

part 'dashboard_summary_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class DashboardSummaryDto {
  @JsonKey(name: 'wallets')
  final List<WalletDto> wallets;

  @JsonKey(name: 'current_month_budgets')
  final List<BudgetDto> currentMonthBudgets;

  @JsonKey(name: 'recent_transactions')
  final List<TransactionDto> recentTransactions;

  @JsonKey(name: 'unread_notifications_count')
  final int unreadNotificationsCount;

  @JsonKey(name: 'summary')
  final ReportSummaryDto summary;

  DashboardSummaryDto({
    required this.wallets,
    required this.currentMonthBudgets,
    required this.recentTransactions,
    required this.unreadNotificationsCount,
    required this.summary,
  });

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardSummaryDtoToJson(this);
}
