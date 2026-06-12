import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:intl/intl.dart';

class NotificationDetailScreen extends ConsumerWidget {
  final NotificationDto notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  String _normalizeType(String type) {
    final t = type.toLowerCase();
    if (t.contains('budgetwarning')) return 'budget_warning';
    if (t.contains('recurringtransaction')) return 'recurring_created';
    if (t.contains('dailyreminder')) return 'daily_reminder';
    if (t.contains('weeklysummary')) return 'weekly_summary';
    if (t.contains('importcompleted') || t.contains('exportcompleted')) return 'transaction';
    return type;
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
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'budget_warning':
        return const Color(0xFFEF4444); // Red
      case 'recurring_created':
        return const Color(0xFF3B82F6); // Blue
      case 'daily_reminder':
        return const Color(0xFF10B981); // Green
      case 'weekly_summary':
        return const Color(0xFF8B5CF6); // Purple
      case 'transaction':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'budget_warning':
        return 'Cảnh báo ngân sách';
      case 'recurring_created':
        return 'Giao dịch định kỳ';
      case 'daily_reminder':
        return 'Nhắc nhở hàng ngày';
      case 'weekly_summary':
        return 'Báo cáo tuần';
      case 'transaction':
        return 'Giao dịch mới';
      default:
        return 'Thông báo hệ thống';
    }
  }

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _formatMoney(double amount, String currencyCode) {
    final format = currencyCode == 'VND' ? '#,###' : '#,##0.00';
    final formatted = NumberFormat(format).format(amount);
    final symbol = currencyCode == 'VND' ? 'đ' : (currencyCode == 'USD' ? r'$' : currencyCode);
    return '$formatted $symbol';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawType = _normalizeType(notification.type);
    final themeColor = _colorForType(rawType);
    final iconData = _iconForType(rawType);
    final typeLabel = _typeLabel(rawType);

    final metadata = notification.metadata;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chi tiết thông báo',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Type Header Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.24),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(notification.createdAt),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Notification Title & Content ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEFF1F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.015),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Metadata Block (Specific UI depending on type) ──
            if (metadata != null && metadata.isNotEmpty) ...[
              if (rawType == 'budget_warning')
                _buildBudgetWarningMetadata(context, metadata, isDark)
              else if (rawType == 'recurring_created')
                _buildRecurringMetadata(context, metadata, isDark)
              else
                _buildGenericMetadata(context, metadata, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetWarningMetadata(
      BuildContext context, Map<String, dynamic> meta, bool isDark) {
    final colors = context.colors;
    final categoryName = meta['category_name']?.toString() ?? 'Ngân sách';
    final month = meta['month']?.toString() ?? '';
    final year = meta['year']?.toString() ?? '';
    final limitAmount = double.tryParse(meta['limit_amount']?.toString() ?? '0') ?? 0.0;
    final usedAmount = double.tryParse(meta['used_amount']?.toString() ?? '0') ?? 0.0;
    final thresholdPercent = (double.tryParse(meta['threshold_percent']?.toString() ?? '0') ?? 0.0).round();
    final isExceeded = thresholdPercent >= 100;

    final progress = limitAmount > 0 ? (usedAmount / limitAmount).clamp(0.0, 1.0) : 0.0;
    final color = isExceeded ? colors.expenseRed : const Color(0xFFF59E0B);
    final currency = 'VND'; // Default fallback

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEFF1F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chi tiết ngân sách tháng $month/$year',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaRow(context, 'Danh mục', categoryName),
          _buildMetaRow(context, 'Ngưỡng cảnh báo', '$thresholdPercent%'),
          _buildMetaRow(context, 'Hạn mức ngân sách', _formatMoney(limitAmount, currency)),
          _buildMetaRow(context, 'Số tiền đã dùng', _formatMoney(usedAmount, currency)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB),
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã dùng ${((usedAmount / (limitAmount > 0 ? limitAmount : 1)) * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
              ),
              if (isExceeded)
                Text(
                  'Đã vượt giới hạn!',
                  style: TextStyle(
                    color: colors.expenseRed,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringMetadata(
      BuildContext context, Map<String, dynamic> meta, bool isDark) {
    final colors = context.colors;
    final status = meta['status']?.toString() ?? 'success';
    final amount = double.tryParse(meta['amount']?.toString() ?? '0') ?? 0.0;
    final isSuccess = status == 'success';
    final statusLabel = isSuccess ? 'Thực hiện thành công' : 'Thực hiện thất bại';
    final statusColor = isSuccess ? colors.incomeGreen : colors.expenseRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEFF1F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.replay_rounded, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chi tiết thực thi định kỳ',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaRow(context, 'Trạng thái', statusLabel, valueColor: statusColor),
          _buildMetaRow(context, 'Số tiền giao dịch', _formatMoney(amount, 'VND')),
          if (meta['error_message'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lý do lỗi:',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.expenseRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                meta['error_message'].toString(),
                style: TextStyle(
                  color: colors.expenseRed,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenericMetadata(
      BuildContext context, Map<String, dynamic> meta, bool isDark) {
    final colors = context.colors;

    final filteredMeta = meta.entries.where((e) {
      final k = e.key.toLowerCase();
      return k != 'title' &&
          k != 'message' &&
          k != 'content' &&
          k != 'id' &&
          k != 'user_id' &&
          k != 'type' &&
          k != 'created_at' &&
          k != 'updated_at';
    }).toList();

    if (filteredMeta.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEFF1F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Thông tin chi tiết thêm',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...filteredMeta.map((e) {
            final parts = e.key.split('_');
            final formattedKey = parts.map((p) {
              if (p.isEmpty) return '';
              return p[0].toUpperCase() + p.substring(1);
            }).join(' ');

            return _buildMetaRow(context, formattedKey, e.value?.toString() ?? '');
          }),
        ],
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? colors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: Alignment.centerRight.x > 0 ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
