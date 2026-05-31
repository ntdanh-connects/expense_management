import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/shared/widgets/custom_text_field.dart';
import 'package:expense_management/shared/widgets/github_logo.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class DevBypassDialog extends StatefulWidget {
  final String provider;
  final Function(String email) onBypassSubmitted;

  const DevBypassDialog({
    super.key,
    required this.provider,
    required this.onBypassSubmitted,
  });

  static void show(
    BuildContext context, {
    required String provider,
    required Function(String email) onBypassSubmitted,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DevBypassDialog(
        provider: provider,
        onBypassSubmitted: onBypassSubmitted,
      ),
    );
  }

  @override
  State<DevBypassDialog> createState() => _DevBypassDialogState();
}

class _DevBypassDialogState extends State<DevBypassDialog> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'test_${widget.provider}@example.com');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.authCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.textSecondary.withOpacity(0.1)),
      ),
      title: Row(
        children: [
          widget.provider == 'google'
              ? Icon(
                  Icons.g_mobiledata_rounded,
                  color: colors.primary,
                  size: 32,
                )
              : GithubLogo(
                  size: 32,
                  color: colors.primary,
                ),
          const SizedBox(width: 8),
          const Text(
            'Sandbox Dev Bypass',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cấu hình ${widget.provider == 'google' ? 'Google Services' : 'GitHub Client ID'} chưa được kích hoạt hoàn tất. Hãy nhập Email giả lập để tiếp tục thử nghiệm luồng nghiệp vụ:',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              hintText: 'email@example.com',
              prefixIcon: Icons.email_outlined,
              validator: (val) =>
                  (val == null || !val.contains('@')) ? 'Email sai định dạng!' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Hủy',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final email = _emailController.text.trim();
              Navigator.of(context).pop();
              widget.onBypassSubmitted(email);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Bypass', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
