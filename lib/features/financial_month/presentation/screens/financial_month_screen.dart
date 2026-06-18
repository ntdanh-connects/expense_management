import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elegant_notification/elegant_notification.dart';
import '../widgets/financial_month_info_card.dart';
import '../widgets/financial_month_grid.dart';
import '../widgets/payday_dialog.dart';
import 'package:expense_management/core/utils/app_logger.dart';

class FinancialMonthScreen extends ConsumerStatefulWidget {
  const FinancialMonthScreen({super.key});

  @override
  ConsumerState<FinancialMonthScreen> createState() => _FinancialMonthScreenState();
}
class _FinancialMonthScreenState extends ConsumerState<FinancialMonthScreen> {
  late int _selectedDay;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _selectedDay = user?.financialStartDay ?? 1;
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(updateProfileUseCaseProvider).execute(
        financialStartDay: _selectedDay,
      );

      if (mounted) {
        ElegantNotification.success(
          title: Text('success'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: Text('financial_month_saved'.tr(ref)),
        ).show(context);
        context.pop();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Lỗi khi lưu thiết lập tháng tài chính',
        details: e,
        stackTrace: stackTrace,
        tag: 'FinancialMonth',
      );
      if (mounted) {
        ElegantNotification.error(
          title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: Text('${'update_profile_error'.tr(ref)}$e'),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showPaydayPicker() async {
    final pickedDay = await showDialog<int>(
      context: context,
      builder: (context) => PaydayDialog(initialDay: _selectedDay),
    );

    if (pickedDay != null) {
      setState(() {
        _selectedDay = pickedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formattedDayStr = _selectedDay.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'financial_month_title'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FinancialMonthInfoCard(),
                    const SizedBox(height: 24),
                    
                    // Selected start day indicator
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? colors.incomeGreen.withOpacity(0.06) 
                            : colors.incomeGreen.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(60.0),
                        border: Border.all(
                          color: colors.incomeGreen.withOpacity(0.12),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'selected_start_day_label'.tr(ref).toUpperCase(),
                            style: TextStyle(
                              color: colors.incomeGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                formattedDayStr,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'monthly_suffix'.tr(ref),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Payday Button
                    OutlinedButton.icon(
                      onPressed: _showPaydayPicker,
                      icon: Icon(Icons.payments_outlined, color: colors.incomeGreen, size: 20),
                      label: Text(
                        'use_payday'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.incomeGreen.withOpacity(0.08),
                        side: BorderSide(color: colors.incomeGreen.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Grid Picker
                    FinancialMonthGrid(
                      selectedDay: _selectedDay,
                      onDaySelected: (day) {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Note at bottom
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'financial_month_note'.tr(ref),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(
                  top: BorderSide(
                    color: colors.textSecondary.withOpacity(0.05),
                    width: 1.0,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'save_changes'.tr(ref),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
