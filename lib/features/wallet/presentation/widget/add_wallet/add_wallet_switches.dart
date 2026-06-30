import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';

class AddWalletSwitches extends ConsumerWidget {
  final bool isHidden;
  final bool isDefaultReceiving;
  final WalletEntity? walletToEdit;
  final String selectedType;
  final ValueChanged<bool> onHiddenChanged;
  final VoidCallback onSetDefaultReceiving;

  const AddWalletSwitches({
    super.key,
    required this.isHidden,
    required this.isDefaultReceiving,
    required this.walletToEdit,
    required this.selectedType,
    required this.onHiddenChanged,
    required this.onSetDefaultReceiving,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 👁️ 6.5. ẨN VÍ KHỎI DASHBOARD (SWITCH)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHidden 
                  ? colors.primary.withOpacity(0.3) 
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHidden 
                      ? colors.primary.withOpacity(0.12) 
                      : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: isHidden ? colors.primary : colors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hide_wallet_from_dashboard'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'hide_wallet_from_dashboard_desc'.tr(ref),
                      style: TextStyle(
                        color: colors.textSecondary.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isHidden,
                activeColor: colors.primary,
                activeTrackColor: colors.primary.withOpacity(0.3),
                onChanged: onHiddenChanged,
              ),
            ],
          ),
        ),

        // 📥 6.6. ĐẶT LÀM VÍ NHẬN MẶC ĐỊNH (SWITCH/BADGE)
        if (walletToEdit != null &&
            (selectedType == 'bank' || selectedType == 'e-wallet' || selectedType == 'ewallet')) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDefaultReceiving
                    ? colors.incomeGreen.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDefaultReceiving
                        ? colors.incomeGreen.withOpacity(0.12)
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDefaultReceiving
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isDefaultReceiving ? colors.incomeGreen : colors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'set_as_default_receiving'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'default_receiving_wallet_hint'.tr(ref),
                        style: TextStyle(
                          color: colors.textSecondary.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isDefaultReceiving,
                  activeColor: colors.incomeGreen,
                  activeTrackColor: colors.incomeGreen.withOpacity(0.3),
                  onChanged: isDefaultReceiving
                      ? null // Đã bật rồi thì không cho tự gạt tắt về false
                      : (val) {
                          onSetDefaultReceiving();
                        },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
