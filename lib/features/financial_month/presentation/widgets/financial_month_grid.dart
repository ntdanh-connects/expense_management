import 'package:expense_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class FinancialMonthGrid extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const FinancialMonthGrid({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: 31,
      itemBuilder: (context, index) {
        final day = index + 1;
        final isSelected = selectedDay == day;

        return GestureDetector(
          onTap: () => onDaySelected(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? colors.incomeGreen : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? colors.incomeGreen 
                    : colors.textSecondary.withOpacity(0.12),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: colors.incomeGreen.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
              ],
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
