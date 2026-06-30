import 'package:expense_management/core/language/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:intl/intl.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget_edit/budget_edit_progress_card.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget_edit/budget_edit_limit_setting_card.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget_edit/budget_edit_history_card.dart';

// Currency conversion helper
double _convertBudgetAmount(
  double amount,
  String fromCurrency,
  String userCurrency,
  dynamic ratesData,
) {
  final from = fromCurrency.toUpperCase();
  final to = userCurrency.toUpperCase();
  if (from == to) return amount;

  const fallbackRates = {
    'USD': 1.0, 'VND': 25400.0, 'EUR': 0.92,
    'GBP': 0.78, 'JPY': 156.0,
  };

  final base = (ratesData?.base ?? 'USD').toUpperCase();
  final rates = ratesData?.rates.map(
    (k, v) => MapEntry(k.toUpperCase(), v.toDouble()),
  ) ?? fallbackRates;

  final fromRate = from == base ? 1.0 : (rates[from] ?? 1.0);
  final toRate   = to == base   ? 1.0 : (rates[to]   ?? 1.0);

  return amount * (toRate / fromRate);
}

class BudgetEditScreen extends ConsumerStatefulWidget {
  final BudgetDto budget;

  const BudgetEditScreen({
    super.key,
    required this.budget,
  });

  @override
  ConsumerState<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends ConsumerState<BudgetEditScreen> {
  final _amountController = TextEditingController();
  late CurrencyTextInputFormatter _formatter;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _alert80 = true;
  bool _alert100 = true;

  List<Map<String, dynamic>> _historyData = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _formatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: '',
    );
    // Convert from server currency (VND) to user's display currency before showing
    final userCurrency = ref.read(currentUserProvider)?.currency ?? 'VND';
    final ratesData = ref.read(exchangeRatesProvider).value;
    final displayAmount = _convertBudgetAmount(widget.budget.limitAmount, 'VND', userCurrency, ratesData);
    _amountController.text = _formatter.formatDouble(displayAmount);
    _loadAlertPreferences();
    _loadHistoryData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _loadAlertPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _alert80 = prefs.getBool('budget_alert_80_${widget.budget.id}') ?? true;
        _alert100 = prefs.getBool('budget_alert_100_${widget.budget.id}') ?? true;
      });
    }
  }

  void _saveAlertPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('budget_alert_80_${widget.budget.id}', _alert80);
    await prefs.setBool('budget_alert_100_${widget.budget.id}', _alert100);
  }

  Future<void> _loadHistoryData() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    try {
      final repository = ref.read(budgetRepositoryProvider);
      final locale = ref.read(localeProvider);
      
      final futures = List.generate(3, (index) async {
        int targetMonth = widget.budget.month - (index + 1);
        int targetYear = widget.budget.year;
        if (targetMonth <= 0) {
          targetMonth += 12;
          targetYear -= 1;
        }
        
        final budgets = await repository.getBudgets(targetMonth, targetYear);
        final matching = budgets.where((b) => b.categoryId == widget.budget.categoryId).firstOrNull;
        
        String monthLabel = DateFormat.MMMM(locale).format(DateTime(targetYear, targetMonth));
        if (monthLabel.isNotEmpty) {
          monthLabel = monthLabel[0].toUpperCase() + monthLabel.substring(1);
        }
        double limit = matching?.limitAmount ?? 0.0;
        double used = matching?.usedAmount ?? 0.0;
        
        return {
          'monthLabel': monthLabel,
          'limit': limit,
          'used': used,
        };
      });
      
      final results = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _historyData = results;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  bool _isPastMonth(int month, int year) {
    final now = DateTime.now();
    if (year < now.year) return true;
    if (year == now.year && month < now.month) return true;
    return false;
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final userCurrency = ref.read(currentUserProvider)?.currency ?? 'VND';
    final ratesData = ref.read(exchangeRatesProvider).value;
    final displayAmount = _formatter.getDouble();
    // Convert from user's display currency back to VND (server currency)
    final limitAmount = _convertBudgetAmount(displayAmount, userCurrency, 'VND', ratesData);
    if (limitAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_enter_valid_limit'.tr(ref)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(budgetRepositoryProvider);
      await repository.createOrUpdateBudget(
        categoryId: widget.budget.categoryId,
        limitAmount: limitAmount,
        month: widget.budget.month,
        year: widget.budget.year,
      );
      
      _saveAlertPreferences();

      await ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('update_recurring_success'.tr(ref)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_occurred'.tr(ref)}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteBudget() async {
    final colors = context.colors;
    final isOverall = widget.budget.categoryId == null;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${'delete'.tr(ref)} ${'budget_title'.tr(ref).toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          isOverall 
              ? 'delete_overall_budget_confirm_msg'.tr(ref) 
              : 'delete_budget_confirm_msg'.tr(ref),
        ),
        actions: [
          TextButton(
            child: Text('budget_cancel'.tr(ref), style: TextStyle(color: colors.textSecondary)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.expenseRed),
            child: Text('delete'.tr(ref), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final repository = ref.read(budgetRepositoryProvider);
      
      if (isOverall) {
        final allBudgets = ref.read(budgetListProvider).value ?? [];
        for (final b in allBudgets) {
          if (b.id != widget.budget.id) {
            await repository.deleteBudget(b.id);
          }
        }
      }

      await repository.deleteBudget(widget.budget.id);

      await ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delete_budget_success'.tr(ref)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_occurred'.tr(ref)}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isReadOnly = _isPastMonth(widget.budget.month, widget.budget.year);
    final userCurrency = ref.watch(currentUserProvider.select((u) => u?.currency)) ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    final ratesData = ref.watch(exchangeRatesProvider).value;

    final displayAmountInput = _formatter.getDouble();
    final limitAmountVnd = _convertBudgetAmount(displayAmountInput, userCurrency, 'VND', ratesData);
    final usedAmountVnd = widget.budget.usedAmount;

    // Convert for display
    final limitAmount = _convertBudgetAmount(limitAmountVnd, 'VND', userCurrency, ratesData);
    final usedAmount = _convertBudgetAmount(usedAmountVnd, 'VND', userCurrency, ratesData);
    final remainingAmount = limitAmount - usedAmount;
    
    double progressRatio = 0.0;
    if (limitAmountVnd > 0) {
      progressRatio = usedAmountVnd / limitAmountVnd;
    }

    Color progressColor = colors.incomeGreen;
    if (progressRatio >= 1.0) {
      progressColor = colors.expenseRed;
    } else if (progressRatio >= 0.8) {
      progressColor = Colors.orange;
    }

    final categoryName = widget.budget.categoryId == null 
        ? 'overall_budget'.tr(ref) 
        : (widget.budget.category?.name ?? 'uncategorized'.tr(ref));
    final categoryIconStr = widget.budget.category?.icon;
    final categoryColorStr = widget.budget.category?.color;

    final categoryIcon = widget.budget.categoryId == null 
        ? Icons.account_balance_wallet_rounded 
        : CategoryUIConstants.getIconData(categoryIconStr, categoryName: categoryName);
    final categoryColor = widget.budget.categoryId == null 
        ? colors.primary 
        : CategoryUIConstants.getColorFromHex(categoryColorStr, categoryName: categoryName);

    // Alert thresholds mapping
    final threshold80Amount = limitAmount * 0.8;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isReadOnly 
              ? 'budget_history'.tr(ref) 
              : '${'budget_title'.tr(ref)} $categoryName',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isReadOnly) ...[
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: colors.expenseRed),
              onPressed: _isSaving || _isDeleting ? null : _deleteBudget,
            ),
          ]
        ],
      ),
      body: _isSaving || _isDeleting
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Hộp tiến độ sử dụng hiện tại
                    BudgetEditProgressCard(
                      usedAmount: usedAmount,
                      remainingAmount: remainingAmount,
                      progressRatio: progressRatio,
                      progressColor: progressColor,
                      categoryIcon: categoryIcon,
                      categoryColor: categoryColor,
                      userCurrency: userCurrency,
                      currencySymbol: currencySymbol,
                    ),
                    const SizedBox(height: 20),

                    // Card 2: Cài đặt hạn mức & cảnh báo
                    Text(
                      'limit_setting'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    BudgetEditLimitSettingCard(
                      amountController: _amountController,
                      isReadOnly: isReadOnly,
                      formatter: _formatter,
                      currencySymbol: currencySymbol,
                      userCurrency: userCurrency,
                      threshold80Amount: threshold80Amount,
                      alert80: _alert80,
                      alert100: _alert100,
                      onAlert80Changed: isReadOnly ? null : (val) {
                        setState(() => _alert80 = val);
                      },
                      onAlert100Changed: isReadOnly ? null : (val) {
                        setState(() => _alert100 = val);
                      },
                      onAmountChanged: (val) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),

                    // Card 3: Lịch sử 3 tháng gần nhất
                    Text(
                      'last_3_months_history'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    BudgetEditHistoryCard(
                      isLoadingHistory: _isLoadingHistory,
                      historyData: _historyData,
                      userCurrency: userCurrency,
                      currencySymbol: currencySymbol,
                      ratesData: ratesData,
                      convertAmount: _convertBudgetAmount,
                    ),
                    const SizedBox(height: 32),

                    // Nút Lưu Thay Đổi
                    if (!isReadOnly)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            'save_changes'.tr(ref),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: _isSaving ? null : _saveBudget,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}