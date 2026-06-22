import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/utils/currency_utils.dart';
import 'package:expense_management/features/savings/presentation/provider/savings_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class CreateSavingsGoalScreen extends ConsumerStatefulWidget {
  const CreateSavingsGoalScreen({super.key});

  @override
  ConsumerState<CreateSavingsGoalScreen> createState() => _CreateSavingsGoalScreenState();
}

class _CreateSavingsGoalScreenState extends ConsumerState<CreateSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _autoSaveAmountController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _enableAutoSave = false;
  String _autoSaveFrequency = 'daily';
  String? _selectedWalletId;

  late final CurrencyTextInputFormatter _targetFormatter;
  late final CurrencyTextInputFormatter _autoSaveFormatter;

  @override
  void initState() {
    super.initState();
    _targetFormatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: '',
    );
    _autoSaveFormatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: '',
    );
    _targetAmountController.addListener(_updateTargetAmountWords);
    _autoSaveAmountController.addListener(_updateAutoSaveAmountWords);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _autoSaveAmountController.dispose();
    super.dispose();
  }

  void _updateTargetAmountWords() {
    setState(() {});
  }

  void _updateAutoSaveAmountWords() {
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: context.colors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final walletState = ref.watch(walletNotifierProvider);
    final localeCode = ref.watch(localeProvider);

    final double targetAmt = _targetFormatter.getDouble().toDouble();
    final double autoSaveAmt = _autoSaveFormatter.getDouble().toDouble();
    final targetAmountWords = formatNumberToWords(targetAmt, localeCode);
    final autoSaveAmountWords = formatNumberToWords(autoSaveAmt, localeCode);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'savings_create_title'.tr(ref),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TÊN MỤC TIÊU CARD
              _buildSectionCard(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'savings_goal_name_label'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'savings_goal_name_hint'.tr(ref),
                        hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: colors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'savings_enter_goal_name_error'.tr(ref);
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. SỐ TIỀN MỤC TIÊU CARD
              _buildSectionCard(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'savings_target_amount_title'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_targetFormatter],
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: 'đ',
                        suffixStyle: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: colors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'savings_enter_target_amount_error'.tr(ref);
                        }
                        final amount = _targetFormatter.getDouble().toDouble();
                        if (amount < 1000) {
                          return 'savings_min_amount_error'.tr(ref);
                        }
                        if (amount > 500000000) {
                          return 'savings_max_target_amount_error'.tr(ref);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Tiền bằng chữ dưới ô nhập tiền
                    Text(
                      'savings_in_words'.tr(ref).replaceAll('{words}', targetAmountWords),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. THỜI HẠN & VÍ NGUỒN CARD
              _buildSectionCard(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'savings_deadline_title'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'savings_select_date_hint'.tr(ref)
                                  : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? colors.textSecondary.withOpacity(0.6)
                                    : colors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            Icon(Icons.calendar_today_rounded, color: colors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'savings_source_wallet_title'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    walletState.when(
                      data: (wallets) {
                        final list = wallets.where((w) => !w.isHidden).toList();
                        return DropdownButtonFormField<String>(
                          dropdownColor: colors.surface,
                          style: TextStyle(color: colors.textPrimary, fontSize: 15),
                          value: _selectedWalletId,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: colors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          hint: Text(
                            'savings_select_source_wallet_hint'.tr(ref),
                            style: TextStyle(color: colors.textSecondary.withOpacity(0.6)),
                          ),
                          items: list.map((wallet) {
                            return DropdownMenuItem<String>(
                              value: wallet.id,
                              child: Text('${wallet.name} (${NumberFormat('#,###', 'vi_VN').format(wallet.balance)} đ)'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedWalletId = val;
                            });
                          },
                        );
                      },
                      loading: () {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
                        final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
                        return Shimmer.fromColors(
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                          child: Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      error: (err, _) => Text(
                        'savings_wallet_load_error'.tr(ref).replaceAll('{error}', err.toString()),
                        style: TextStyle(color: colors.expenseRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. CÀI ĐẶT TỰ ĐỘNG TÍCH LŨY
              _buildSectionCard(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'savings_autosave_label'.tr(ref),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'savings_autosave_desc'.tr(ref),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _enableAutoSave,
                          activeColor: colors.primary,
                          onChanged: (val) {
                            setState(() {
                              _enableAutoSave = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_enableAutoSave) ...[
                      const Divider(height: 24),
                      Text(
                        'savings_frequency_title'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildFrequencyOption('daily', 'savings_freq_daily_label'.tr(ref)),
                          const SizedBox(width: 8),
                          _buildFrequencyOption('weekly', 'savings_freq_weekly_label'.tr(ref)),
                          const SizedBox(width: 8),
                          _buildFrequencyOption('monthly', 'savings_freq_monthly_label'.tr(ref)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'savings_autosave_amount_title'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _autoSaveAmountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_autoSaveFormatter],
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: 'đ',
                          suffixStyle: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (!_enableAutoSave) return null;
                          if (value == null || value.isEmpty) {
                            return 'savings_enter_autosave_amount_error'.tr(ref);
                          }
                          final val = _autoSaveFormatter.getDouble().toDouble();
                          if (val < 1000) {
                            return 'savings_min_amount_error'.tr(ref);
                          }
                          if (val > 500000000) {
                            return 'savings_max_amount_error'.tr(ref);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'savings_in_words'.tr(ref).replaceAll('{words}', autoSaveAmountWords),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BUTTON TẠO
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'savings_create_btn'.tr(ref),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String frequency, String label) {
    final isSelected = _autoSaveFrequency == frequency;
    final colors = context.colors;
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _autoSaveFrequency = frequency;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? colors.primary.withOpacity(0.08) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? colors.primary : colors.textSecondary.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.primary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required AppColorsExtension colors, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
      ),
      child: child,
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_enableAutoSave && _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('savings_select_wallet_for_autosave_error'.tr(ref))),
      );
      return;
    }

    final name = _nameController.text.trim();
    final targetAmount = _targetFormatter.getDouble().toDouble();
    final targetDate = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;
    final autoSaveFrequency = _enableAutoSave ? _autoSaveFrequency : null;
    final autoSaveAmount = _enableAutoSave ? _autoSaveFormatter.getDouble().toDouble() : null;
    final sourceWalletId = _selectedWalletId;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(savingsListProvider.notifier).createGoal(
            name: name,
            targetAmount: targetAmount,
            targetDate: targetDate,
            autoSaveFrequency: autoSaveFrequency,
            autoSaveAmount: autoSaveAmount,
            sourceWalletId: sourceWalletId,
          );

      if (mounted) {
        context.pop(); // Pop loading dialog
        context.pop(); // Back to list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('savings_create_success'.tr(ref))),
        );
      }
    } catch (e) {
      if (mounted) {
        context.pop(); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('savings_detail_error'.tr(ref).replaceAll('{error}', e.toString()))),
        );
      }
    }
  }
}
