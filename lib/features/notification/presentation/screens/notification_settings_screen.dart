import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/notification/data/models/notification_dto.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';

// Settings screen implementation

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    
    // Watch the preference provider but do not block with loading/error UI.
    // Use .value to get the state and default to a fallback if null.
    final prefAsync = ref.watch(notificationPreferencesProvider);
    final pref = prefAsync.value;

    final effectivePref = pref ?? NotificationPreferenceDto(
      id: 'local_fallback',
      userId: 'local_fallback',
      emailEnabled: true,
      pushEnabled: true,
      weeklySummaryEnabled: false,
      dailyReminderEnabled: true,
    );

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
          'Cài đặt thông báo',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _SettingsBody(pref: effectivePref),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final NotificationPreferenceDto pref;
  const _SettingsBody({required this.pref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section: Nhắc nhở hàng ngày ────────────────────────
          const _SectionHeader(title: 'Nhắc nhở hàng ngày'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                title: 'Nhắc nhở ghi chép chi tiêu',
                subtitle: 'Cuối ngày để không bỏ lỡ giao dịch',
                value: pref.dailyReminderEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .updateSettings(dailyReminderEnabled: v),
              ),
              const _Divider(),
              const _TimeTile(title: 'Thời gian nhắc nhở'),
            ],
          ),
          const SizedBox(height: 20),

          // ── Section: Cảnh báo giao dịch ────────────────────────
          const _SectionHeader(title: 'Cảnh báo giao dịch'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                title: 'Giao dịch định kỳ',
                subtitle: 'Thông báo khi giao dịch tự động được tạo',
                value: pref.pushEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .updateSettings(pushEnabled: v),
              ),
              const _Divider(),
              _SwitchTile(
                title: 'Cảnh báo ngân sách',
                subtitle: 'Gửi qua Email & In-app khi vượt hạn mức',
                value: pref.emailEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .updateSettings(emailEnabled: v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Section: Báo cáo & Tổng kết ────────────────────────
          const _SectionHeader(title: 'Báo cáo & Tổng kết'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                title: 'Tổng kết chi tiêu hàng tuần',
                subtitle: 'Bản tin phân tích tài chính gửi qua Email',
                value: pref.weeklySummaryEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .updateSettings(weeklySummaryEnabled: v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: colors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: colors.textSecondary.withValues(alpha: 0.24),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends ConsumerWidget {
  final String title;
  const _TimeTile({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final time = ref.watch(dailyReminderTimeProvider);

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: colors.primary,
                  brightness: Theme.of(context).brightness,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          ref.read(dailyReminderTimeProvider.notifier).setTime(picked);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: colors.textSecondary.withValues(alpha: 0.12),
    );
  }
}
