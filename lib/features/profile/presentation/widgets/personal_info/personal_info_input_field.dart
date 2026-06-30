import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class PersonalInfoInputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool readOnly;
  final String? Function(String?)? validator;

  const PersonalInfoInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.readOnly = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: readOnly ? colors.surface.withOpacity(0.5) : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: readOnly ? colors.textSecondary.withOpacity(0.5) : colors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: readOnly ? colors.textSecondary.withOpacity(0.5) : colors.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  validator: validator,
                  style: TextStyle(
                    color: readOnly ? colors.textSecondary : colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
