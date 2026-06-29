import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class OcrInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String fieldKey;
  final TextInputType keyboardType;
  final bool isActive;
  final VoidCallback onTap;

  const OcrInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.fieldKey,
    required this.keyboardType,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.primary.withOpacity(0.08) : (isDark ? Colors.grey[900] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.primary : color.textSecondary.withOpacity(0.1),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? color.primary : color.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: color.textSecondary, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: TextStyle(
                      color: color.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Chưa nhập',
                      hintStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                    ),
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
