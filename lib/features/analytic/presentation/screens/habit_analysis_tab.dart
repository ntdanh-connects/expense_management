import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/ai_assistant/presentation/providers/habit_analysis_provider.dart';
import 'package:expense_management/features/analytic/presentation/widgets/habit_analysis/habit_analysis_card.dart';
import 'package:expense_management/features/analytic/presentation/widgets/habit_analysis/habit_analysis_type_badge.dart';
import 'package:intl/intl.dart';

class HabitAnalysisTab extends ConsumerStatefulWidget {
  const HabitAnalysisTab({super.key});

  @override
  ConsumerState<HabitAnalysisTab> createState() => _HabitAnalysisTabState();
}

class _HabitAnalysisTabState extends ConsumerState<HabitAnalysisTab> {
  final List<String> _types = ['all', 'daily', 'monthly', 'yearly'];
  final List<String> _labels = ['Tất cả', 'Hàng ngày', 'Hàng tháng', 'Hàng năm'];
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitAnalysisProvider.notifier).load(
            type: _selectedType == 'all' ? null : _selectedType,
            refresh: true,
          );
    });
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
    });
    ref.read(habitAnalysisProvider.notifier).load(
          type: type == 'all' ? null : type,
          refresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(habitAnalysisProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📊 Horizontal filter selector (All / Daily / Monthly / Yearly)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_types.length, (index) {
              final type = _types[index];
              final label = _labels[index];
              final isSelected = _selectedType == type;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => _onTypeChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : colors.textSecondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.textSecondary.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 18),

        // Body content
        if (state.isLoading && state.entries.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.error != null && state.entries.isEmpty)
          _buildError(state.error!, colors)
        else if (state.entries.isEmpty)
          _buildEmpty(colors)
        else
          _buildList(state, colors),
      ],
    );
  }

  Widget _buildError(String error, AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(habitAnalysisProvider.notifier).load(
                    type: _selectedType == 'all' ? null : _selectedType,
                    refresh: true,
                  ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors) {
    return Column(
      children: [
        _buildInfoBanner(colors),
        const SizedBox(height: 24),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.insights_rounded, color: colors.primary, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có phân tích nào',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy ghi nhận giao dịch thường xuyên. Hệ thống AI sẽ tự động tạo báo cáo thói quen cho bạn sau mỗi ngày, tháng và năm.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.12),
            colors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Phân tích thói quen bằng AI',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            title: 'Hàng ngày',
            desc: 'Tổng kết chi tiêu trong ngày, danh mục nổi bật, giao dịch bất thường.',
            colors: colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.calendar_month_rounded,
            title: 'Hàng tháng',
            desc: 'So sánh chi tiêu với tháng trước, xu hướng tiết kiệm, cảnh báo vượt ngân sách.',
            colors: colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.auto_graph_rounded,
            title: 'Hàng năm',
            desc: 'Đánh giá tổng quan tài chính cả năm, mục tiêu và khuyến nghị cho năm tới.',
            colors: colors,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 13),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Phân tích được tự động tạo sau khi bạn có đủ dữ liệu giao dịch.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String desc,
    required AppColorsExtension colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.primary, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(HabitAnalysisState state, AppColorsExtension colors) {
    return Column(
      children: [
        _buildInfoBanner(colors),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.entries.length,
          itemBuilder: (context, i) {
            final entry = state.entries[i];
            return HabitAnalysisCard(
              entry: entry,
              onTap: () {
                if (!entry.isRead) {
                  ref.read(habitAnalysisProvider.notifier).markRead(entry.id);
                }
                _showDetailSheet(context, entry, colors);
              },
            );
          },
        ),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref.read(habitAnalysisProvider.notifier).load(),
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Xem thêm'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: colors.primary.withOpacity(0.2)),
                  foregroundColor: colors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showDetailSheet(
      BuildContext context, HabitAnalysisEntry entry, AppColorsExtension colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HabitAnalysisTypeBadge(type: entry.type),
                          const SizedBox(width: 10),
                          Text(
                            entry.periodRange.isNotEmpty ? entry.periodRange : _formatDate(entry.analysisDate),
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._buildAnalysisContent(entry.analysisData, colors),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnalysisContent(
      Map<String, dynamic> data, AppColorsExtension colors) {
    final widgets = <Widget>[];

    String cleanSummary(dynamic rawSummary) {
      final str = rawSummary?.toString() ?? '';
      if (str.isEmpty ||
          str.toLowerCase().contains('lỗi') ||
          str.toLowerCase().contains('error') ||
          str.toLowerCase().contains('key') ||
          str.toLowerCase().contains('429')) {
        return 'Báo cáo thói quen chi tiêu. Bạn có thể xem các chỉ số thống kê chi tiết bên dưới.';
      }
      return str;
    }

    final rawSummary = data['summary'] ?? data['insight'] ?? data['analysis'] ?? data['message'];
    final summary = rawSummary != null ? cleanSummary(rawSummary) : null;
    if (summary != null) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withOpacity(0.12),
                colors.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  summary.toString(),
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // Recommendations list
    final recs = data['recommendations'] as List?;
    if (recs != null && recs.isNotEmpty) {
      widgets.add(
        Text(
          'Khuyến nghị',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
      for (final r in recs) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.toString(),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      widgets.add(const SizedBox(height: 8));
    }

    // Raw data as JSON-like tiles
    final interestingKeys = data.keys.where((k) =>
        k != 'summary' &&
        k != 'insight' &&
        k != 'analysis' &&
        k != 'message' &&
        k != 'recommendations');
    for (final key in interestingKeys) {
      final val = data[key];
      if (val == null) continue;
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.authCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _prettyKey(key),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  val.toString(),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  String _prettyKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

