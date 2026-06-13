import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/dashboard/domain/entities/recurring_rule_entity.dart';
import 'package:expense_management/features/dashboard/presentation/providers/recurring_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  bool _isLoadingPayees = false;

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
    }

    _formatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: 'đ',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final text = _formatter.formatDouble(rule.amount);
      _titleController.selection = TextSelection.collapsed(offset: _titleController.text.length);
      
      // Set wallet
      final wallets = ref.read(walletNotifierProvider).value ?? [];
      final matched = wallets.where((w) => w.id == rule.walletId).firstOrNull;
      if (mounted) setState(() => _selectedWallet = matched);

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
          final sub = parent.children!.where((c) => c.id == rule.categoryId).firstOrNull;
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

  String _getCurrencySymbol(String? code) {
    switch (code) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      default: return 'đ';
    }
  }

  String _formatStartDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  Future<void> _pickStartDate() async {
    final colors = context.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final colors = context.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2035),
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
    if (picked != null) setState(() => _endDate = picked);
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
      builder: (ctx) => _CategoryPickerSheet(
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('recurring_select_wallet'.tr(ref), style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...wallets.where((w) => !w.isHidden && w.type.toLowerCase() != 'cash').map((w) {
              final isSelected = _selectedWallet?.id == w.id;
              final hexColor = w.color.replaceAll('#', '');
              Color itemColor;
              try { itemColor = Color(int.parse('FF$hexColor', radix: 16)); }
              catch (_) { itemColor = colors.primary; }
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: itemColor.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(
                    w.type.toLowerCase() == 'bank' ? Icons.account_balance_rounded
                        : w.type.toLowerCase() == 'e-wallet' ? Icons.qr_code_scanner_rounded
                        : Icons.payments_rounded,
                    color: itemColor, size: 20,
                  ),
                ),
                title: Text(w.name, style: TextStyle(
                  color: isSelected ? colors.primary : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
                subtitle: Text(
                  '${AppConstant.formatMoney(w.balance, w.currencyCode)} ${_getCurrencySymbol(w.currencyCode)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: colors.primary) : null,
                onTap: () { setState(() => _selectedWallet = w); Navigator.pop(ctx); },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPayeeSheet() {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PayeePickerSheet(
        onSelected: (payee) {
          setState(() {
            _selectedPayee = payee;
          });
        },
        selectedPayeeId: _selectedPayee?['id'],
      ),
    );
  }

  Widget _buildBeneficiaryTile(AppColorsExtension colors, bool isDark) {
    return GestureDetector(
      onTap: _showPayeeSheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: _selectedPayee == null
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline_rounded, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'recurring_select_payee'.tr(ref),
                      style: TextStyle(color: colors.textSecondary, fontSize: 15),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.textSecondary.withOpacity(0.5)),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedPayee!['payee_type'] == 'bank'
                          ? Icons.account_balance_rounded
                          : _selectedPayee!['payee_type'] == 'p2p'
                              ? Icons.person_rounded
                              : Icons.qr_code_scanner_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPayee!['payee_name'] ?? '',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _selectedPayee!['payee_type'] == 'bank'
                              ? '${_selectedPayee!['bank_name']} - ${_selectedPayee!['identifier']}'
                              : '${_selectedPayee!['identifier']}',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedPayee = null);
                    },
                    child: Icon(Icons.cancel_rounded, color: colors.textSecondary, size: 20),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _save() async {
    if (_amount <= 0) { _showSnack('recurring_error_amount'.trRead(ref)); return; }
    if (_titleController.text.trim().isEmpty) { _showSnack('recurring_error_title'.trRead(ref)); return; }
    if (_selectedWallet == null) { _showSnack('recurring_error_wallet'.trRead(ref)); return; }

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
      await ref.read(recurringNotifierProvider.notifier).updateRule(widget.rule.id, data);
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
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('recurring_delete_title'.trRead(ref), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('recurring_delete_desc'.trRead(ref), style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.trRead(ref), style: TextStyle(color: colors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: colors.expenseRed, elevation: 0),
            child: Text('delete'.trRead(ref), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    try {
      await ref.read(recurringNotifierProvider.notifier).deleteRule(widget.rule.id);
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

  Map<String, dynamic> _getParentStyle(String name, AppColorsExtension colors) {
    switch (name) {
      case 'Chi tiêu - sinh hoạt': case 'Living Expenses':
        return {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF97316)};
      case 'Chi phí phát sinh': case 'Occasional Expenses':
        return {'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEAB308)};
      case 'Chi phí cố định': case 'Fixed Expenses':
        return {'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF3B82F6)};
      case 'Đầu tư - tiết kiệm': case 'Investment & Savings':
        return {'icon': Icons.savings_rounded, 'color': const Color(0xFF10B981)};
      case 'Thu nhập': case 'Income':
        return {'icon': Icons.account_balance_rounded, 'color': const Color(0xFF8B5CF6)};
      default: return {'icon': Icons.category_rounded, 'color': colors.primary};
    }
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'recurring_edit_title'.tr(ref),
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
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

                  // ── Status Toggle (Trạng thái)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? colors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
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
                            color: _isActive ? accentGreen : colors.textSecondary,
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
                                _isActive ? 'recurring_status_active'.tr(ref) : 'recurring_status_paused'.tr(ref),
                                style: TextStyle(
                                  color: _isActive ? accentGreen : colors.textSecondary,
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
                  _buildAmountCard(colors, isDark, amountColor),
                  const SizedBox(height: 16),

                  // ── Category
                  _buildSectionLabel('recurring_category_section'.tr(ref), colors, trailing: 'recurring_change'.tr(ref), onTrailingTap: _showCategorySheet),
                  const SizedBox(height: 8),
                  _buildCategoryTile(colors, isDark),
                  const SizedBox(height: 16),

                  // ── Wallet
                  _buildSectionLabel('recurring_wallet_account_section'.tr(ref), colors, trailing: 'recurring_change'.tr(ref), onTrailingTap: _showWalletSheet),
                  const SizedBox(height: 8),
                  _buildWalletTile(colors, isDark),
                  const SizedBox(height: 16),

                  // ── Beneficiary
                  _buildSectionLabel('recurring_payee_section'.tr(ref), colors),
                  const SizedBox(height: 8),
                  _buildBeneficiaryTile(colors, isDark),
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
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                          : const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                      label: Text(
                        'recurring_delete_btn'.tr(ref),
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.4)),
                        backgroundColor: Colors.red.withOpacity(0.04),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildAmountCard(AppColorsExtension colors, bool isDark, Color amountColor) {
    return Container(
      decoration: BoxDecoration(
        color: amountColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: amountColor.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'recurring_amount_label'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _getCurrencySymbol(_selectedWallet?.currencyCode),
                style: TextStyle(color: amountColor, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: amountColor, fontSize: 36, fontWeight: FontWeight.bold),
                  controller: TextEditingController(text: _formatter.formatDouble(widget.rule.amount))
                    ..selection = TextSelection.collapsed(offset: 0),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: amountColor.withOpacity(0.4), fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  inputFormatters: [_formatter],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: colors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'recurring_title_hint_edit'.tr(ref),
                      hintStyle: TextStyle(
                        color: colors.textSecondary.withOpacity(0.5),
                        fontSize: 13, height: 1.5,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(AppColorsExtension colors, bool isDark) {
    final catIcon = CategoryUIConstants.getIconData(_selectedCategory?.icon, categoryName: _selectedCategory?.name);
    final catColor = CategoryUIConstants.getColorFromHex(_selectedCategory?.color, categoryName: _selectedCategory?.name);
    final catName = _selectedCategory?.name ?? widget.rule.categoryName ?? 'recurring_select_category'.trRead(ref);

    return GestureDetector(
      onTap: _showCategorySheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: catColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catName.tr(ref),
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (_selectedParentCategory != null && _selectedParentCategory?.id != _selectedCategory?.id)
                    Text(
                      _selectedParentCategory!.name.tr(ref),
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTile(AppColorsExtension colors, bool isDark) {
    final wallet = _selectedWallet;
    return GestureDetector(
      onTap: _showWalletSheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: wallet == null
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.account_balance_wallet_rounded, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('recurring_select_wallet'.tr(ref), style: TextStyle(color: colors.textSecondary, fontSize: 15))),
                  Icon(Icons.chevron_right_rounded, color: colors.textSecondary.withOpacity(0.5)),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(
                      wallet.type.toLowerCase() == 'bank' ? Icons.account_balance_rounded
                          : wallet.type.toLowerCase() == 'e-wallet' ? Icons.qr_code_scanner_rounded
                          : Icons.payments_rounded,
                      color: colors.primary, size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wallet.name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          '${AppConstant.formatMoney(wallet.balance, wallet.currencyCode)} ${_getCurrencySymbol(wallet.currencyCode)}',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text('recurring_change'.tr(ref), style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
      ),
    );
  }

  Widget _buildFrequencyTabs(AppColorsExtension colors) {
    final items = [
      ('daily', 'recurring_freq_daily'.tr(ref)), ('weekly', 'recurring_freq_weekly'.tr(ref)), ('monthly', 'recurring_freq_monthly'.tr(ref)), ('yearly', 'recurring_freq_yearly'.tr(ref)),
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
                  color: isSelected ? const Color(0xFF1B6B45) : Colors.transparent,
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
            Icon(Icons.calendar_month_rounded, color: const Color(0xFF1B6B45), size: 22),
            const SizedBox(width: 12),
            Text('recurring_start_date'.tr(ref), style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              _formatStartDate(_startDate),
              style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_today_outlined, color: colors.textSecondary, size: 18),
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
          Icon(Icons.calendar_month_rounded, color: const Color(0xFF1B6B45), size: 22),
          const SizedBox(width: 12),
          Text(
            'recurring_end_date'.tr(ref),
            style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (_endDate != null) ...[
            GestureDetector(
              onTap: _pickEndDate,
              child: Text(
                _formatStartDate(_endDate!),
                style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _endDate = null),
              child: Icon(Icons.cancel_rounded, color: colors.textSecondary, size: 20),
            ),
          ] else
            GestureDetector(
              onTap: _pickEndDate,
              child: Text(
                'recurring_no_end_date'.tr(ref),
                style: TextStyle(color: colors.textSecondary, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickEndDate,
            child: Icon(Icons.calendar_today_outlined, color: colors.textSecondary, size: 18),
          ),
        ],
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
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4)),
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

  Widget _buildSectionLabel(String label, AppColorsExtension colors, {String? trailing, VoidCallback? onTrailingTap}) {
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
        left: 16, right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 8,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: (_isLoading || _isDeleting) ? null : _save,
          icon: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Icon(Icons.check_circle_rounded, color: Colors.white),
          label: Text(
            'recurring_save_changes'.tr(ref),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ── Category Picker Bottom Sheet ──────────────────────────────────────────────

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  final List<CategoryDto> parents;
  final CategoryDto? selectedCategory;
  final void Function(CategoryDto parent, CategoryDto? sub) onSelected;

  const _CategoryPickerSheet({
    required this.parents,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  ConsumerState<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  CategoryDto? _selectedParent;

  Map<String, dynamic> _getParentStyle(String name, AppColorsExtension colors) {
    switch (name) {
      case 'Chi tiêu - sinh hoạt': case 'Living Expenses':
        return {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF97316)};
      case 'Chi phí phát sinh': case 'Occasional Expenses':
        return {'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEAB308)};
      case 'Chi phí cố định': case 'Fixed Expenses':
        return {'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF3B82F6)};
      case 'Đầu tư - tiết kiệm': case 'Investment & Savings':
        return {'icon': Icons.savings_rounded, 'color': const Color(0xFF10B981)};
      case 'Thu nhập': case 'Income':
        return {'icon': Icons.account_balance_rounded, 'color': const Color(0xFF8B5CF6)};
      default: return {'icon': Icons.category_rounded, 'color': context.colors.primary};
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final children = _selectedParent?.children ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 38, height: 4.5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.5))),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                if (_selectedParent != null) ...[
                  GestureDetector(
                    onTap: () => setState(() => _selectedParent = null),
                    child: Icon(Icons.arrow_back_ios_rounded, size: 18, color: colors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _getParentStyle(_selectedParent!.name, colors)['icon'],
                    color: _getParentStyle(_selectedParent!.name, colors)['color'],
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _selectedParent == null ? 'recurring_select_category'.tr(ref) : (_selectedParent!.name.tr(ref)),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: 0.88,
              ),
              itemCount: _selectedParent == null ? widget.parents.length : children.length,
              itemBuilder: (context, index) {
                if (_selectedParent == null) {
                  final parent = widget.parents[index];
                  final style = _getParentStyle(parent.name, colors);
                  final hasChildren = parent.children != null && parent.children!.isNotEmpty;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (hasChildren) setState(() => _selectedParent = parent);
                      else { widget.onSelected(parent, null); Navigator.pop(context); }
                    },
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: (style['color'] as Color).withOpacity(0.12),
                        child: Icon(style['icon'] as IconData, color: style['color'] as Color, size: 24),
                      ),
                      const SizedBox(height: 7),
                      Text(parent.name.tr(ref), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  );
                } else {
                  final sub = children[index];
                  final iconData = CategoryUIConstants.getIconData(sub.icon);
                  final color = CategoryUIConstants.getColorFromHex(sub.color);
                  final isSelected = widget.selectedCategory?.id == sub.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () { widget.onSelected(_selectedParent!, sub); Navigator.pop(context); },
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: color.withOpacity(isSelected ? 0.25 : 0.12),
                        child: Icon(iconData, color: color, size: 24),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        sub.name.tr(ref),
                        style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? color : null),
                        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payee Picker Bottom Sheet (shared for creating/editing) ──────────────────

class _PayeePickerSheet extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic>? payee) onSelected;
  final String? selectedPayeeId;

  const _PayeePickerSheet({
    required this.onSelected,
    this.selectedPayeeId,
  });

  @override
  ConsumerState<_PayeePickerSheet> createState() => _PayeePickerSheetState();
}

class _PayeePickerSheetState extends ConsumerState<_PayeePickerSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _payees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPayees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayees({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(qrTransferProvider.notifier).fetchPayees(
        search: search,
        perPage: 100,
      );
      if (res != null && res['data'] is List) {
        setState(() {
          _payees = List<Map<String, dynamic>>.from(res['data']);
        });
      }
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38, height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                Text(
                  'recurring_select_payee'.tr(ref),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner_rounded, color: colors.primary),
                  onPressed: () async {
                    final qrString = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const _SimpleQrScannerPage()),
                    );
                    if (qrString != null) {
                      setState(() => _isLoading = true);
                      try {
                        final res = await ref.read(qrTransferProvider.notifier).decodeQrCode(qrString);
                        if (res != null) {
                          final payeeMap = {
                            'id': res['payee_id'],
                            'payee_name': res['payee_name'],
                            'identifier': res['account_number'] ?? res['identifier'],
                            'bank_name': res['bank_name'],
                            'payee_type': res['type'],
                          };
                          widget.onSelected(payeeMap);
                          if (mounted) Navigator.pop(context); // Close sheet
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mã QR không hợp lệ hoặc không thể giải mã!')),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
                const Spacer(),
                if (widget.selectedPayeeId != null)
                  TextButton(
                    onPressed: () {
                      widget.onSelected(null);
                      Navigator.pop(context);
                    },
                    child: Text('cancel'.tr(ref), style: TextStyle(color: colors.expenseRed)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'recurring_search_payee'.tr(ref),
                        hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
                      ),
                      onChanged: (val) {
                        _loadPayees(search: val.trim());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payees.isEmpty
                    ? Center(
                        child: Text(
                          'recurring_no_payee'.tr(ref),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _payees.length,
                        itemBuilder: (context, index) {
                          final payee = _payees[index];
                          final isSelected = widget.selectedPayeeId == payee['id'];
                          final payeeName = payee['payee_name'] ?? '';
                          final payeeType = payee['payee_type'] ?? '';
                          final identifier = payee['identifier'] ?? '';
                          final bankName = payee['bank_name'] ?? '';

                          IconData iconData = Icons.account_balance_rounded;
                          if (payeeType == 'e-wallet' || payeeType == 'e_wallet') {
                            iconData = Icons.qr_code_scanner_rounded;
                          } else if (payeeType == 'p2p') {
                            iconData = Icons.person_rounded;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: colors.primary.withOpacity(0.1),
                              child: Icon(iconData, color: colors.primary, size: 20),
                            ),
                            title: Text(
                              payeeName,
                              style: TextStyle(
                                color: isSelected ? colors.primary : colors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              payeeType == 'bank'
                                  ? '$bankName - $identifier'
                                  : identifier,
                              style: TextStyle(color: colors.textSecondary, fontSize: 12),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: colors.primary)
                                : null,
                            onTap: () {
                              widget.onSelected(payee);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Simple QR Scanner Page ───────────────────────────────────────────────────

class _SimpleQrScannerPage extends StatefulWidget {
  const _SimpleQrScannerPage();

  @override
  State<_SimpleQrScannerPage> createState() => _SimpleQrScannerPageState();
}

class _SimpleQrScannerPageState extends State<_SimpleQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR người thụ hưởng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _isScanned = true;
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}