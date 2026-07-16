import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/ai_assistant/presentation/providers/habit_analysis_provider.dart';
import 'package:intl/intl.dart';

class HabitAnalysisScreen extends ConsumerStatefulWidget {
  const HabitAnalysisScreen({super.key});

  @override
  ConsumerState<HabitAnalysisScreen> createState() =>
      _HabitAnalysisScreenState();
}

class _HabitAnalysisScreenState extends ConsumerState<HabitAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _types = ['all', 'daily', 'monthly', 'yearly'];
  final List<String> _labels = ['Tất cả', 'Hàng ngày', 'Hàng tháng', 'Hàng năm'];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitAnalysisProvider.notifier).load(refresh: true);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final type = _types[_tabController.index];
    ref.read(habitAnalysisProvider.notifier).load(
          type: type == 'all' ? null : type,
          refresh: true,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(habitAnalysisProvider.notifier).load();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(habitAnalysisProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Phân tích Thói Quen AI',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: state.isLoading && state.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.entries.isEmpty
              ? _buildError(state.error!, colors)
              : state.entries.isEmpty
                  ? _buildEmpty(colors)
                  : _buildList(state, colors),
    );
  }

  Widget _buildError(String error, AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 52),
            const SizedBox(height: 16),
            Text('Không thể tải dữ liệu',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: colors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.read(habitAnalysisProvider.notifier).load(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.insights_rounded, color: colors.primary, size: 48),
          ),
          const SizedBox(height: 20),
          Text('Chưa có phân tích nào',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'AI sẽ tự động phân tích thói quen chi tiêu hàng ngày, hàng tháng và hàng năm của bạn.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(HabitAnalysisState state, AppColorsExtension colors) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.entries.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == state.entries.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final entry = state.entries[i];
        return _HabitAnalysisCard(
          entry: entry,
          onTap: () {
            if (!entry.isRead) {
              ref.read(habitAnalysisProvider.notifier).markRead(entry.id);
            }
            _showDetailSheet(context, entry, colors);
          },
        );
      },
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
                          _TypeBadge(type: entry.type),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(entry.analysisDate),
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 13),
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

    // Summary / insight text
    final summary = data['summary'] ?? data['insight'] ?? data['analysis'] ?? data['message'];
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
                  style: TextStyle(
                      color: colors.textPrimary, fontSize: 14, height: 1.5),
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
      widgets.add(Text('Khuyến nghị',
          style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15)));
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
                  decoration: BoxDecoration(
                      color: colors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(r.toString(),
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            height: 1.5))),
              ],
            ),
          ),
        );
      }
      widgets.add(const SizedBox(height: 8));
    }

    // Raw data as JSON-like tiles
    final interestingKeys = data.keys.where(
        (k) => k != 'summary' && k != 'insight' && k != 'analysis' && k != 'message' && k != 'recommendations');
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
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  val.toString(),
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
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

// ----------------------------------------------------------------
// Card widget
// ----------------------------------------------------------------
class _HabitAnalysisCard extends StatelessWidget {
  final HabitAnalysisEntry entry;
  final VoidCallback onTap;

  const _HabitAnalysisCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final summary = entry.analysisData['summary'] ??
        entry.analysisData['insight'] ??
        entry.analysisData['analysis'] ??
        entry.analysisData['message'] ??
        'Nhấn để xem chi tiết';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(entry.isRead ? 0.04 : 0.07)
              : (entry.isRead ? Colors.white : const Color(0xFFF0F4FF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: entry.isRead
                ? colors.textSecondary.withOpacity(0.06)
                : colors.primary.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeBadge(type: entry.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(entry.analysisDate),
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 12),
                  ),
                ),
                if (!entry.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: colors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary.toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                height: 1.45,
                fontWeight:
                    entry.isRead ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Xem chi tiết →',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

// ----------------------------------------------------------------
// Type badge
// ----------------------------------------------------------------
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (type) {
      case 'monthly':
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange.shade700;
        label = 'Tháng';
        icon = Icons.calendar_month_rounded;
        break;
      case 'yearly':
        bg = Colors.purple.withOpacity(0.15);
        fg = Colors.purple.shade400;
        label = 'Năm';
        icon = Icons.star_rounded;
        break;
      default:
        bg = colors.primary.withOpacity(0.12);
        fg = colors.primary;
        label = 'Ngày';
        icon = Icons.today_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
