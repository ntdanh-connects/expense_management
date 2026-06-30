import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/security/presentation/providers/security_provider.dart';
import 'profile_menu_item.dart';

class ProfileSecuritySection extends ConsumerWidget {
  const ProfileSecuritySection({super.key});

  void _showDisablePinConfirmDialog(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final pinController = TextEditingController();
    String error = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'confirm_disable_pin_title'.tr(ref),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('confirm_disable_pin_desc'.tr(ref)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textPrimary, fontSize: 24, letterSpacing: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.3))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primary)),
                    ),
                    onChanged: (val) async {
                      if (val.length == 4) {
                        final correct = await ref.read(securityNotifierProvider.notifier).verifyPin(val);
                        if (correct) {
                          await ref.read(securityNotifierProvider.notifier).disablePin();
                          if (ctx.mounted) Navigator.pop(ctx);
                        } else {
                          HapticFeedback.vibrate();
                          setDialogState(() {
                            pinController.clear();
                            error = 'pin_incorrect_try_again'.tr(ref);
                          });
                        }
                      }
                    },
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(error, style: TextStyle(color: colors.expenseRed, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: Text('cancel'.tr(ref), style: TextStyle(color: colors.textSecondary)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final securityState = ref.watch(securityNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'security_title'.tr(ref).toUpperCase(),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.authCardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Switch Bật/Tắt PIN Lock
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: colors.profileSecurity, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'lock_app_pin'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: securityState.isPinEnabled,
                      activeColor: colors.primary,
                      onChanged: (value) async {
                        if (value) {
                          await context.push(RoutePaths.pinSetup);
                        } else {
                          _showDisablePinConfirmDialog(context, ref);
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (securityState.isPinEnabled) ...[
                Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                // Đổi mã PIN
                ProfileMenuItem(
                  icon: Icons.pin_rounded,
                  iconColor: colors.profileSecurity,
                  title: 'change_pin'.tr(ref),
                  onTap: () {
                    context.push(RoutePaths.pinSetup);
                  },
                ),
                Divider(color: colors.textSecondary.withOpacity(0.08), height: 1, indent: 50),
                // Switch Bật/Tắt Face ID
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Platform.isIOS
                          ? SFIcon(
                              SFIcons.sf_faceid,
                              fontSize: 22,
                              color: colors.profileSecurity,
                            )
                          : Icon(
                              Icons.fingerprint_rounded,
                              color: colors.profileSecurity,
                              size: 22,
                            ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          Platform.isIOS
                              ? 'unlock_with_biometric_ios'.tr(ref)
                              : 'unlock_with_biometric_android'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: securityState.isBiometricEnabled,
                        activeColor: colors.primary,
                        onChanged: (val) async {
                          await ref.read(securityNotifierProvider.notifier).setBiometricEnabled(val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
