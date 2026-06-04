import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'bottom_bar_config.dart';

class QuickActionBottomSheet extends ConsumerWidget {
  final Color systemAccentColor;
  const QuickActionBottomSheet({super.key, required this.systemAccentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = context.colors;
    final actions = BottomBarConfig.getQuickActions(context, systemAccentColor, ref);

    return Container(
      decoration: BoxDecoration(color: color.authCardBg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: color.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('create_new_task'.tr(ref), style: TextStyle(color: color.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...actions.map((act) => _buildActionBox(context, act, color)),
        ],
      ),
    );
  }

  Widget _buildActionBox(BuildContext context, QuickActionConfig act, dynamic color) {
    final displayColor = act.customColor ?? color.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () { Navigator.pop(context); if (act.onTap != null) act.onTap!(); },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? color.background : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: displayColor.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: displayColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(act.icon, color: displayColor, size: 24)),
              const SizedBox(width: 16),
              Expanded(child: Text(act.title, style: TextStyle(color: color.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
              if (act.badgeText != null)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: displayColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text(act.badgeText!, style: TextStyle(color: displayColor, fontSize: 10, fontWeight: FontWeight.bold))),
              Icon(Icons.arrow_forward_ios_rounded, color: color.textSecondary.withOpacity(0.4), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}