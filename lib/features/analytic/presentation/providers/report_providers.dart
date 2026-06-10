import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/analytic/data/datasource/remote/report_api_service.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:expense_management/features/analytic/data/repository_impl/report_repository_impl.dart';
import 'package:expense_management/features/analytic/domain/repository/report_repository.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

enum TimeFilter { thisWeek, thisMonth, thisQuarter, thisYear, custom }

// API & Repo Providers
final reportApiServiceProvider = Provider<ReportApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ReportApiService(dio);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final apiService = ref.watch(reportApiServiceProvider);
  return ReportRepositoryImpl(apiService);
});

// UI State Providers
final selectedTimeFilterProvider = StateProvider<TimeFilter>((ref) => TimeFilter.thisMonth);

final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final selectedDateRangeProvider = Provider<DateTimeRange>((ref) {
  final filter = ref.watch(selectedTimeFilterProvider);
  final customRange = ref.watch(customDateRangeProvider);
  final now = DateTime.now();

  switch (filter) {
    case TimeFilter.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      );
    case TimeFilter.thisMonth:
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return DateTimeRange(start: startOfMonth, end: endOfMonth);
    case TimeFilter.thisQuarter:
      final quarter = ((now.month - 1) / 3).floor();
      final startOfQuarter = DateTime(now.year, quarter * 3 + 1, 1);
      final endOfQuarter = DateTime(now.year, (quarter + 1) * 3 + 1, 0, 23, 59, 59);
      return DateTimeRange(start: startOfQuarter, end: endOfQuarter);
    case TimeFilter.thisYear:
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
      return DateTimeRange(start: startOfYear, end: endOfYear);
    case TimeFilter.custom:
      return customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          );
  }
});

// Helper for Previous Period calculation
DateTimeRange getPreviousPeriodRange(TimeFilter filter, DateTimeRange currentRange) {
  switch (filter) {
    case TimeFilter.thisWeek:
      return DateTimeRange(
        start: currentRange.start.subtract(const Duration(days: 7)),
        end: currentRange.end.subtract(const Duration(days: 7)),
      );
    case TimeFilter.thisMonth:
      final prevMonthStart = DateTime(currentRange.start.year, currentRange.start.month - 1, 1);
      final prevMonthEnd = DateTime(currentRange.start.year, currentRange.start.month, 0, 23, 59, 59);
      return DateTimeRange(start: prevMonthStart, end: prevMonthEnd);
    case TimeFilter.thisQuarter:
      final prevQuarterStart = DateTime(currentRange.start.year, currentRange.start.month - 3, 1);
      final prevQuarterEnd = DateTime(currentRange.start.year, currentRange.start.month, 0, 23, 59, 59);
      return DateTimeRange(start: prevQuarterStart, end: prevQuarterEnd);
    case TimeFilter.thisYear:
      return DateTimeRange(
        start: DateTime(currentRange.start.year - 1, 1, 1),
        end: DateTime(currentRange.start.year - 1, 12, 31, 23, 59, 59),
      );
    case TimeFilter.custom:
      final duration = currentRange.end.difference(currentRange.start);
      final prevEnd = currentRange.start.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(duration);
      return DateTimeRange(start: prevStart, end: DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59));
  }
}

// Data Fetching Providers
final reportSummaryProvider = FutureProvider<ReportSummaryDto>((ref) async {
  ref.keepAlive();
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);
  return repository.getSummary(
    startDate: range.start,
    endDate: range.end,
  );
});

final previousPeriodSummaryProvider = FutureProvider<ReportSummaryDto>((ref) async {
  ref.keepAlive();
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(selectedTimeFilterProvider);
  final range = ref.watch(selectedDateRangeProvider);
  final prevRange = getPreviousPeriodRange(filter, range);
  return repository.getSummary(
    startDate: prevRange.start,
    endDate: prevRange.end,
  );
});

final reportCategoriesProvider = FutureProvider<ReportCategoryDto>((ref) async {
  ref.keepAlive();
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);
  final filter = ref.watch(selectedTimeFilterProvider);

  if (filter == TimeFilter.thisMonth) {
    final now = DateTime.now();
    return repository.getCategories(
      month: now.month,
      year: now.year,
      type: 'expense',
    );
  } else {
    return repository.getCategories(
      startDate: range.start,
      endDate: range.end,
      type: 'expense',
    );
  }
});

final trendsDailyProvider = FutureProvider<List<ReportTrendEntryDto>>((ref) async {
  ref.keepAlive();
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);
  return repository.getTrends(
    startDate: range.start,
    endDate: range.end,
    groupBy: 'day',
  );
});

final trends6MonthsProvider = FutureProvider<List<ReportTrendEntryDto>>((ref) async {
  ref.keepAlive();
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - 5, 1);
  final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return repository.getTrends(
    startDate: startDate,
    endDate: endDate,
    groupBy: 'month',
  );
});
