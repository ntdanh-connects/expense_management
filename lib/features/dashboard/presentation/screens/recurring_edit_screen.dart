import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';
import 'package:expense_management/features/dashboard/presentation/providers/recurring_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_category_picker_sheet.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_payee_picker_sheet.dart';
import 'package:expense_management/shared/widgets/confirm_dialog.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_edit/recurring_amount_card.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_edit/recurring_category_selector.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_edit/recurring_wallet_tile.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_edit/recurring_beneficiary_tile.dart';

class RecurringEditScreen extends ConsumerStatefulWidget {
  final RecurringRuleEntity rule;

  const RecurringEditScreen({super.key, required this.rule});

  @override
  ConsumerState<RecurringEditScreen> createState() =>
      _RecurringEditScreenState();
}

class _RecurringEditScreenState extends ConsumerState<RecurringEditScreen> {
  final _titleController = TextEditingController();
  late CurrencyTextInputFormatter _formatter;

  late String _selectedType;
  CategoryDto? _selectedParentCategory;
  CategoryDto? _selectedCategory;

  WalletEntity? _selectedWallet;

  late String _frequency;
  late DateTime _startDate;
  DateTime? _endDate;

  late bool _isAutoRecord;
  late bool _isRemind;
  late bool _isActive;

  bool _isLoading = false;
  bool _isDeleting = false;
  Map<String, dynamic>? _selectedPayee;
  String? _recipientWalletName;
  final bool _isLoadingPayees = false;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;

    _titleController.text = rule.title;
    _selectedType = rule.type;
    _frequency = rule.frequency;
    _startDate = rule.startDate ?? rule.nextRunAt ?? DateTime.now();
    _endDate = rule.endAt;
    _isAutoRecord = rule.isActive;
    _isRemind = false;
    _isActive = rule.isActive;
    if (rule.payeeId != null) {
      _selectedPayee = {
        'id': rule.payeeId,
        'payee_name': rule.payeeName,
        'identifier': rule.payeeAccountNumber,
        'bank_name': rule.payeeBankName,
        'payee_type': rule.payeeType,
      };
      if (rule.payeeType == 'internal' || rule.payeeType == 'p2p') {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final result = await ref
                .read(qrTransferProvider.notifier)
                .decodeQrCode(rule.payeeAccountNumber!);
            if (result != null && mounted) {
              setState(() {
                _recipientWalletName =
                    result['recipient_wallet_name']?.toString();
              });
            }
          } catch (_) {}
        });
      }
    }

    _formatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: 'đ',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final text = _formatter.formatDouble(rule.amount);
      _titleController.selection =
          TextSelection.collapsed(offset: _titleController.text.length);

      // Set wallet
      final wallets = ref.read(walletNotifierProvider).value ?? [];
      final matched = wallets.where((w) => w.id == rule.walletId).firstOrNull;
      if (matched != null) {
        if (mounted) setState(() => _selectedWallet = matched);
      }

      // Set category
      final allCats = ref.read(categoriesNotifierProvider).value ?? [];
      for (final parent in allCats) {
        if (parent.id == rule.categoryId) {
          setState(() {
            _selectedParentCategory = parent;
            _selectedCategory = parent;
          });
          break;
        }
        if (parent.children != null) {
          final sub =
              parent.children!.where((c) => c.id == rule.categoryId).firstOrNull;
          if (sub != null) {
            setState(() {
              _selectedParentCategory = parent;
              _selectedCategory = sub;
            });
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  double get _amount => _formatter.getDouble();

  String _formatStartDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  Future<void> _pickStartDate() async {
    final colors = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _startDate.isBefore(today) ? today : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(now.year + 20),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: colors.primary,
            brightness: Theme.of(context).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final colors = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDate = _startDate.isBefore(today) ? today : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: (_endDate != null && !_endDate!.isBefore(minDate))
          ? _endDate!
          : minDate.add(const Duration(days: 30)),
      firstDate: minDate,
      lastDate: DateTime(now.year + 20),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: colors.primary,
            brightness: Theme.of(context).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _showCategorySheet() {
    final allCats = ref.read(categoriesNotifierProvider).value ?? [];
    final parents = allCats
        .where((c) => c.type == _selectedType && c.parentId == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecurringCategoryPickerSheet(
        parents: parents,
        selectedCategory: _selectedCategory,
        onSelected: (parent, sub) {
          setState(() {
            _selectedParentCategory = parent;
            _selectedCategory = sub ?? parent;
          });
        },
      ),
    );
  }

  void _showWalletSheet() {
    final wallets = ref.read(walletNotifierProvider).value ?? [];
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'recurring_select_wallet'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final filtered = wallets.where((w) {
                  final type = w.type.toLowerCase();
                  return !w.isHidden &&
                      (type == 'bank' || type == 'e-wallet' || type == 'e_wallet') &&
                      w.currencyCode == 'VND';
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'recurring_transaction_wallet_warning'.tr(ref),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 13),
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filtered.map((w) {
                    final isSelected = _selectedWallet?.id == w.id;
                    final hexColor = w.color.replaceAll('#', '');
                    Color itemColor;
                    try {
                      itemColor = Color(int.parse('FF$hexColor', radix: 16));
                    } catch (_) {
                      itemColor = colors.primary;
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          w.type.toLowerCase() == 'bank'
                              ? Icons.account_balance_rounded
                              : w.type.toLowerCase() == 'cash'
                                  ? Icons.payments_rounded
                                  : Icons.qr_code_scanner_rounded,
                          color: itemColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        w.name,
                        style: TextStyle(
                          color:
                              isSelected ? colors.primary : colors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: colors.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedWallet = w;
                          if (w.type.toLowerCase() == 'cash') {
                            _selectedPayee = null;
                            _recipientWalletName = null;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPayeeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecurringPayeePickerSheet(
        onSelected: (payee) async {
          setState(() {
            _selectedPayee = payee;
            _recipientWalletName = null;
          });
          if (payee != null &&
              (payee['payee_type'] == 'internal' ||
                  payee['payee_type'] == 'p2p')) {
            try {
              final result = await ref
                  .read(qrTransferProvider.notifier)
                  .decodeQrCode(payee['identifier']);
              if (result != null && mounted) {
                setState(() {
                  _recipientWalletName =
                      result['recipient_wallet_name']?.toString();
                });
              }
            } catch (_) {}
          }
        },
        selectedPayeeId: _selectedPayee?['id'],
      ),
    );
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      _showSnack('recurring_error_amount'.trRead(ref));
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnack('recurring_error_title'.trRead(ref));
      return;
    }
    if (_selectedWallet == null) {
      _showSnack('recurring_error_wallet'.trRead(ref));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'wallet_id': _selectedWallet!.id,
        'category_id': _selectedCategory?.id,
        'payee_id': _selectedPayee?['id'],
        'type': _selectedType,
        'amount': _amount,
        'title': _titleController.text.trim(),
        'frequency': _frequency,
        'interval_value': 1,
        'next_run_at': _startDate.toUtc().toIso8601String(),
        'start_date': _startDate.toUtc().toIso8601String(),
        'end_at': _endDate?.toUtc().toIso8601String(),
        'is_active': _isActive,
      };
      await ref
          .read(recurringNotifierProvider.notifier)
          .updateRule(widget.rule.id, data);
      if (mounted) {
        _showSuccessSnack('update_recurring_success'.trRead(ref));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: 'recurring_delete_title'.trRead(ref),
        content: 'recurring_delete_desc'.trRead(ref),
        cancelLabel: 'cancel'.trRead(ref),
        confirmLabel: 'delete'.trRead(ref),
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    try {
      await ref
          .read(recurringNotifierProvider.notifier)
          .deleteRule(widget.rule.id);
      if (mounted) {
        _showSuccessSnack('delete_recurring_success'.trRead(ref));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: context.colors.expenseRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: context.colors.incomeGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = _selectedType == 'expense';
    final amountColor = isExpense ? colors.expenseRed : colors.incomeGreen;
    final accentGreen = const Color(0xFF1B6B45);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'recurring_edit_title'.tr(ref),
          style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'recurring_edit_subtitle'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // ── Status Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? colors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: colors.textSecondary.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isActive
                                ? accentGreen.withOpacity(0.1)
                                : colors.textSecondary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.autorenew_rounded,
                            color:
                                _isActive ? accentGreen : colors.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'recurring_status'.tr(ref),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _isActive
                                    ? 'recurring_status_active'.tr(ref)
                                    : 'recurring_status_paused'.tr(ref),
                                style: TextStyle(
                                  color:
                                      _isActive ? accentGreen : colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isActive,
                          activeColor: accentGreen,
                          activeTrackColor: accentGreen.withOpacity(0.3),
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Amount Card
                  RecurringAmountCard(
                    titleController: _titleController,
                    formatter: _formatter,
                    initialAmount: widget.rule.amount,
                    currencyCode: _selectedWallet?.currencyCode,
                    amountColor: amountColor,
                  ),
                  const SizedBox(height: 16),

                  // ── Category
                  _buildSectionLabel('recurring_category_section'.tr(ref), colors,
                      trailing: 'recurring_change'.tr(ref),
                      onTrailingTap: _showCategorySheet),
                  const SizedBox(height: 8),
                  RecurringCategorySelector(
                    selectedCategory: _selectedCategory,
                    selectedParentCategory: _selectedParentCategory,
                    defaultCategoryName: widget.rule.categoryName,
                    onTap: _showCategorySheet,
                  ),
                  const SizedBox(height: 16),

                  // ── Wallet
                  _buildSectionLabel(
                      'recurring_wallet_account_section'.tr(ref), colors,
                      trailing: 'recurring_change'.tr(ref),
                      onTrailingTap: _showWalletSheet),
                  const SizedBox(height: 8),
                  RecurringWalletTile(
                    selectedWallet: _selectedWallet,
                    onTap: _showWalletSheet,
                  ),
                  const SizedBox(height: 16),

                  // ── Beneficiary
                  _buildSectionLabel('recurring_payee_section'.tr(ref), colors),
                  const SizedBox(height: 8),
                  RecurringBeneficiaryTile(
                    selectedPayee: _selectedPayee,
                    recipientWalletName: _recipientWalletName,
                    onTap: _showPayeeSheet,
                    onClear: () {
                      setState(() {
                        _selectedPayee = null;
                        _recipientWalletName = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Frequency
                  _buildSectionLabel('recurring_frequency_section'.tr(ref), colors),
                  const SizedBox(height: 10),
                  _buildFrequencyTabs(colors),
                  const SizedBox(height: 16),

                  // ── Start date
                  _buildStartDateRow(colors, isDark),
                  const SizedBox(height: 16),

                  // ── End date (Optional)
                  _buildEndDateRow(colors, isDark),
                  const SizedBox(height: 16),

                  // ── Options
                  _buildOptionTile(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'recurring_auto_record'.tr(ref),
                    subtitle: 'recurring_auto_record_desc'.tr(ref),
                    value: _isAutoRecord,
                    onChanged: (v) => setState(() => _isAutoRecord = v),
                    colors: colors,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // ── Delete button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: (_isDeleting || _isLoading) ? null : _delete,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red))
                          : const Icon(Icons.delete_rounded,
                              color: Colors.red, size: 20),
                      label: Text(
                        'recurring_delete_btn'.tr(ref),
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.4)),
                        backgroundColor: Colors.red.withOpacity(0.04),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Save button
          _buildSaveButton(colors, accentGreen),
        ],
      ),
    );
  }

  Widget _buildStartDateRow(AppColorsExtension colors, bool isDark) {
    return GestureDetector(
      onTap: _pickStartDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded,
                color: Color(0xFF1B6B45), size: 22),
            const SizedBox(width: 12),
            Text('recurring_start_date'.tr(ref),
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              _formatStartDate(_startDate),
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_today_outlined,
                color: colors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDateRow(AppColorsExtension colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded,
              color: Color(0xFF1B6B45), size: 22),
          const SizedBox(width: 12),
          Text(
            'recurring_end_date'.tr(ref),
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (_endDate != null) ...[
            GestureDetector(
              onTap: _pickEndDate,
              child: Text(
                _formatStartDate(_endDate!),
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _endDate = null),
              child:
                  Icon(Icons.cancel_rounded, color: colors.textSecondary, size: 20),
            ),
          ] else
            GestureDetector(
              onTap: _pickEndDate,
              child: Text(
                'recurring_no_end_date'.tr(ref),
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickEndDate,
            child: Icon(Icons.calendar_today_outlined,
                color: colors.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyTabs(AppColorsExtension colors) {
    final items = [
      ('daily', 'recurring_freq_daily'.tr(ref)),
      ('weekly', 'recurring_freq_weekly'.tr(ref)),
      ('monthly', 'recurring_freq_monthly'.tr(ref)),
      ('yearly', 'recurring_freq_yearly'.tr(ref)),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = _frequency == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _frequency = item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF1B6B45) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppColorsExtension colors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF1B6B45),
            activeTrackColor: const Color(0xFF1B6B45).withOpacity(0.3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, AppColorsExtension colors,
      {String? trailing, VoidCallback? onTrailingTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF1B6B45),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton(AppColorsExtension colors, Color accentGreen) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 8,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: (_isLoading || _isDeleting) ? null : _save,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Icon(Icons.check_circle_rounded, color: Colors.white),
          label: Text(
            'recurring_save_changes'.tr(ref),
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
