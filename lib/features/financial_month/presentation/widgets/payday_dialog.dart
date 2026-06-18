import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaydayDialog extends ConsumerStatefulWidget {
  final int initialDay;

  const PaydayDialog({
    super.key,
    required this.initialDay,
  });

  @override
  ConsumerState<PaydayDialog> createState() => _PaydayDialogState();
}

class _PaydayDialogState extends ConsumerState<PaydayDialog> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      title: Text(
        'select_payday_title'.tr(ref),
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'select_payday_desc'.tr(ref),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 45,
                perspective: 0.005,
                diameterRatio: 1.2,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedDay = index + 1;
                  });
                },
                controller: FixedExtentScrollController(initialItem: _selectedDay - 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 31,
                  builder: (context, index) {
                    final day = index + 1;
                    final isCurrent = _selectedDay == day;
                    return Center(
                      child: Text(
                        'day_format_simple'.tr(ref).replaceAll('{day}', day.toString().padLeft(2, '0')),
                        style: TextStyle(
                          color: isCurrent ? colors.primary : colors.textSecondary,
                          fontSize: isCurrent ? 20 : 16,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'cancel'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedDay),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(
            'confirm'.tr(ref),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
