import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';

class StatisticsTimeFilterBar extends ConsumerWidget {
  const StatisticsTimeFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentFilter = ref.watch(selectedTimeFilterProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);

    final tzName = ref.watch(currentUserProvider.select((u) => u?.timezone)) ?? 'Asia/Ho_Chi_Minh';
    final location = tz.getLocation(tzName);
    final now = tz.TZDateTime.now(location);

    final isCurrentMonthOrFuture = (dateRange.end.year > now.year) || 
        (dateRange.end.year == now.year && dateRange.end.month >= now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip(context, ref, TimeFilter.thisWeek, 'this_week'.tr(ref), currentFilter),
              const SizedBox(width: 8),
              _buildFilterChip(context, ref, TimeFilter.thisMonth, 'this_month'.tr(ref), currentFilter),
              const SizedBox(width: 8),
              _buildFilterChip(context, ref, TimeFilter.thisQuarter, 'this_quarter'.tr(ref), currentFilter),
              const SizedBox(width: 8),
              _buildFilterChip(context, ref, TimeFilter.thisYear, 'this_year'.tr(ref), currentFilter),
              const SizedBox(width: 8),
              _buildFilterChip(context, ref, TimeFilter.custom, 'custom_range'.tr(ref), currentFilter),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _changeMonth(ref, -1),
                  color: colors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: isCurrentMonthOrFuture ? null : () => _changeMonth(ref, 1),
                  color: colors.primary,
                  disabledColor: colors.textSecondary.withValues(alpha: 0.3),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _changeMonth(WidgetRef ref, int offset) {
    final dateRange = ref.read(selectedDateRangeProvider);
    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    final location = tz.getLocation(tzName);
    
    final currentStart = dateRange.start;
    int newYear = currentStart.year;
    int newMonth = currentStart.month + offset;
    
    if (newMonth > 12) {
      newYear += 1;
      newMonth = 1;
    } else if (newMonth < 1) {
      newYear -= 1;
      newMonth = 12;
    }
    
    final now = tz.TZDateTime.now(location);
    
    if (newYear == now.year && newMonth == now.month) {
      ref.read(selectedTimeFilterProvider.notifier).state = TimeFilter.thisMonth;
      ref.read(customDateRangeProvider.notifier).state = null;
    } else {
      final startOfMonth = tz.TZDateTime(location, newYear, newMonth, 1);
      final endOfMonth = tz.TZDateTime(location, newYear, newMonth + 1, 0, 23, 59, 59);
      
      ref.read(customDateRangeProvider.notifier).state = DateTimeRange(start: startOfMonth, end: endOfMonth);
      ref.read(selectedTimeFilterProvider.notifier).state = TimeFilter.custom;
    }
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, TimeFilter filter, String label, TimeFilter currentFilter) {
    final isSelected = filter == currentFilter;
    final colors = context.colors;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : colors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          if (filter == TimeFilter.custom) {
            _selectCustomDateRange(context, ref);
          } else {
            ref.read(selectedTimeFilterProvider.notifier).state = filter;
          }
        }
      },
      selectedColor: colors.primary,
      backgroundColor: colors.textSecondary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }

  Future<void> _selectCustomDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final currentRange = ref.read(selectedDateRangeProvider);
    final colors = context.colors;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: colors.primary,
                  onPrimary: Colors.white,
                  surface: colors.surface,
                  onSurface: colors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = picked;
      ref.read(selectedTimeFilterProvider.notifier).state = TimeFilter.custom;
    }
  }
}
