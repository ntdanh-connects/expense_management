import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';


/// Opens a sliding notification panel from the right side.
/// Call [NotificationSidebar.show(context)] to open.
class NotificationSidebar {
  static void show(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      _SidebarRoute(child: const _NotificationPanel()),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Route — slides in from the right with a translucent barrier
// ---------------------------------------------------------------------------

class _SidebarRoute<T> extends PageRoute<T> {
  final Widget child;

  _SidebarRoute({required this.child})
      : super(fullscreenDialog: false);

  @override
  Color get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Notification Sidebar';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return Stack(
      children: [
        // Dark scrim — tap to dismiss
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: FadeTransition(
            opacity: animation,
            child: Container(color: Colors.black54),
          ),
        ),
        // Panel
        Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Panel Widget
// ---------------------------------------------------------------------------

class _NotificationPanel extends ConsumerStatefulWidget {
  const _NotificationPanel();

  @override
  ConsumerState<_NotificationPanel> createState() =>
      _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<_NotificationPanel> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Refresh when panel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).refresh(silent: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final panelWidth = MediaQuery.of(context).size.width * 0.88;
    final notifAsync = ref.watch(notificationNotifierProvider);

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: SizedBox(
        width: panelWidth,
        child: Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              _PanelHeader(
                onClose: () => Navigator.of(context).pop(),
                onMarkAll: () => ref
                    .read(notificationNotifierProvider.notifier)
                    .markAllAsRead(),
                onDeleteAll: () => _confirmDeleteAll(context),
                unreadCount: notifAsync.value?.unreadCount ?? 0,
                hasNotifications: (notifAsync.value?.notifications.isNotEmpty) ?? false,
              ),

              // ── Body ──────────────────────────────────────────────
              Expanded(
                child: notifAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorView(
                    onRetry: () => ref
                        .read(notificationNotifierProvider.notifier)
                        .refresh(),
                  ),
                  data: (state) {
                    final items = state.notifications;
                    if (items.isEmpty) {
                      return const _EmptyView();
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(notificationNotifierProvider.notifier)
                          .refresh(silent: true),
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length +
                            (state.isLoading ? 1 : 0),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 72,
                          endIndent: 16,
                          color: colors.textSecondary.withOpacity(0.1),
                        ),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }
                          return _NotificationTile(
                            item: items[index],
                            onTap: () async {
                              if (!items[index].isRead) {
                                ref.read(notificationNotifierProvider.notifier).markAsRead(items[index].id);
                              }

                              final metadata = items[index].metadata;
                              final type = items[index].type.toLowerCase();
                              final isBudget = type.contains('budgetwarning') || type.contains('budget_warning');
                              final isExport = type.contains('exportcompleted') || type.contains('export_completed');
                              final isFinancial = type.contains('financialmonth') || type.contains('financial_month');
                              final isP2p = type.contains('p2ptransferreceived') || type.contains('p2p_transfer');

                              if (isExport) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close sidebar
                                  context.push(RoutePaths.exportHistory);
                                }
                                return;
                              }

                              if (isFinancial) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close sidebar
                                  context.push(RoutePaths.financialMonth);
                                }
                                return;
                              }

                              if (isBudget && metadata != null) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  barrierColor: Colors.black26,
                                  builder: (_) => const Center(child: CircularProgressIndicator()),
                                );

                                try {
                                  final budgetId = metadata['budget_id']?.toString();
                                  final month = int.tryParse(metadata['month']?.toString() ?? '') ?? DateTime.now().month;
                                  final year = int.tryParse(metadata['year']?.toString() ?? '') ?? DateTime.now().year;

                                  final budgets = await ref.read(budgetRepositoryProvider).getBudgets(month, year);
                                  
                                  final budget = budgets.firstWhere(
                                    (b) => b.id == budgetId,
                                    orElse: () {
                                      final catName = metadata['category_name']?.toString();
                                      return budgets.firstWhere(
                                        (b) => b.category?.name == catName,
                                      );
                                    },
                                  );

                                  if (mounted) {
                                    Navigator.of(context).pop(); // Dismiss loading
                                  }

                                  if (budget.categoryId != null && budget.category != null) {
                                    final cat = budget.category!;
                                    final startDate = DateTime(year, month, 1);
                                    final endDate = DateTime(year, month + 1, 0);

                                    if (mounted) {
                                      Navigator.of(context).pop(); // Close sidebar
                                      context.push(RoutePaths.categoryDetail, extra: {
                                        'categoryId': cat.id,
                                        'categoryName': cat.name,
                                        'categoryColor': cat.color,
                                        'categoryIcon': cat.icon,
                                        'type': 'expense',
                                        'startDate': startDate,
                                        'endDate': endDate,
                                        'timeMode': 'month',
                                      });
                                    }
                                  } else {
                                    if (mounted) {
                                      Navigator.of(context).pop(); // Close sidebar
                                      context.push('${RoutePaths.analytics}?tab=budget');
                                    }
                                  }
                                  return;
                                } catch (_) {
                                  if (mounted) {
                                    Navigator.of(context).pop(); // Dismiss loading
                                  }
                                  if (mounted) {
                                    Navigator.of(context).pop(); // Close sidebar
                                    context.push('${RoutePaths.analytics}?tab=budget');
                                  }
                                  return;
                                }
                              }

                              String? transactionId = metadata?['transaction_id'] as String?;

                              if (transactionId == null && isP2p && metadata != null) {
                                final amount = double.tryParse(metadata['amount']?.toString() ?? '0');
                                final senderName = metadata['sender_name'] as String?;
                                if (amount != null && amount > 0) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    barrierColor: Colors.black26,
                                    builder: (_) => const Center(child: CircularProgressIndicator()),
                                  );

                                  try {
                                    final tx = await ref
                                        .read(transactionListProvider.notifier)
                                        .findTransactionByNotificationMetadata(
                                          type: 'income',
                                          amount: amount,
                                          senderName: senderName,
                                        );
                                    if (tx != null) {
                                      transactionId = tx.id;
                                    }
                                  } catch (_) {}

                                  if (mounted) {
                                    Navigator.of(context).pop(); // Dismiss loading
                                  }
                                }
                              }

                              if (mounted) {
                                Navigator.of(context).pop(); // Close sidebar
                                if (transactionId != null && transactionId.isNotEmpty) {
                                  context.push(RoutePaths.transactionDetail, extra: transactionId);
                                } else {
                                  context.push(RoutePaths.notificationDetail, extra: items[index]);
                                }
                              }
                            },
                            onDelete: () => ref
                                .read(notificationNotifierProvider
                                    .notifier)
                                .deleteNotification(items[index].id),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: colors.expenseRed, size: 24),
            const SizedBox(width: 10),
            Text(
              'Xóa toàn bộ thông báo',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Tất cả thông báo sẽ bị xóa vĩnh viễn. Bạn có chắc chắn muốn tiếp tục?',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.expenseRed),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(notificationNotifierProvider.notifier).deleteAllNotifications();
    }
  }
}

// ---------------------------------------------------------------------------
// Panel Header
// ---------------------------------------------------------------------------

class _PanelHeader extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onMarkAll;
  final VoidCallback onDeleteAll;
  final int unreadCount;
  final bool hasNotifications;

  const _PanelHeader({
    required this.onClose,
    required this.onMarkAll,
    required this.onDeleteAll,
    required this.unreadCount,
    required this.hasNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primary.withOpacity(0.85)],
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Title + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Thông báo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount chưa đọc',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Mark all as read
              if (unreadCount > 0)
                GestureDetector(
                  onTap: onMarkAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done_all_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Đọc tất cả',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Delete all
              if (hasNotifications) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDeleteAll,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification tile
// ---------------------------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  final NotificationDto item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  String _normalizeType(String type) {
    final t = type.toLowerCase();
    if (t.contains('budgetwarning')) return 'budget_warning';
    if (t.contains('recurringtransaction')) return 'recurring_created';
    if (t.contains('dailyreminder')) return 'daily_reminder';
    if (t.contains('weeklysummary')) return 'weekly_summary';
    if (t.contains('p2ptransferreceived')) return 'p2p_transfer';
    if (t.contains('exportcompleted') || t.contains('export_completed')) return 'export_completed';
    if (t.contains('financialmonth') || t.contains('financial_month')) return 'financial_month';
    if (t.contains('importcompleted')) return 'transaction';
    return type;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRead = item.isRead;
    final normalizedType = _normalizeType(item.type);
    final iconData = _iconForType(normalizedType);
    final iconColor = _colorForType(normalizedType);

    return Dismissible(
      key: Key('notif-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colors.expenseRed.withOpacity(0.9),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isRead
              ? Colors.transparent
              : colors.primary.withOpacity(0.04),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(item.createdAt),
                      style: TextStyle(
                        color: colors.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'budget_warning':
        return Icons.account_balance_wallet_rounded;
      case 'recurring_created':
        return Icons.autorenew_rounded;
      case 'daily_reminder':
        return Icons.alarm_rounded;
      case 'weekly_summary':
        return Icons.bar_chart_rounded;
      case 'transaction':
        return Icons.receipt_long_rounded;
      case 'p2p_transfer':
        return Icons.swap_horizontal_circle_rounded;
      case 'export_completed':
        return Icons.download_done_rounded;
      case 'financial_month':
        return Icons.calendar_month_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'budget_warning':
        return const Color(0xFFEF4444);
      case 'recurring_created':
        return const Color(0xFF3B82F6);
      case 'daily_reminder':
        return const Color(0xFF10B981);
      case 'weekly_summary':
        return const Color(0xFF8B5CF6);
      case 'transaction':
        return const Color(0xFFF59E0B);
      case 'p2p_transfer':
        return const Color(0xFF10B981);
      case 'export_completed':
        return const Color(0xFF8B5CF6);
      case 'financial_month':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

// ---------------------------------------------------------------------------
// Empty & Error views
// ---------------------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded,
                size: 40, color: colors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Các thông báo của bạn sẽ xuất hiện ở đây',
            style: TextStyle(
              color: colors.textSecondary.withOpacity(0.7),
              fontSize: 12.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Không thể tải thông báo',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
