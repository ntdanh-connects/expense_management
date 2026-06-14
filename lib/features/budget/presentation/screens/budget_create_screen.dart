import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/budget/presentation/widgets/month_year_picker.dart';
import 'package:expense_management/features/budget/presentation/widgets/category_selector_dialog.dart';
import 'package:intl/intl.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:shimmer/shimmer.dart';

// Currency conversion helper (same pattern as budget_screen)
double _convertToDisplayCurrency(
  double amount,
  String fromCurrency,
  String toCurrency,
  dynamic ratesData,
) {
  final from = fromCurrency.toUpperCase();
  final to = toCurrency.toUpperCase();
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

class TempCategoryBudget {
  final String? id; // Database id, null if new
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final TextEditingController controller;
  final CurrencyTextInputFormatter formatter;

  TempCategoryBudget({
    this.id,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.controller,
    required this.formatter,
  });
}

class BudgetCreateScreen extends ConsumerStatefulWidget {
  const BudgetCreateScreen({super.key});

  @override
  ConsumerState<BudgetCreateScreen> createState() => _BudgetCreateScreenState();
}

class _BudgetCreateScreenState extends ConsumerState<BudgetCreateScreen> {
  final _overallBudgetController = TextEditingController();
  late CurrencyTextInputFormatter _overallFormatter;
  final _formKey = GlobalKey<FormState>();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _copyFromPrevious = false;
  bool _isLoadingData = false;
  bool _isSaving = false;
  bool _autoCalculateTotal = false;

  List<BudgetDto> _originalBudgets = [];
  final List<TempCategoryBudget> _categoryBudgetsList = [];

  @override
  void initState() {
    super.initState();
    _overallFormatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: '',
    );
    
    // Auto-select starting month/year
    final defaultMonth = ref.read(selectedBudgetMonthProvider);
    final defaultYear = ref.read(selectedBudgetYearProvider);
    final now = DateTime.now();
    
    // Constraint: cannot set budgets in the past
    if (defaultYear < now.year || (defaultYear == now.year && defaultMonth < now.month)) {
      _selectedMonth = now.month;
      _selectedYear = now.year;
    } else {
      _selectedMonth = defaultMonth;
      _selectedYear = defaultYear;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgetsForDate(_selectedMonth, _selectedYear);
    });
  }

  @override
  void dispose() {
    _overallBudgetController.dispose();
    for (var item in _categoryBudgetsList) {
      item.controller.dispose();
    }
    super.dispose();
  }

  double _getOverallAmount() {
    return _overallFormatter.getDouble();
  }

  double _getSumOfCategoryBudgets() {
    double sum = 0;
    for (var item in _categoryBudgetsList) {
      sum += item.formatter.getDouble();
    }
    return sum;
  }

  void _updateOverallBudgetIfAuto() {
    if (_autoCalculateTotal) {
      final sum = _getSumOfCategoryBudgets();
      _overallBudgetController.text = _overallFormatter.formatDouble(sum);
    }
  }

  Future<void> _loadBudgetsForDate(int month, int year) async {
    setState(() {
      _isLoadingData = true;
      _copyFromPrevious = false;
    });
    try {
      final repository = ref.read(budgetRepositoryProvider);
      final budgets = await repository.getBudgets(month, year);
      
      // Separate overall budget and category budgets
      final general = budgets.where((b) => b.categoryId == null).firstOrNull;
      final categories = budgets.where((b) => b.categoryId != null).toList();
      
      _categoryBudgetsList.clear();

      final userCurrency = ref.read(currentUserProvider)?.currency ?? 'VND';
      final ratesData = ref.read(exchangeRatesProvider).value;
      
      setState(() {
        _originalBudgets = budgets;
        double sumOfCats = 0;
        for (var b in categories) {
          sumOfCats += b.limitAmount;
        }
        if (general != null && sumOfCats > 0 && general.limitAmount == sumOfCats) {
          _autoCalculateTotal = true;
        } else {
          _autoCalculateTotal = false;
        }

        if (general != null) {
          final displayAmount = _convertToDisplayCurrency(general.limitAmount, 'VND', userCurrency, ratesData);
          _overallBudgetController.text = _overallFormatter.formatDouble(displayAmount);
        } else {
          _overallBudgetController.text = '';
        }

        for (var b in categories) {
          final formatter = CurrencyTextInputFormatter.currency(
            locale: 'vi',
            decimalDigits: 0,
            symbol: '',
          );
          final displayAmount = _convertToDisplayCurrency(b.limitAmount, 'VND', userCurrency, ratesData);
          final controller = TextEditingController(text: formatter.formatDouble(displayAmount));
          _categoryBudgetsList.add(TempCategoryBudget(
            id: b.id,
            categoryId: b.categoryId!,
            categoryName: b.category?.name ?? 'uncategorized'.trRead(ref),
            categoryIcon: b.category?.icon,
            categoryColor: b.category?.color,
            controller: controller,
            formatter: formatter,
          ));
        }
      });
    } catch (e) {
      // Ignore or show error
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _toggleCopyFromPrevious(bool val) async {
    if (!val) {
      setState(() {
        _copyFromPrevious = false;
      });
      // Restore from DB for current date
      _loadBudgetsForDate(_selectedMonth, _selectedYear);
      return;
    }

    setState(() {
      _isLoadingData = true;
      _copyFromPrevious = true;
    });

    try {
      int fromMonth = _selectedMonth - 1;
      int fromYear = _selectedYear;
      if (fromMonth == 0) {
        fromMonth = 12;
        fromYear = _selectedYear - 1;
      }

      final repository = ref.read(budgetRepositoryProvider);
      final prevBudgets = await repository.getBudgets(fromMonth, fromYear);

      if (prevBudgets.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('no_prev_budget_to_copy'.trRead(ref)),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _copyFromPrevious = false;
            _isLoadingData = false;
          });
        }
        return;
      }

      final general = prevBudgets.where((b) => b.categoryId == null).firstOrNull;
      final categories = prevBudgets.where((b) => b.categoryId != null).toList();

      _categoryBudgetsList.clear();

      final userCurrency = ref.read(currentUserProvider)?.currency ?? 'VND';
      final ratesData = ref.read(exchangeRatesProvider).value;

      setState(() {
        double sumOfCats = 0;
        for (var b in categories) {
          sumOfCats += b.limitAmount;
        }
        if (general != null && sumOfCats > 0 && general.limitAmount == sumOfCats) {
          _autoCalculateTotal = true;
        } else {
          _autoCalculateTotal = false;
        }

        if (general != null) {
          final displayAmount = _convertToDisplayCurrency(general.limitAmount, 'VND', userCurrency, ratesData);
          _overallBudgetController.text = _overallFormatter.formatDouble(displayAmount);
        } else {
          _overallBudgetController.text = '';
        }

        for (var b in categories) {
          final formatter = CurrencyTextInputFormatter.currency(
            locale: 'vi',
            decimalDigits: 0,
            symbol: '',
          );
          final displayAmount = _convertToDisplayCurrency(b.limitAmount, 'VND', userCurrency, ratesData);
          final controller = TextEditingController(text: formatter.formatDouble(displayAmount));
          _categoryBudgetsList.add(TempCategoryBudget(
            id: null, // This is a new budget copy, id is null
            categoryId: b.categoryId!,
            categoryName: b.category?.name ?? 'uncategorized'.trRead(ref),
            categoryIcon: b.category?.icon,
            categoryColor: b.category?.color,
            controller: controller,
            formatter: formatter,
          ));
        }
        _isLoadingData = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('copied_prev_budget_success'.trRead(ref)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _copyFromPrevious = false;
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_occurred'.trRead(ref)}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showMonthYearPicker() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => MonthYearPickerDialog(
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMonth = result['month']!;
        _selectedYear = result['year']!;
      });
      _loadBudgetsForDate(_selectedMonth, _selectedYear);
    }
  }

  void _showCategorySelector() async {
    final allCategories = ref.read(categoriesNotifierProvider).value ?? [];
    final excludedIds = _categoryBudgetsList.map((c) => c.categoryId).toSet();

    final selectedSubcategory = await showDialog<CategoryDto>(
      context: context,
      builder: (context) => ParentChildCategoryPickerDialog(
        allCategories: allCategories,
        excludedCategoryIds: excludedIds,
      ),
    );

    if (selectedSubcategory != null) {
      final formatter = CurrencyTextInputFormatter.currency(
        locale: 'vi',
        decimalDigits: 0,
        symbol: '',
      );
      final controller = TextEditingController();
      
      setState(() {
        _categoryBudgetsList.add(TempCategoryBudget(
          id: null,
          categoryId: selectedSubcategory.id,
          categoryName: selectedSubcategory.name,
          categoryIcon: selectedSubcategory.icon,
          categoryColor: selectedSubcategory.color,
          controller: controller,
          formatter: formatter,
        ));
        _updateOverallBudgetIfAuto();
      });
    }
  }

  Future<void> _saveAllBudgets() async {
    if (!_formKey.currentState!.validate()) return;

    final userCurrency = ref.read(currentUserProvider)?.currency ?? 'VND';
    final ratesData = ref.read(exchangeRatesProvider).value;

    // Convert display amounts back to VND (server currency) before saving
    double toVnd(double displayAmount) =>
        _convertToDisplayCurrency(displayAmount, userCurrency, 'VND', ratesData);

    final overallDisplayAmount = _autoCalculateTotal ? _getSumOfCategoryBudgets() : _getOverallAmount();
    final overallAmount = toVnd(overallDisplayAmount);
    final sumOfCategoriesDisplay = _getSumOfCategoryBudgets();
    final sumOfCategories = toVnd(sumOfCategoriesDisplay);

    if (overallAmount <= 0 && _categoryBudgetsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_setup_at_least_one_budget'.trRead(ref)),
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

      // 1. Save overall budget if it has an amount
      if (overallAmount > 0) {
        await repository.createOrUpdateBudget(
          categoryId: null,
          limitAmount: overallAmount,
          month: _selectedMonth,
          year: _selectedYear,
        );
      } else {
        // If overall budget is set to 0 or empty, and it previously existed, delete it
        final existingGeneral = _originalBudgets.where((b) => b.categoryId == null).firstOrNull;
        if (existingGeneral != null) {
          await repository.deleteBudget(existingGeneral.id);
        }
      }

      // 2. Save detailed category budgets
      for (var item in _categoryBudgetsList) {
        final displayAmount = item.formatter.getDouble();
        final amount = toVnd(displayAmount);
        if (amount > 0) {
          await repository.createOrUpdateBudget(
            categoryId: item.categoryId,
            limitAmount: amount,
            month: _selectedMonth,
            year: _selectedYear,
          );
        }
      }

      // 3. Delete any categories that were in _originalBudgets but are no longer in _categoryBudgetsList
      final currentCategoryIds = _categoryBudgetsList.map((c) => c.categoryId).toSet();
      final deletedBudgets = _originalBudgets
          .where((b) => b.categoryId != null && !currentCategoryIds.contains(b.categoryId))
          .toList();

      for (var b in deletedBudgets) {
        await repository.deleteBudget(b.id);
      }

      // Sync Month/Year selectors of parent screens to this created budget date
      ref.read(selectedBudgetMonthProvider.notifier).state = _selectedMonth;
      ref.read(selectedBudgetYearProvider.notifier).state = _selectedYear;
      await ref.read(budgetListProvider.notifier).refreshBudgets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('setup_budget_success'.trRead(ref)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_occurred'.trRead(ref)}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final userCurrency = ref.watch(currentUserProvider)?.currency ?? 'VND';
    final currencySymbol = AppConstant.getCurrencySymbol(userCurrency);
    
    final overallAmount = _getOverallAmount();
    final sumOfCategories = _getSumOfCategoryBudgets();
    final remainingAmount = overallAmount - sumOfCategories;
    
    double progressRatio = 0.0;
    if (overallAmount > 0) {
      progressRatio = sumOfCategories / overallAmount;
    }

    Color progressColor = colors.incomeGreen;
    if (progressRatio >= 1.0) {
      progressColor = colors.expenseRed;
    } else if (progressRatio >= 0.8) {
      progressColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'budget_create'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _isSaving || _isLoadingData ? null : _saveAllBudgets,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'budget_save'.tr(ref),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoadingData
          ? const _BudgetCreateShimmer()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Thời gian áp dụng
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: _showMonthYearPicker,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'apply_time'.tr(ref),
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat.yMMMM(ref.watch(localeProvider)).format(DateTime(_selectedYear, _selectedMonth)),
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down_rounded, color: colors.primary, size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'copy_previous_desc'.tr(ref),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _copyFromPrevious,
                                activeThumbColor: colors.primary,
                                onChanged: (val) {
                                  _toggleCopyFromPrevious(val);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Tổng ngân sách dự kiến
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'expected_overall_budget'.tr(ref),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'budget_mode_sum_categories'.tr(ref),
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    height: 28,
                                    width: 44,
                                    child: FittedBox(
                                      fit: BoxFit.fill,
                                      child: Switch(
                                        value: _autoCalculateTotal,
                                        activeThumbColor: colors.primary,
                                        onChanged: (val) {
                                          setState(() {
                                            _autoCalculateTotal = val;
                                            _updateOverallBudgetIfAuto();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _overallBudgetController,
                                  keyboardType: TextInputType.number,
                                  readOnly: _autoCalculateTotal,
                                  style: TextStyle(
                                    color: _autoCalculateTotal ? colors.textSecondary : colors.textPrimary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.3)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  inputFormatters: [_overallFormatter],
                                  onChanged: (val) {
                                    setState(() {});
                                  },
                                ),
                              ),
                              Text(
                                currencySymbol,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_autoCalculateTotal) ...[
                            Text(
                              'budget_mode_sum_desc'.tr(ref),
                              style: TextStyle(
                                  color: colors.textSecondary.withOpacity(0.7),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  remainingAmount >= 0 ? 'remaining_limit'.tr(ref) : 'exceeded_limit'.tr(ref),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${AppConstant.formatMoney(remainingAmount.abs(), userCurrency)} $currencySymbol',
                                  style: TextStyle(
                                    color: remainingAmount >= 0 ? colors.incomeGreen : colors.expenseRed,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressRatio.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: colors.textSecondary.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title: Hạn mức chi tiết
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'detailed_limit'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Detailed lists of category budgets
                    if (_categoryBudgetsList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
                        ),
                        child: Center(
                          child: Text(
                            'no_detailed_limit_yet'.tr(ref),
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categoryBudgetsList.length,
                        itemBuilder: (context, index) {
                          final item = _categoryBudgetsList[index];
                          final categoryIcon = CategoryUIConstants.getIconData(item.categoryIcon, categoryName: item.categoryName);
                          final categoryColor = CategoryUIConstants.getColorFromHex(item.categoryColor, categoryName: item.categoryName);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.005),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(categoryIcon, color: categoryColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                
                                // Name & Input
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.categoryName,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      TextFormField(
                                        controller: item.controller,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Nhập hạn mức...',
                                          hintStyle: TextStyle(
                                            color: colors.textSecondary.withOpacity(0.3),
                                            fontSize: 13,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          suffixText: currencySymbol,
                                          suffixStyle: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.12)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.12)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: colors.primary, width: 1.2),
                                          ),
                                        ),
                                        inputFormatters: [item.formatter],
                                        onChanged: (val) {
                                          setState(() {
                                            _updateOverallBudgetIfAuto();
                                          });
                                        },
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'please_enter_limit'.tr(ref);
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
 
                                // Delete Button
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: colors.expenseRed.withOpacity(0.7)),
                                  onPressed: () {
                                    setState(() {
                                      _categoryBudgetsList.removeAt(index);
                                      _updateOverallBudgetIfAuto();
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 14),

                    // Add Category Button
                    InkWell(
                      onTap: _showCategorySelector,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.3),
                            width: 1.2,
                            style: BorderStyle.solid, // Custom paint for dashes is possible, but solid is very clean
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: colors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'add_category'.tr(ref),
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Quote Card
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'budget_quote'.tr(ref),
                          style: TextStyle(
                            color: colors.textSecondary.withOpacity(0.8),
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BudgetCreateShimmer extends StatelessWidget {
  const _BudgetCreateShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Apply time
            Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            // Card 2: Expected overall budget
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),
            // Section Title
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Category budgets list
            for (int i = 0; i < 2; i++) ...[
              Container(
                width: double.infinity,
                height: 80,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Add Category Button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}