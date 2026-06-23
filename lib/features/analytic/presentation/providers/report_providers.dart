import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_wallet_dto.dart';
import 'package:expense_management/features/analytic/domain/di/domain_providers.dart';
export 'package:expense_management/features/analytic/domain/di/domain_providers.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

extension CacheForExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;

    onDispose(() {
      timer?.cancel();
    });

    onCancel(() {
      timer?.cancel();
      timer = Timer(duration, () {
        link.close();
      });
    });

    onResume(() {
      timer?.cancel();
    });
  }
}

enum TimeFilter { thisWeek, thisMonth, thisQuarter, thisYear, custom }

// UI State Providers
final selectedTimeFilterProvider = StateProvider<TimeFilter>(
  (ref) => TimeFilter.thisMonth,
);

final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final selectedAnalyticTabProvider = StateProvider<String>(
  (ref) => 'statistics',
);

final selectedTrendTypeProvider = StateProvider<String>((ref) => 'expense');

final selectedTrendCategoryProvider = StateProvider<CategoryDto?>(
  (ref) => null,
);

final selectedDateRangeProvider = Provider<DateTimeRange>((ref) {
  final filter = ref.watch(selectedTimeFilterProvider);
  final customRange = ref.watch(customDateRangeProvider);

  final tzName =
      ref.watch(currentUserProvider.select((u) => u?.timezone)) ??
      'Asia/Ho_Chi_Minh';
  final location = tz.getLocation(tzName);
  final now = tz.TZDateTime.now(location);

  switch (filter) {
    case TimeFilter.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return DateTimeRange(
        start: tz.TZDateTime(
          location,
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        ),
        end: tz.TZDateTime(
          location,
          endOfWeek.year,
          endOfWeek.month,
          endOfWeek.day,
          23,
          59,
          59,
        ),
      );
    case TimeFilter.thisMonth:
      final startOfMonth = tz.TZDateTime(location, now.year, now.month, 1);
      final endOfMonth = tz.TZDateTime(
        location,
        now.year,
        now.month + 1,
        0,
        23,
        59,
        59,
      );
      return DateTimeRange(start: startOfMonth, end: endOfMonth);
    case TimeFilter.thisQuarter:
      final quarter = ((now.month - 1) / 3).floor();
      final startOfQuarter = tz.TZDateTime(
        location,
        now.year,
        quarter * 3 + 1,
        1,
      );
      final endOfQuarter = tz.TZDateTime(
        location,
        now.year,
        (quarter + 1) * 3 + 1,
        0,
        23,
        59,
        59,
      );
      return DateTimeRange(start: startOfQuarter, end: endOfQuarter);
    case TimeFilter.thisYear:
      final startOfYear = tz.TZDateTime(location, now.year, 1, 1);
      final endOfYear = tz.TZDateTime(location, now.year, 12, 31, 23, 59, 59);
      return DateTimeRange(start: startOfYear, end: endOfYear);
    case TimeFilter.custom:
      return customRange ??
          DateTimeRange(
            start: tz.TZDateTime(location, now.year, now.month, 1),
            end: tz.TZDateTime(
              location,
              now.year,
              now.month + 1,
              0,
              23,
              59,
              59,
            ),
          );
  }
});

// Helper for Previous Period calculation
DateTimeRange getPreviousPeriodRange(
  TimeFilter filter,
  DateTimeRange currentRange,
) {
  final start = currentRange.start;
  final end = currentRange.end;

  if (start is tz.TZDateTime) {
    final location = start.location;
    switch (filter) {
      case TimeFilter.thisWeek:
        return DateTimeRange(
          start: tz.TZDateTime.from(
            start.subtract(const Duration(days: 7)),
            location,
          ),
          end: tz.TZDateTime.from(
            end.subtract(const Duration(days: 7)),
            location,
          ),
        );
      case TimeFilter.thisMonth:
        final prevMonthStart = tz.TZDateTime(
          location,
          start.year,
          start.month - 1,
          1,
        );
        final prevMonthEnd = tz.TZDateTime(
          location,
          start.year,
          start.month,
          0,
          23,
          59,
          59,
        );
        return DateTimeRange(start: prevMonthStart, end: prevMonthEnd);
      case TimeFilter.thisQuarter:
        final prevQuarterStart = tz.TZDateTime(
          location,
          start.year,
          start.month - 3,
          1,
        );
        final prevQuarterEnd = tz.TZDateTime(
          location,
          start.year,
          start.month,
          0,
          23,
          59,
          59,
        );
        return DateTimeRange(start: prevQuarterStart, end: prevQuarterEnd);
      case TimeFilter.thisYear:
        return DateTimeRange(
          start: tz.TZDateTime(location, start.year - 1, 1, 1),
          end: tz.TZDateTime(location, start.year - 1, 12, 31, 23, 59, 59),
        );
      case TimeFilter.custom:
        final duration = end.difference(start);
        final prevEnd = start.subtract(const Duration(days: 1));
        final prevStart = prevEnd.subtract(duration);
        return DateTimeRange(
          start: tz.TZDateTime.from(prevStart, location),
          end: tz.TZDateTime(
            location,
            prevEnd.year,
            prevEnd.month,
            prevEnd.day,
            23,
            59,
            59,
          ),
        );
    }
  }

  // Fallback for non-TZDateTime (e.g. standard local DateTime)
  switch (filter) {
    case TimeFilter.thisWeek:
      return DateTimeRange(
        start: start.subtract(const Duration(days: 7)),
        end: end.subtract(const Duration(days: 7)),
      );
    case TimeFilter.thisMonth:
      final prevMonthStart = DateTime(start.year, start.month - 1, 1);
      final prevMonthEnd = DateTime(start.year, start.month, 0, 23, 59, 59);
      return DateTimeRange(start: prevMonthStart, end: prevMonthEnd);
    case TimeFilter.thisQuarter:
      final prevQuarterStart = DateTime(start.year, start.month - 3, 1);
      final prevQuarterEnd = DateTime(start.year, start.month, 0, 23, 59, 59);
      return DateTimeRange(start: prevQuarterStart, end: prevQuarterEnd);
    case TimeFilter.thisYear:
      return DateTimeRange(
        start: DateTime(start.year - 1, 1, 1),
        end: DateTime(start.year - 1, 12, 31, 23, 59, 59),
      );
    case TimeFilter.custom:
      final duration = end.difference(start);
      final prevEnd = start.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(duration);
      return DateTimeRange(
        start: prevStart,
        end: DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
      );
  }
}

// Data Fetching Providers
final reportSummaryProvider = FutureProvider.autoDispose<ReportSummaryDto>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);
  return repository.getSummary(startDate: range.start, endDate: range.end);
});

final dashboardSummaryProvider = FutureProvider.autoDispose<ReportSummaryDto>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  // Watch transactionListProvider to refresh when transactions are updated/synced
  ref.watch(transactionListProvider);

  final userId = ref.read(currentUserProvider)?.id ?? '';
  if (userId.isEmpty) {
    return ReportSummaryDto(income: 0, expense: 0, net: 0);
  }

  final repository = ref.watch(reportRepositoryProvider);

  final user = ref.read(currentUserProvider);
  final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
  final location = tz.getLocation(tzName);
  final now = tz.TZDateTime.now(location);
  final startOfMonth = tz.TZDateTime(location, now.year, now.month, 1);
  final endOfMonth = tz.TZDateTime(
    location,
    now.year,
    now.month + 1,
    0,
    23,
    59,
    59,
  );

  return repository.getSummary(startDate: startOfMonth, endDate: endOfMonth);
});

final previousPeriodSummaryProvider = FutureProvider.autoDispose<ReportSummaryDto>((
  ref,
) async {
  ref.cacheFor(const Duration(minutes: 3));
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

Future<ReportCategoryDto> _adjustReportCategories(
  Ref ref,
  ReportCategoryDto dto,
  String type,
  DateTime startDate,
  DateTime endDate,
) async {
  try {
    final useCase = ref.read(getTransactionsUseCaseProvider);
    final result = await useCase.execute(
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat(
        'yyyy-MM-dd',
      ).format(endDate.add(const Duration(days: 1))),
      type: type,
      sortBy: 'date',
      sortOrder: 'desc',
      perPage: 200,
    );

    final transfers = result.items.where((tx) => tx.isTransferLocked);
    double transferTotal = 0.0;
    for (final tx in transfers) {
      transferTotal += tx.amount * (tx.exchangeRate ?? 1.0);
    }

    if (transferTotal == 0.0) return dto;

    final categories = <ReportCategoryEntryDto>[];
    double newTotalAmount = dto.totalAmount - transferTotal;
    if (newTotalAmount < 0) newTotalAmount = 0.0;

    for (final cat in dto.categories) {
      final isUncat =
          cat.categoryId == 'uncategorized' ||
          cat.categoryId.isEmpty ||
          cat.categoryId == 'null' ||
          cat.categoryName == 'Chưa phân loại' ||
          cat.categoryName == 'Uncategorized';
      if (isUncat) {
        double newAmt = cat.amount - transferTotal;
        if (newAmt < 0) newAmt = 0.0;

        if (newAmt > 0) {
          categories.add(
            ReportCategoryEntryDto(
              categoryId: cat.categoryId,
              categoryName: cat.categoryName,
              categoryColor: cat.categoryColor,
              categoryIcon: cat.categoryIcon,
              parentId: cat.parentId,
              parentName: cat.parentName,
              amount: newAmt,
              percentage: newTotalAmount > 0
                  ? (newAmt / newTotalAmount) * 100
                  : 0.0,
            ),
          );
        }
      } else {
        categories.add(
          ReportCategoryEntryDto(
            categoryId: cat.categoryId,
            categoryName: cat.categoryName,
            categoryColor: cat.categoryColor,
            categoryIcon: cat.categoryIcon,
            parentId: cat.parentId,
            parentName: cat.parentName,
            amount: cat.amount,
            percentage: newTotalAmount > 0
                ? (cat.amount / newTotalAmount) * 100
                : 0.0,
          ),
        );
      }
    }

    final finalCategories =
        categories
            .map(
              (cat) => ReportCategoryEntryDto(
                categoryId: cat.categoryId,
                categoryName: cat.categoryName,
                categoryColor: cat.categoryColor,
                categoryIcon: cat.categoryIcon,
                parentId: cat.parentId,
                parentName: cat.parentName,
                amount: cat.amount,
                percentage: newTotalAmount > 0
                    ? (cat.amount / newTotalAmount) * 100
                    : 0.0,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return ReportCategoryDto(
      totalAmount: newTotalAmount,
      categories: finalCategories,
    );
  } catch (_) {
    return dto;
  }
}

final reportCategoriesProvider = FutureProvider.autoDispose<ReportCategoryDto>((ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);
  final filter = ref.watch(selectedTimeFilterProvider);

  final ReportCategoryDto rawReport;
  if (filter == TimeFilter.thisMonth) {
    final now = DateTime.now();
    rawReport = await repository.getCategories(
      month: now.month,
      year: now.year,
      type: 'expense',
    );
  } else {
    rawReport = await repository.getCategories(
      startDate: range.start,
      endDate: range.end,
      type: 'expense',
    );
  }
  return _adjustReportCategories(
    ref,
    rawReport,
    'expense',
    range.start,
    range.end,
  );
});

final reportIncomeCategoriesProvider = FutureProvider.autoDispose<ReportCategoryDto>((
  ref,
) async {
  ref.cacheFor(const Duration(minutes: 3));
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);
  final filter = ref.watch(selectedTimeFilterProvider);

  final ReportCategoryDto rawReport;
  if (filter == TimeFilter.thisMonth) {
    final now = DateTime.now();
    rawReport = await repository.getCategories(
      month: now.month,
      year: now.year,
      type: 'income',
    );
  } else {
    rawReport = await repository.getCategories(
      startDate: range.start,
      endDate: range.end,
      type: 'income',
    );
  }
  return _adjustReportCategories(
    ref,
    rawReport,
    'income',
    range.start,
    range.end,
  );
});

final trendsDailyProvider = FutureProvider.autoDispose<List<ReportTrendEntryDto>>((
  ref,
) async {
  ref.cacheFor(const Duration(minutes: 3));
  ref.watch(transactionListProvider);
  final range = ref.watch(selectedDateRangeProvider);
  final category = ref.watch(selectedTrendCategoryProvider);

  if (category == null) {
    final repository = ref.watch(reportRepositoryProvider);
    return repository.getTrends(
      startDate: range.start,
      endDate: range.end,
      groupBy: 'day',
    );
  }

  // Calculate trends locally for the selected category (both income and expense)
  final useCase = ref.read(getTransactionsUseCaseProvider);
  final isUncategorized = category.id == 'uncategorized';

  // Fetch transactions matching the category ID and date range
  final resultTransactions = await useCase.execute(
    categoryId: isUncategorized ? null : category.id,
    startDate: DateFormat('yyyy-MM-dd').format(range.start),
    endDate: DateFormat(
      'yyyy-MM-dd',
    ).format(range.end.add(const Duration(days: 1))),
    type: null,
    sortBy: 'date',
    sortOrder: 'asc',
    perPage: 200,
  );

  var allTransactions = resultTransactions.items;
  if (isUncategorized) {
    allTransactions = allTransactions
        .where(
          (tx) =>
              (tx.categoryId == null || tx.categoryName == null) &&
              !tx.isTransferLocked,
        )
        .toList();
  }

  // Deduplicate transactions by ID defensively
  final uniqueMap = {for (var tx in allTransactions) tx.id: tx};
  final cleanTransactions = uniqueMap.values.toList();

  // Group by day inside user timezone
  final tzName =
      ref.watch(currentUserProvider.select((u) => u?.timezone)) ??
      'Asia/Ho_Chi_Minh';
  final location = tz.getLocation(tzName);

  final Map<String, List<TransactionEntity>> grouped = {};
  for (final tx in cleanTransactions) {
    final txDate = tz.TZDateTime.from(tx.transactionDate, location);
    final dateStr = DateFormat('yyyy-MM-dd').format(txDate);
    grouped.putIfAbsent(dateStr, () => []).add(tx);
  }

  final List<ReportTrendEntryDto> result = [];
  var current = tz.TZDateTime.from(range.start, location);
  final end = tz.TZDateTime.from(range.end, location);

  while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
    final dateStr = DateFormat('yyyy-MM-dd').format(current);
    final items = grouped[dateStr] ?? [];

    double income = 0.0;
    double expense = 0.0;
    for (final tx in items) {
      final amount = tx.amount * (tx.exchangeRate ?? 1.0);
      if (tx.type == 'income') {
        income += amount;
      } else if (tx.type == 'expense') {
        expense += amount;
      }
    }

    result.add(
      ReportTrendEntryDto(
        label: DateFormat('dd/MM').format(current),
        date: dateStr,
        income: income,
        expense: expense,
      ),
    );

    current = current.add(const Duration(days: 1));
  }

  return result;
});

final trends6MonthsProvider = FutureProvider.autoDispose<List<ReportTrendEntryDto>>((
  ref,
) async {
  ref.cacheFor(const Duration(minutes: 3));
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

// Dynamic trend provider for 6 weeks, 12 months, or 2 years
final trendsFlexibleProvider =
    FutureProvider.autoDispose.family<List<ReportTrendEntryDto>, String>((
      ref,
      timeMode,
    ) async {
      ref.cacheFor(const Duration(minutes: 3));
      ref.watch(transactionListProvider);
      final repository = ref.watch(reportRepositoryProvider);
      final now = DateTime.now();

      if (timeMode == 'week') {
        // 6 weeks: from 5 weeks ago Monday to end of this week Sunday.
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        ).subtract(const Duration(days: 35));
        final endDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        ).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

        final dailyTrends = await repository.getTrends(
          startDate: startDate,
          endDate: endDate,
          groupBy: 'day',
        );

        final List<ReportTrendEntryDto> weeklyTrends = [];
        for (int i = 0; i < 6; i++) {
          final weekStart = startDate.add(Duration(days: i * 7));
          final weekEnd = weekStart.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
          );

          double income = 0;
          double expense = 0;

          for (final entry in dailyTrends) {
            if (entry.date != null) {
              final entryDate = DateTime.tryParse(entry.date!);
              if (entryDate != null &&
                  entryDate.isAfter(
                    weekStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  entryDate.isBefore(weekEnd.add(const Duration(seconds: 1)))) {
                income += entry.income;
                expense += entry.expense;
              }
            }
          }

          final label =
              '${weekStart.day}/${weekStart.month}-${weekEnd.day}/${weekEnd.month}';
          weeklyTrends.add(
            ReportTrendEntryDto(
              label: label,
              date: DateFormat('yyyy-MM-dd').format(weekStart),
              month: weekStart.month,
              year: weekStart.year,
              income: income,
              expense: expense,
            ),
          );
        }
        return weeklyTrends;
      } else if (timeMode == 'month') {
        final startDate = DateTime(now.year, now.month - 11, 1);
        final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        final trends = await repository.getTrends(
          startDate: startDate,
          endDate: endDate,
          groupBy: 'month',
        );

        final List<ReportTrendEntryDto> result = [];
        for (int i = 11; i >= 0; i--) {
          final targetMonth = DateTime(now.year, now.month - i, 1);
          final label = 'T${targetMonth.month}';
          final match = trends.firstWhere(
            (ReportTrendEntryDto t) =>
                t.month == targetMonth.month && t.year == targetMonth.year,
            orElse: () {
              return trends.firstWhere(
                (ReportTrendEntryDto t) =>
                    t.label.contains(
                      '${targetMonth.month}/${targetMonth.year}',
                    ) ||
                    t.label.contains(
                      '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}',
                    ),
                orElse: () => ReportTrendEntryDto(
                  label: label,
                  date: DateFormat('yyyy-MM-dd').format(targetMonth),
                  month: targetMonth.month,
                  year: targetMonth.year,
                  income: 0.0,
                  expense: 0.0,
                ),
              );
            },
          );

          result.add(
            ReportTrendEntryDto(
              label: label,
              date: match.date ?? DateFormat('yyyy-MM-dd').format(targetMonth),
              month: targetMonth.month,
              year: targetMonth.year,
              income: match.income,
              expense: match.expense,
            ),
          );
        }
        return result;
      } else {
        // timeMode == 'year' -> 2 years (last year and this year)
        final startDate = DateTime(now.year - 1, 1, 1);
        final endDate = DateTime(now.year, 12, 31, 23, 59, 59);

        final monthlyTrends = await repository.getTrends(
          startDate: startDate,
          endDate: endDate,
          groupBy: 'month',
        );

        double thisYearIncome = 0;
        double thisYearExpense = 0;
        double lastYearIncome = 0;
        double lastYearExpense = 0;

        for (final entry in monthlyTrends) {
          if (entry.year == now.year || entry.label.contains('${now.year}')) {
            thisYearIncome += entry.income;
            thisYearExpense += entry.expense;
          } else if (entry.year == now.year - 1 ||
              entry.label.contains('${now.year - 1}')) {
            lastYearIncome += entry.income;
            lastYearExpense += entry.expense;
          }
        }

        return [
          ReportTrendEntryDto(
            label: '${now.year - 1}',
            date: '${now.year - 1}-01-01',
            month: 1,
            year: now.year - 1,
            income: lastYearIncome,
            expense: lastYearExpense,
          ),
          ReportTrendEntryDto(
            label: '${now.year}',
            date: '${now.year}-01-01',
            month: 1,
            year: now.year,
            income: thisYearIncome,
            expense: thisYearExpense,
          ),
        ];
      }
    });

// Category breakdown provider for custom periods
typedef CategoryPeriodArg = ({
  DateTime startDate,
  DateTime endDate,
  String type,
});
final categoriesByPeriodProvider =
    FutureProvider.autoDispose.family<ReportCategoryDto, CategoryPeriodArg>((
      ref,
      arg,
    ) async {
      ref.cacheFor(const Duration(minutes: 3));
      ref.watch(transactionListProvider);
      final repository = ref.watch(reportRepositoryProvider);
      final rawReport = await repository.getCategories(
        startDate: arg.startDate,
        endDate: arg.endDate,
        type: arg.type,
      );
      return _adjustReportCategories(
        ref,
        rawReport,
        arg.type,
        arg.startDate,
        arg.endDate,
      );
    });

// Transaction list provider for the Category Detail Screen
// Transaction list provider for the Category Detail Screen
typedef CategoryDetailTransArg = ({
  String categoryId,
  DateTime startDate,
  DateTime endDate,
  String type,
});
final categoryDetailTransactionsProvider =
    FutureProvider.autoDispose.family<List<TransactionEntity>, CategoryDetailTransArg>((
      ref,
      arg,
    ) async {
      ref.cacheFor(const Duration(minutes: 3));
      ref.watch(transactionListProvider);
      final useCase = ref.read(getTransactionsUseCaseProvider);

      final isUncategorized = arg.categoryId == 'uncategorized';
      final database = ref.read(appDatabaseProvider);
      final allCategories = await database.getAllCategories();

      List<TransactionEntity> baseTransactions = [];

      if (isUncategorized) {
        final result = await useCase.execute(
          categoryId: null,
          startDate: DateFormat('yyyy-MM-dd').format(arg.startDate),
          endDate: DateFormat(
            'yyyy-MM-dd',
          ).format(arg.endDate.add(const Duration(days: 1))),
          type: arg.type,
          sortBy: 'date',
          sortOrder: 'desc',
          perPage: 100,
        );
        baseTransactions = result.items
            .where(
              (tx) =>
                  (tx.categoryId == null || tx.categoryName == null) &&
                  tx.type == arg.type &&
                  !tx.isTransferLocked,
            )
            .toList();
      } else {
        // Lấy các danh mục con nếu đây là danh mục cha
        final childIds = allCategories
            .where((c) => c.parentId == arg.categoryId)
            .map((c) => c.id)
            .toList();

        final idsToFetch = [arg.categoryId, ...childIds];

        // Fetch transactions song song cho tất cả các ID danh mục liên quan
        final results = await Future.wait(
          idsToFetch.map(
            (id) => useCase.execute(
              categoryId: id,
              startDate: DateFormat('yyyy-MM-dd').format(arg.startDate),
              endDate: DateFormat(
                'yyyy-MM-dd',
              ).format(arg.endDate.add(const Duration(days: 1))),
              type: arg.type,
              sortBy: 'date',
              sortOrder: 'desc',
              perPage: 100,
            ),
          ),
        );

        // Gộp tất cả kết quả
        baseTransactions = results.expand((r) => r.items).toList();
      }

      // 1. Tạo Map chứa các giao dịch từ API để tránh trùng lặp
      final Map<String, TransactionEntity> mergedMap = {
        for (var tx in baseTransactions) tx.id: tx,
      };

      // 2. Đồng bộ các thay đổi optimistic từ local state (transactionListProvider)
      final localList = ref.read(transactionListProvider).value ?? [];
      final childIds = isUncategorized
          ? <String>[]
          : allCategories
                .where((c) => c.parentId == arg.categoryId)
                .map((c) => c.id)
                .toList();
      final idsToFetch = isUncategorized
          ? <String>[]
          : [arg.categoryId, ...childIds];

      for (final localTx in localList) {
        // Only merge pending (unsynced) optimistic transactions
        if (localTx.status != 'pending') {
          continue;
        }

        // Kiểm tra xem giao dịch có thuộc phạm vi của chi tiết này không (ngày và loại)
        final txDate = localTx.transactionDate;
        final isWithinDateRange =
            txDate.isAfter(
              arg.startDate.subtract(const Duration(seconds: 1)),
            ) &&
            txDate.isBefore(arg.endDate.add(const Duration(days: 1)));
        final isMatchingType = localTx.type == arg.type;

        if (isWithinDateRange && isMatchingType) {
          final isTxInThisCategory = isUncategorized
              ? (localTx.categoryId == null || localTx.categoryName == null) &&
                    !localTx.isTransferLocked
              : idsToFetch.contains(localTx.categoryId);

          if (isTxInThisCategory) {
            mergedMap[localTx.id] = localTx;
          } else {
            // Nếu giao dịch cũ thuộc danh mục này nhưng vừa được chuyển sang danh mục khác
            mergedMap.remove(localTx.id);
          }
        }
      }

      // 3. Enrich thông tin danh mục cho danh sách kết quả cuối cùng từ local Categories DB
      final enrichedList = mergedMap.values.map((tx) {
        if (tx.categoryId != null) {
          final match = allCategories.where((c) => c.id == tx.categoryId);
          if (match.isNotEmpty) {
            final cat = match.first;
            return TransactionEntity(
              id: tx.id,
              walletId: tx.walletId,
              categoryId: tx.categoryId,
              type: tx.type,
              status: tx.status,
              amount: tx.amount,
              currencyCode: tx.currencyCode,
              exchangeRate: tx.exchangeRate,
              title: tx.title,
              notes: tx.notes,
              timezone: tx.timezone,
              sourceType: tx.sourceType,
              sourceId: tx.sourceId,
              isTransferLocked: tx.isTransferLocked,
              transactionDate: tx.transactionDate,
              createdAt: tx.createdAt,
              categoryName: cat.name,
              categoryIcon: cat.icon,
              categoryColor: cat.color,
              walletName: tx.walletName,
              walletIcon: tx.walletIcon,
              walletColor: tx.walletColor,
              attachmentUrls: tx.attachmentUrls,
              payeeId: tx.payeeId,
              payeeName: tx.payeeName,
              payeeAccountNumber: tx.payeeAccountNumber,
              payeeBankName: tx.payeeBankName,
              senderName: tx.senderName,
              senderWalletName: tx.senderWalletName,
              senderIdentifier: tx.senderIdentifier,
            );
          }
        }
        return tx;
      }).toList();

      final sortedList = enrichedList
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      return sortedList;
    });

final reportWalletsProvider = FutureProvider.autoDispose.family<ReportWalletDto, String>((
  ref,
  type,
) async {
  ref.cacheFor(const Duration(minutes: 3));
  // Watch transactionListProvider to refresh when transactions are updated/synced
  ref.watch(transactionListProvider);

  final userId = ref.read(currentUserProvider.select((u) => u?.id)) ?? '';
  if (userId.isEmpty) {
    return ReportWalletDto(totalAmount: 0.0, wallets: []);
  }

  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);

  return repository.getWallets(
    startDate: range.start,
    endDate: range.end,
    type: type,
  );
});
