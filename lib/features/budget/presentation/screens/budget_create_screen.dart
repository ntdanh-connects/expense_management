import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/budget/presentation/widgets/month_year_picker.dart';
import 'package:expense_management/features/budget/presentation/widgets/category_selector_dialog.dart';
import 'package:intl/intl.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget_create/budget_create_apply_time_card.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget_create/budget_create_overall_limit_card.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget_create/budget_create_category_limit_item.dart';
import 'package:expense_management/features/budget/presentation/widgets/budget_create/budget_create_shimmer.dart';

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

class BudgetCreateScreen extends ConsumerStatefulWidget {
  final String? preselectedCategoryId;
  final double? suggestedAmount;

  const BudgetCreateScreen({
    super.key,
    this.preselectedCategoryId,
    this.suggestedAmount,
  });

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

        if (widget.preselectedCategoryId != null) {
          final alreadyExists = _categoryBudgetsList.any((c) => c.categoryId == widget.preselectedCategoryId);
          if (!alreadyExists) {
            final allCategories = ref.read(categoriesNotifierProvider).value ?? [];
            final cat = allCategories.where((c) => c.id == widget.preselectedCategoryId).firstOrNull;
            if (cat != null) {
              final formatter = CurrencyTextInputFormatter.currency(
                locale: 'vi',
                decimalDigits: 0,
                symbol: '',
              );
              final displayAmount = _convertToDisplayCurrency(widget.suggestedAmount ?? 1000000.0, 'VND', userCurrency, ratesData);
              final controller = TextEditingController(text: formatter.formatDouble(displayAmount));
              _categoryBudgetsList.add(TempCategoryBudget(
                id: null,
                categoryId: cat.id,
                categoryName: cat.name,
                categoryIcon: cat.icon,
                categoryColor: cat.color,
                controller: controller,
                formatter: formatter,
              ));
            }
          }
        }
      });
    } catch (e) {
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
            id: null,
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

    double toVnd(double displayAmount) =>
        _convertToDisplayCurrency(displayAmount, userCurrency, 'VND', ratesData);

    final overallDisplayAmount = _autoCalculateTotal ? _getSumOfCategoryBudgets() : _getOverallAmount();
    final overallAmount = toVnd(overallDisplayAmount);

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

      if (overallAmount > 0) {
        await repository.createOrUpdateBudget(
          categoryId: null,
          limitAmount: overallAmount,
          month: _selectedMonth,
          year: _selectedYear,
        );
      } else {
        final existingGeneral = _originalBudgets.where((b) => b.categoryId == null).firstOrNull;
        if (existingGeneral != null) {
          await repository.deleteBudget(existingGeneral.id);
        }
      }

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

      final currentCategoryIds = _categoryBudgetsList.map((c) => c.categoryId).toSet();
      final deletedBudgets = _originalBudgets
          .where((b) => b.categoryId != null && !currentCategoryIds.contains(b.categoryId))
          .toList();

      for (var b in deletedBudgets) {
        await repository.deleteBudget(b.id);
      }

      ref.read(selectedBudgetMonthProvider.notifier).state = _selectedMonth;
      ref.read(selectedBudgetYearProvider.notifier).state = _selectedYear;
      await ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);

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
    final userCurrency = ref.watch(currentUserProvider.select((u) => u?.currency)) ?? 'VND';
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
          ? const BudgetCreateShimmer()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BudgetCreateApplyTimeCard(
                      selectedMonth: _selectedMonth,
                      selectedYear: _selectedYear,
                      copyFromPrevious: _copyFromPrevious,
                      onTapMonthYearPicker: _showMonthYearPicker,
                      onCopyChanged: _toggleCopyFromPrevious,
                    ),
                    const SizedBox(height: 16),

                    BudgetCreateOverallLimitCard(
                      overallBudgetController: _overallBudgetController,
                      autoCalculateTotal: _autoCalculateTotal,
                      onAutoCalculateChanged: (val) {
                        setState(() {
                          _autoCalculateTotal = val;
                          _updateOverallBudgetIfAuto();
                        });
                      },
                      overallFormatter: _overallFormatter,
                      currencySymbol: currencySymbol,
                      userCurrency: userCurrency,
                      remainingAmount: remainingAmount,
                      progressRatio: progressRatio,
                      progressColor: progressColor,
                      onOverallChanged: (val) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),

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
                          return BudgetCreateCategoryLimitItem(
                            item: item,
                            currencySymbol: currencySymbol,
                            onDelete: () {
                              setState(() {
                                _categoryBudgetsList.removeAt(index);
                                _updateOverallBudgetIfAuto();
                              });
                            },
                            onChanged: (val) {
                              setState(() {
                                _updateOverallBudgetIfAuto();
                              });
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 14),

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
                            style: BorderStyle.solid,
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