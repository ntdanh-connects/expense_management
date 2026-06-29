import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';

int getOccurrencesInPeriod(
  RecurringRuleEntity rule,
  DateTime now,
  String period,
) {
  if (!rule.isActive) return 0;

  DateTime start;
  DateTime end;

  switch (period) {
    case 'day':
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case 'week':
      final daysToSubtract = now.weekday - 1;
      start = DateTime(now.year, now.month, now.day - daysToSubtract);
      end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
      break;
    case 'month':
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
    case 'year':
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31, 23, 59, 59);
      break;
    default:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  final ruleStart = rule.startDate ?? start;

  if (ruleStart.isAfter(end)) return 0;
  if (rule.endAt != null && rule.endAt!.isBefore(start)) return 0;

  int count = 0;
  DateTime current = ruleStart;
  final interval = rule.intervalValue > 0 ? rule.intervalValue : 1;

  switch (rule.frequency) {
    case 'daily':
      if (current.isBefore(start)) {
        final differenceInDays = start.difference(current).inDays;
        final skipIntervals = differenceInDays ~/ interval;
        current = current.add(Duration(days: skipIntervals * interval));
        while (current.isBefore(start)) {
          current = current.add(Duration(days: interval));
        }
      }
      break;
    case 'weekly':
      if (current.isBefore(start)) {
        final differenceInDays = start.difference(current).inDays;
        final skipIntervals = differenceInDays ~/ (7 * interval);
        current = current.add(Duration(days: skipIntervals * 7 * interval));
        while (current.isBefore(start)) {
          current = current.add(Duration(days: 7 * interval));
        }
      }
      break;
    case 'monthly':
      if (current.isBefore(start)) {
        int monthsDiff =
            (start.year - current.year) * 12 + (start.month - current.month);
        int skipIntervals = monthsDiff ~/ interval;
        current = DateTime(
          current.year + (current.month + skipIntervals * interval - 1) ~/ 12,
          (current.month + skipIntervals * interval - 1) % 12 + 1,
          current.day,
        );
        while (current.isBefore(start)) {
          current = DateTime(
            current.year,
            current.month + interval,
            current.day,
          );
        }
      }
      break;
    case 'yearly':
      if (current.isBefore(start)) {
        int yearsDiff = start.year - current.year;
        int skipIntervals = yearsDiff ~/ interval;
        current = DateTime(
          current.year + skipIntervals * interval,
          current.month,
          current.day,
        );
        while (current.isBefore(start)) {
          current = DateTime(
            current.year + interval,
            current.month,
            current.day,
          );
        }
      }
      break;
  }

  int maxLoopCount = 366;
  if (period == 'day') maxLoopCount = 2;
  if (period == 'week') maxLoopCount = 8;
  if (period == 'month') maxLoopCount = 32;

  while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
    if (rule.endAt != null && current.isAfter(rule.endAt!)) {
      break;
    }
    if (current.isAfter(start) || current.isAtSameMomentAs(start)) {
      count++;
    }

    switch (rule.frequency) {
      case 'daily':
        current = current.add(Duration(days: interval));
        break;
      case 'weekly':
        current = current.add(Duration(days: 7 * interval));
        break;
      case 'monthly':
        current = DateTime(
          current.year,
          current.month + interval,
          current.day,
        );
        break;
      case 'yearly':
        current = DateTime(
          current.year + interval,
          current.month,
          current.day,
        );
        break;
      default:
        return count;
    }

    if (count > maxLoopCount) break;
  }

  return count;
}

String getPeriodTotalTitleKey(String period) {
  switch (period) {
    case 'day':
      return 'recurring_total_day';
    case 'week':
      return 'recurring_total_week';
    case 'month':
      return 'recurring_total_month';
    case 'year':
      return 'recurring_total_year';
    default:
      return 'recurring_total_month';
  }
}
