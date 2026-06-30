import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/statistics_tab/statistics_time_filter_bar.dart';
import '../widgets/statistics_tab/statistics_summary_section.dart';
import '../widgets/statistics_tab/statistics_trend_chart_section.dart';
import '../widgets/statistics_tab/statistics_categories_section.dart';

class StatisticsTab extends ConsumerWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🕒 1. Date range filter selectors
        StatisticsTimeFilterBar(),
        const SizedBox(height: 18),

        // 💵 2. Balance Summary cards
        StatisticsSummarySection(),
        const SizedBox(height: 18),

        // 📈 3. Daily Spending Trend Line Chart (Collapsible)
        StatisticsTrendChartSection(),
        const SizedBox(height: 18),

        // 🍩 4. Combined Categories (Collapsible)
        StatisticsCategoriesSection(),
      ],
    );
  }
}
