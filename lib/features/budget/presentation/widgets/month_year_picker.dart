import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:intl/intl.dart';

class MonthYearPickerDialog extends ConsumerStatefulWidget {
  final int initialMonth;
  final int initialYear;

  const MonthYearPickerDialog({
    super.key,
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  ConsumerState<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends ConsumerState<MonthYearPickerDialog> {
  late int _selectedMonth;
  late int _selectedYear;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _selectedYear = widget.initialYear;
    _now = DateTime.now();
    
    // Ensure initial selection is not in the past
    if (_selectedYear < _now.year) {
      _selectedYear = _now.year;
    }
    if (_selectedYear == _now.year && _selectedMonth < _now.month) {
      _selectedMonth = _now.month;
    }
  }

  bool _isMonthDisabled(int month, int year) {
    if (year < _now.year) return true;
    if (year == _now.year && month < _now.month) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final years = List.generate(5, (index) => _now.year + index);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_apply_time'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Year Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'year'.tr(ref),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    dropdownColor: colors.surface,
                    underline: const SizedBox(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    items: years.map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text(y.toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedYear = val;
                          // If current year is selected and current month is higher than selected month, auto-adjust month to current month
                          if (_selectedYear == _now.year && _selectedMonth < _now.month) {
                            _selectedMonth = _now.month;
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Month Selector Grid
            Text(
              'month'.tr(ref),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isDisabled = _isMonthDisabled(month, _selectedYear);
                final isSelected = _selectedMonth == month;

                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            _selectedMonth = month;
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : (isDisabled
                              ? colors.textSecondary.withOpacity(0.03)
                              : colors.textSecondary.withOpacity(0.06)),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: colors.primary, width: 1.5)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(
                      ref.read(localeProvider) == 'vi'
                          ? 'Th. $month'
                          : DateFormat.MMM(ref.read(localeProvider)).format(DateTime(2026, month)),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDisabled ? Colors.grey.withOpacity(0.4) : colors.textPrimary),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'cancel'.tr(ref),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'month': _selectedMonth,
                      'year': _selectedYear,
                    });
                  },
                  child: Text(
                    'confirm'.tr(ref),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
