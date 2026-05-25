import 'package:expense_management/shared/widgets/theme_toggle_button.dart';
import 'package:flutter/material.dart';

class AuthHeaderAction extends StatelessWidget {
  const AuthHeaderAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        right: 16 
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ThemeToggleButton()
        ],
      ), 
    );
  }
}