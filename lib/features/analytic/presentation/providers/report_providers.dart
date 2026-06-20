import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:expense_management/core/database/app_database.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/analytic/data/datasource/remote/report_api_service.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_trend_dto.dart';
import 'package:expense_management/features/analytic/data/repository_impl/report_repository_impl.dart';
import 'package:expense_management/features/analytic/domain/repository/report_repository.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

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

final selectedAnalyticTabProvider = StateProvider<String>((ref) => 'statistics');

final selectedDateRangeProvider = Provider<DateTimeRange>((ref) {
  final filter = ref.watch(selectedTimeFilterProvider);
  final customRange = ref.watch(customDateRangeProvider);
  
  final user = ref.watch(currentUserProvider);
  final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
  final location = tz.getLocation(tzName);
  final now = tz.TZDateTime.now(location);

  switch (filter) {
    case TimeFilter.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return DateTimeRange(
        start: tz.TZDateTime(location, startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: tz.TZDateTime(location, endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      );
    case TimeFilter.thisMonth:
      final startOfMonth = tz.TZDateTime(location, now.year, now.month, 1);
      final endOfMonth = tz.TZDateTime(location, now.year, now.month + 1, 0, 23, 59, 59);
      return DateTimeRange(start: startOfMonth, end: endOfMonth);
    case TimeFilter.thisQuarter:
      final quarter = ((now.month - 1) / 3).floor();
      final startOfQuarter = tz.TZDateTime(location, now.year, quarter * 3 + 1, 1);
      final endOfQuarter = tz.TZDateTime(location, now.year, (quarter + 1) * 3 + 1, 0, 23, 59, 59);
      return DateTimeRange(start: startOfQuarter, end: endOfQuarter);
    case TimeFilter.thisYear:
      final startOfYear = tz.TZDateTime(location, now.year, 1, 1);
      final endOfYear = tz.TZDateTime(location, now.year, 12, 31, 23, 59, 59);
      return DateTimeRange(start: startOfYear, end: endOfYear);
    case TimeFilter.custom:
      return customRange ??
          DateTimeRange(
            start: tz.TZDateTime(location, now.year, now.month, 1),
            end: tz.TZDateTime(location, now.year, now.month + 1, 0, 23, 59, 59),
          );
  }
});

// Helper for Previous Period calculation
DateTimeRange getPreviousPeriodRange(TimeFilter filter, DateTimeRange currentRange) {
  final start = currentRange.start;
  final end = currentRange.end;

  if (start is tz.TZDateTime) {
    final location = start.location;
    switch (filter) {
      case TimeFilter.thisWeek:
        return DateTimeRange(
          start: tz.TZDateTime.from(start.subtract(const Duration(days: 7)), location),
          end: tz.TZDateTime.from(end.subtract(const Duration(days: 7)), location),
        );
      case TimeFilter.thisMonth:
        final prevMonthStart = tz.TZDateTime(location, start.year, start.month - 1, 1);
        final prevMonthEnd = tz.TZDateTime(location, start.year, start.month, 0, 23, 59, 59);
        return DateTimeRange(start: prevMonthStart, end: prevMonthEnd);
      case TimeFilter.thisQuarter:
        final prevQuarterStart = tz.TZDateTime(location, start.year, start.month - 3, 1);
        final prevQuarterEnd = tz.TZDateTime(location, start.year, start.month, 0, 23, 59, 59);
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
          end: tz.TZDateTime(location, prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
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
      return DateTimeRange(start: prevStart, end: DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59));
  }
}

// Data Fetching Providers
final reportSummaryProvider = FutureProvider<ReportSummaryDto>((ref) async {
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);
  return repository.getSummary(
    startDate: range.start,
    endDate: range.end,
  );
});

final dashboardSummaryProvider = FutureProvider<ReportSummaryDto>((ref) async {
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
  final endOfMonth = tz.TZDateTime(location, now.year, now.month + 1, 0, 23, 59, 59);

  return repository.getSummary(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

final previousPeriodSummaryProvider = FutureProvider<ReportSummaryDto>((ref) async {
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

final reportIncomeCategoriesProvider = FutureProvider<ReportCategoryDto>((ref) async {
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final range = ref.watch(selectedDateRangeProvider);
  final filter = ref.watch(selectedTimeFilterProvider);

  if (filter == TimeFilter.thisMonth) {
    final now = DateTime.now();
    return repository.getCategories(
      month: now.month,
      year: now.year,
      type: 'income',
    );
  } else {
    return repository.getCategories(
      startDate: range.start,
      endDate: range.end,
      type: 'income',
    );
  }
});

final trendsDailyProvider = FutureProvider<List<ReportTrendEntryDto>>((ref) async {
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
final trendsFlexibleProvider = FutureProvider.family<List<ReportTrendEntryDto>, String>((ref, timeMode) async {
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  final now = DateTime.now();

  if (timeMode == 'week') {
    // 6 weeks: from 5 weeks ago Monday to end of this week Sunday.
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).subtract(const Duration(days: 35));
    final endDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final dailyTrends = await repository.getTrends(
      startDate: startDate,
      endDate: endDate,
      groupBy: 'day',
    );

    final List<ReportTrendEntryDto> weeklyTrends = [];
    for (int i = 0; i < 6; i++) {
      final weekStart = startDate.add(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      double income = 0;
      double expense = 0;

      for (final entry in dailyTrends) {
        if (entry.date != null) {
          final entryDate = DateTime.tryParse(entry.date!);
          if (entryDate != null &&
              entryDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              entryDate.isBefore(weekEnd.add(const Duration(seconds: 1)))) {
            income += entry.income;
            expense += entry.expense;
          }
        }
      }

      final label = '${weekStart.day}/${weekStart.month}-${weekEnd.day}/${weekEnd.month}';
      weeklyTrends.add(ReportTrendEntryDto(
        label: label,
        date: DateFormat('yyyy-MM-dd').format(weekStart),
        month: weekStart.month,
        year: weekStart.year,
        income: income,
        expense: expense,
      ));
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
        (t) => t.month == targetMonth.month && t.year == targetMonth.year,
        orElse: () {
          return trends.firstWhere(
            (t) =>
                t.label.contains('${targetMonth.month}/${targetMonth.year}') ||
                t.label.contains('${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}'),
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

      result.add(ReportTrendEntryDto(
        label: label,
        date: match.date ?? DateFormat('yyyy-MM-dd').format(targetMonth),
        month: targetMonth.month,
        year: targetMonth.year,
        income: match.income,
        expense: match.expense,
      ));
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
      } else if (entry.year == now.year - 1 || entry.label.contains('${now.year - 1}')) {
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
typedef CategoryPeriodArg = ({DateTime startDate, DateTime endDate, String type});
final categoriesByPeriodProvider = FutureProvider.family<ReportCategoryDto, CategoryPeriodArg>((ref, arg) async {
  ref.watch(transactionListProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getCategories(
    startDate: arg.startDate,
    endDate: arg.endDate,
    type: arg.type,
  );
});

// Transaction list provider for the Category Detail Screen
typedef CategoryDetailTransArg = ({String categoryId, DateTime startDate, DateTime endDate, String type});
final categoryDetailTransactionsProvider = FutureProvider.family<List<TransactionEntity>, CategoryDetailTransArg>((ref, arg) async {
  ref.watch(transactionListProvider);
  final useCase = ref.read(getTransactionsUseCaseProvider);

  final isUncategorized = arg.categoryId == 'uncategorized';
  if (isUncategorized) {
    final result = await useCase.execute(
      categoryId: null,
      startDate: DateFormat('yyyy-MM-dd').format(arg.startDate),
      endDate: DateFormat('yyyy-MM-dd').format(arg.endDate.add(const Duration(days: 1))),
      type: arg.type,
      sortBy: 'date',
      sortOrder: 'desc',
      perPage: 100,
    );
    return result.items
        .where((tx) => (tx.categoryId == null || tx.categoryName == null) && tx.type == arg.type)
        .toList();
  }

  // Lấy các danh mục con nếu đây là danh mục cha
  final database = ref.read(appDatabaseProvider);
  final allCategories = await database.getAllCategories();
  final childIds = allCategories
      .where((c) => c.parentId == arg.categoryId)
      .map((c) => c.id)
      .toList();

  final idsToFetch = [arg.categoryId, ...childIds];

  // Fetch transactions song song cho tất cả các ID danh mục liên quan
  final results = await Future.wait(idsToFetch.map((id) => useCase.execute(
        categoryId: id,
        startDate: DateFormat('yyyy-MM-dd').format(arg.startDate),
        endDate: DateFormat('yyyy-MM-dd').format(arg.endDate.add(const Duration(days: 1))),
        type: arg.type,
        sortBy: 'date',
        sortOrder: 'desc',
        perPage: 100,
      )));

  // Gộp tất cả kết quả, đảm bảo tính duy nhất theo ID giao dịch và sắp xếp theo ngày giảm dần
  final allTransactions = results.expand((r) => r.items).toList();
  final uniqueMap = {for (var tx in allTransactions) tx.id: tx};
  
  final enrichedList = uniqueMap.values.map((tx) {
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

class ReportWalletEntryDto {
  final String walletId;
  final String walletName;
  final String walletColor;
  final String walletIcon;
  final double amount;
  final double percentage;

  ReportWalletEntryDto({
    required this.walletId,
    required this.walletName,
    required this.walletColor,
    required this.walletIcon,
    required this.amount,
    required this.percentage,
  });
}

class ReportWalletDto {
  final double totalAmount;
  final List<ReportWalletEntryDto> wallets;

  ReportWalletDto({
    required this.totalAmount,
    required this.wallets,
  });
}

final reportWalletsProvider = FutureProvider<ReportWalletDto>((ref) async {
  // Watch transactionListProvider to refresh when transactions are updated/synced
  ref.watch(transactionListProvider);

  final database = ref.read(appDatabaseProvider);
  final userId = ref.read(currentUserProvider)?.id ?? '';
  if (userId.isEmpty) {
    return ReportWalletDto(totalAmount: 0.0, wallets: []);
  }

  final range = ref.watch(selectedDateRangeProvider);

  // Fetch all active wallets
  final wallets = await database.select(database.wallets).get();
  final walletMap = {for (var w in wallets) w.id: w};

  // Fetch all local transactions in the date range of type 'expense'
  final txs = await (database.select(database.localTransactions)
        ..where((t) => t.userId.equals(userId) & 
                       t.deletedAt.isNull() & 
                       t.type.equals('expense') &
                       t.sourceType.equals('transfer').not() & // Loại bỏ chuyển khoản nội bộ
                       t.transactionDate.isBiggerOrEqualValue(range.start) & 
                       t.transactionDate.isSmallerOrEqualValue(range.end)))
      .get();

  double totalAmount = 0.0;
  final Map<String, double> walletAmounts = {};

  for (final tx in txs) {
    final amt = tx.amountInUserCurrency;
    totalAmount += amt;
    walletAmounts[tx.walletId] = (walletAmounts[tx.walletId] ?? 0.0) + amt;
  }

  final List<ReportWalletEntryDto> entries = [];
  walletAmounts.forEach((walletId, amount) {
    final wallet = walletMap[walletId];
    final walletName = wallet?.name ?? 'Ví không xác định';
    final walletColor = wallet?.color ?? '#CCCCCC';
    final walletIcon = wallet?.icon ?? '';

    entries.add(ReportWalletEntryDto(
      walletId: walletId,
      walletName: walletName,
      walletColor: walletColor,
      walletIcon: walletIcon,
      amount: amount,
      percentage: totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0,
    ));
  });

  // Sắp xếp chi tiêu từ ví nhiều nhất đến ít nhất
  entries.sort((a, b) => b.amount.compareTo(a.amount));

  return ReportWalletDto(
    totalAmount: totalAmount,
    wallets: entries,
  );
});

