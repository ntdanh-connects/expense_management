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
import 'package:expense_management/features/dashboard/presentation/providers/recurring_provider.dart';
import 'package:expense_management/features/transaction/presentation/screens/sub_category_selection_screen.dart';

class RecurringCreateScreen extends ConsumerStatefulWidget {
  const RecurringCreateScreen({super.key});

  @override
  ConsumerState<RecurringCreateScreen> createState() =>
      _RecurringCreateScreenState();
}

class _RecurringCreateScreenState extends ConsumerState<RecurringCreateScreen> {
  final _titleController = TextEditingController();
  late CurrencyTextInputFormatter _formatter;

  // Type & category
  String _selectedType = 'expense'; // expense, income
  CategoryDto? _selectedParentCategory;
  CategoryDto? _selectedCategory;

  // Wallet
  WalletEntity? _selectedWallet;

  // Frequency
  String _frequency = 'monthly'; // daily, weekly, monthly, yearly

  // Start date
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // Options
  bool _isAutoRecord = true;
  bool _isRemind = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: 'đ',
    );
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

  String _formatStartDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

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
    final parents = allCats.where((c) => c.type == _selectedType && c.parentId == null).toList();
    parents.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

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
            Text(
              'recurring_select_wallet'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...wallets.where((w) => !w.isHidden && w.type.toLowerCase() != 'cash').map((w) {
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
                        : w.type.toLowerCase() == 'e-wallet'
                            ? Icons.qr_code_scanner_rounded
                            : Icons.payments_rounded,
                    color: itemColor, size: 20,
                  ),
                ),
                title: Text(
                  w.name,
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${AppConstant.formatMoney(w.balance, w.currencyCode)} ${_getCurrencySymbol(w.currencyCode)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: colors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedWallet = w);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
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
        'type': _selectedType,
        'amount': _amount,
        'title': _titleController.text.trim(),
        'frequency': _frequency,
        'interval_value': 1,
        'next_run_at': _startDate.toUtc().toIso8601String(),
        'start_date': _startDate.toUtc().toIso8601String(),
        'end_at': _endDate?.toUtc().toIso8601String(),
        'is_active': _isAutoRecord,
      };
      await ref.read(recurringNotifierProvider.notifier).createRule(data);
      if (mounted) {
        _showSuccessSnack('create_recurring_success'.trRead(ref));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.colors.expenseRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.colors.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCats = ref.watch(categoriesNotifierProvider).value ?? [];
    final parents = allCats
        .where((c) => c.type == _selectedType && c.parentId == null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Quick subcategories (first 3 of selected parent)
    final quickSubs = _selectedParentCategory?.children?.take(3).toList() ?? [];

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
          'recurring_create_title'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
                    'recurring_create_subtitle'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // ── Amount card
                  _buildAmountCard(colors, isDark),
                  const SizedBox(height: 16),

                  // ── Wallet
                  _buildSectionLabel('recurring_wallet_section'.tr(ref), colors),
                  const SizedBox(height: 8),
                  _buildWalletTile(colors, isDark),
                  const SizedBox(height: 20),

                  // ── Category (like add_transaction_screen)
                  _buildSectionLabel('recurring_category_section'.tr(ref), colors, trailing: 'recurring_see_all'.tr(ref), onTrailingTap: _showCategorySheet),
                  const SizedBox(height: 10),

                  // Type tabs
                  _buildTypeTabs(colors),
                  const SizedBox(height: 12),

                  // Parent categories horizontal scroll
                  SizedBox(
                    height: 90,
                    child: allCats.isEmpty
                        ? const SizedBox()
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: parents.length,
                            itemBuilder: (context, index) {
                              final parent = parents[index];
                              return _buildParentCategoryChip(parent, colors);
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Quick subcategories
                  if (quickSubs.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: quickSubs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == quickSubs.length) {
                            // "Thêm" button
                            return _buildAddSubcatChip(colors);
                          }
                          return _buildSubCategoryChip(quickSubs[index], colors);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 4),

                  // ── Frequency
                  _buildSectionLabel('recurring_frequency_section'.tr(ref), colors),
                  const SizedBox(height: 10),
                  _buildFrequencyTabs(colors),
                  const SizedBox(height: 16),

                  // ── Start date
                  _buildStartDateRow(colors),
                  const SizedBox(height: 16),

                  // ── End date (Optional)
                  _buildEndDateRow(colors),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Save button
          _buildSaveButton(colors),
        ],
      ),
    );
  }

  Widget _buildAmountCard(AppColorsExtension colors, bool isDark) {
    final isIncome = _selectedType == 'income';
    final amountColor = isIncome ? colors.incomeGreen : colors.expenseRed;

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
                style: TextStyle(
                  color: amountColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: amountColor.withOpacity(0.4),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  inputFormatters: [_formatter],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
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
                      hintText: 'recurring_title_hint'.tr(ref),
                      hintStyle: TextStyle(
                        color: colors.textSecondary.withOpacity(0.5),
                        fontSize: 13,
                        height: 1.5,
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

  Widget _buildWalletTile(AppColorsExtension colors, bool isDark) {
    return GestureDetector(
      onTap: _showWalletSheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: _selectedWallet == null
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'recurring_select_wallet'.tr(ref),
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
                    child: Icon(Icons.account_balance_wallet_rounded, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedWallet!.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${'recurring_wallet_balance'.tr(ref)}: ${AppConstant.formatMoney(_selectedWallet!.balance, _selectedWallet!.currencyCode)} ${_getCurrencySymbol(_selectedWallet!.currencyCode)}',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'recurring_change'.tr(ref),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTypeTabs(AppColorsExtension colors) {
    final tabs = [
      ('expense', 'recurring_type_expense'.tr(ref), colors.expenseRed),
      ('income', 'recurring_type_income'.tr(ref), colors.incomeGreen),
    ];

    return Row(
      children: tabs.map((tab) {
        final isSelected = _selectedType == tab.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedType = tab.$1;
              _selectedParentCategory = null;
              _selectedCategory = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? tab.$3.withOpacity(0.12) : colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? tab.$3 : colors.textSecondary.withOpacity(0.1),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                tab.$2,
                style: TextStyle(
                  color: isSelected ? tab.$3 : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _getParentStyle(String name, AppColorsExtension colors) {
    switch (name) {
      case 'Chi tiêu - sinh hoạt':
      case 'Living Expenses':
        return {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF97316)};
      case 'Chi phí phát sinh':
      case 'Occasional Expenses':
        return {'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEAB308)};
      case 'Chi phí cố định':
      case 'Fixed Expenses':
        return {'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF3B82F6)};
      case 'Đầu tư - tiết kiệm':
      case 'Investment & Savings':
        return {'icon': Icons.savings_rounded, 'color': const Color(0xFF10B981)};
      case 'Thu nhập':
      case 'Income':
        return {'icon': Icons.account_balance_rounded, 'color': const Color(0xFF8B5CF6)};
      default:
        return {'icon': Icons.category_rounded, 'color': colors.primary};
    }
  }

  Widget _buildParentCategoryChip(CategoryDto parent, AppColorsExtension colors) {
    final style = _getParentStyle(parent.name, colors);
    final isSelected = _selectedParentCategory?.id == parent.id;
    final IconData parentIcon = style['icon'];
    final Color parentColor = style['color'];

    return GestureDetector(
      onTap: () => setState(() {
        _selectedParentCategory = parent;
        _selectedCategory = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? parentColor.withOpacity(0.12) : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? parentColor : colors.textSecondary.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(parentIcon, color: isSelected ? parentColor : colors.textSecondary, size: 22),
            const SizedBox(height: 6),
            FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  parent.name.tr(ref),
                  style: TextStyle(
                    color: isSelected ? parentColor : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryChip(CategoryDto sub, AppColorsExtension colors) {
    final isSelected = _selectedCategory?.id == sub.id;
    final iconData = CategoryUIConstants.getIconData(sub.icon);
    final catColor = CategoryUIConstants.getColorFromHex(sub.color);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = sub),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? catColor : colors.textSecondary.withOpacity(0.06),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: catColor.withOpacity(isSelected ? 0.25 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: catColor, size: 20),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  sub.name.tr(ref),
                  style: TextStyle(
                    color: isSelected ? catColor : colors.textPrimary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSubcatChip(AppColorsExtension colors) {
    return GestureDetector(
      onTap: _showCategorySheet,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.textSecondary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: colors.textSecondary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              'recurring_add_more'.tr(ref),
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
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
                  color: isSelected ? colors.primary : Colors.transparent,
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

  Widget _buildStartDateRow(AppColorsExtension colors) {
    return GestureDetector(
      onTap: _pickStartDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: colors.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              'recurring_start_date'.tr(ref),
              style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
            ),
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

  Widget _buildEndDateRow(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: colors.primary, size: 22),
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
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: colors.primary,
            activeTrackColor: colors.primary.withOpacity(0.3),
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
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton(AppColorsExtension colors) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 16, top: 8,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _save,
          icon: _isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Icon(Icons.check_circle_rounded, color: Colors.white),
          label: Text(
            'recurring_save'.tr(ref),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B6B45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ── Category Picker Bottom Sheet (shared between create & edit) ──────────────

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
      case 'Chi tiêu - sinh hoạt':
      case 'Living Expenses':
        return {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF97316)};
      case 'Chi phí phát sinh':
      case 'Occasional Expenses':
        return {'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEAB308)};
      case 'Chi phí cố định':
      case 'Fixed Expenses':
        return {'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF3B82F6)};
      case 'Đầu tư - tiết kiệm':
      case 'Investment & Savings':
        return {'icon': Icons.savings_rounded, 'color': const Color(0xFF10B981)};
      case 'Thu nhập':
      case 'Income':
        return {'icon': Icons.account_balance_rounded, 'color': const Color(0xFF8B5CF6)};
      default:
        return {'icon': Icons.category_rounded, 'color': colors.primary};
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
                if (_selectedParent != null) ...[
                  GestureDetector(
                    onTap: () => setState(() => _selectedParent = null),
                    child: Icon(Icons.arrow_back_ios_rounded, size: 18, color: colors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                ],
                if (_selectedParent != null)
                  Icon(
                    _getParentStyle(_selectedParent!.name, colors)['icon'],
                    color: _getParentStyle(_selectedParent!.name, colors)['color'],
                    size: 22,
                  ),
                if (_selectedParent != null) const SizedBox(width: 8),
                Text(
                  _selectedParent == null
                      ? 'recurring_select_category'.tr(ref)
                      : (_selectedParent!.name.tr(ref)),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Expanded(
            child: _selectedParent == null
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: widget.parents.length,
                    itemBuilder: (context, index) {
                      final parent = widget.parents[index];
                      final style = _getParentStyle(parent.name, colors);
                      final bool hasChildren = parent.children != null && parent.children!.isNotEmpty;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (hasChildren) {
                            setState(() => _selectedParent = parent);
                          } else {
                            widget.onSelected(parent, null);
                            Navigator.pop(context);
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: (style['color'] as Color).withOpacity(0.12),
                              child: Icon(style['icon'] as IconData, color: style['color'] as Color, size: 24),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              parent.name.tr(ref),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final sub = children[index];
                      final iconData = CategoryUIConstants.getIconData(sub.icon);
                      final color = CategoryUIConstants.getColorFromHex(sub.color);
                      final isSelected = widget.selectedCategory?.id == sub.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          widget.onSelected(_selectedParent!, sub);
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: color.withOpacity(isSelected ? 0.25 : 0.12),
                              child: Icon(iconData, color: color, size: 24),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              sub.name.tr(ref),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? color : null,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}