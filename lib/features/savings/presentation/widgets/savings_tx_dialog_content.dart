import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/shared/widgets/shimmer_components.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/utils/currency_utils.dart';
import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';
import 'package:expense_management/features/savings/presentation/provider/savings_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';

class SavingsTxDialogContent extends ConsumerStatefulWidget {
  final SavingsGoalEntity goal;
  final String type;
  final BuildContext screenContext;

  const SavingsTxDialogContent({
    super.key,
    required this.goal,
    required this.type,
    required this.screenContext,
  });

  @override
  ConsumerState<SavingsTxDialogContent> createState() => _SavingsTxDialogContentState();
}

class _SavingsTxDialogContentState extends ConsumerState<SavingsTxDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late final CurrencyTextInputFormatter _amountFormatter;
  String? _selectedWalletId;
  bool _isDialogLoading = false;

  @override
  void initState() {
    super.initState();
    _amountFormatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: '',
    );
    _selectedWalletId = widget.goal.sourceWalletId;
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final localeCode = ref.watch(localeProvider);
    final walletState = ref.watch(walletNotifierProvider);

    final double parsedAmount = _amountFormatter.getDouble().toDouble();
    final amountWords = formatNumberToWords(parsedAmount, localeCode);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.type == 'deposit'
                  ? 'savings_deposit_title'.tr(ref)
                  : 'savings_withdraw_title'.tr(ref),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Amount TextField
            TextFormField(
              controller: _amountController,
              enabled: !_isDialogLoading,
              keyboardType: TextInputType.number,
              inputFormatters: [_amountFormatter],
              style: TextStyle(
                color: widget.type == 'deposit' ? colors.incomeGreen : colors.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'savings_transaction_amount_hint'.tr(ref),
                labelStyle: TextStyle(color: colors.textSecondary),
                suffixText: 'đ',
                suffixStyle: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'savings_enter_amount_error'.tr(ref);
                }
                final amount = _amountFormatter.getDouble().toDouble();
                if (amount < 1000) {
                  return 'savings_min_amount_error'.tr(ref);
                }
                if (amount > 500000000) {
                  return 'savings_max_amount_error'.tr(ref);
                }
                if (widget.type == 'withdraw' && amount > widget.goal.currentAmount) {
                  return 'savings_withdraw_exceed_error'
                      .tr(ref)
                      .replaceAll(
                        '{amount}',
                        NumberFormat('#,###').format(widget.goal.currentAmount),
                      );
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'savings_in_words'.tr(ref).replaceAll('{words}', amountWords),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            // Dropdown chọn Ví
            walletState.when(
              data: (wallets) {
                final list = wallets.where((w) => !w.isHidden).toList();
                return DropdownButtonFormField<String>(
                  dropdownColor: colors.surface,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  value: _selectedWalletId,
                  decoration: InputDecoration(
                    labelText: widget.type == 'deposit'
                        ? 'savings_source_wallet_label'.tr(ref)
                        : 'savings_dest_wallet_label'.tr(ref),
                    labelStyle: TextStyle(color: colors.textSecondary),
                    filled: true,
                    fillColor: colors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: list.map((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Text(
                        '${wallet.name} (${NumberFormat('#,###', 'vi_VN').format(wallet.balance)} đ)',
                      ),
                    );
                  }).toList(),
                  onChanged: _isDialogLoading
                      ? null
                      : (val) {
                          setState(() {
                            _selectedWalletId = val;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'savings_select_wallet_error'.tr(ref);
                    }
                    return null;
                  },
                );
              },
              loading: () => const BoxShimmer(height: 56, borderRadius: 12),
              error: (err, _) => Text(
                'savings_wallet_load_error'.tr(ref).replaceAll('{error}', err.toString()),
              ),
            ),
            const SizedBox(height: 16),
            // Notes TextField
            TextFormField(
              controller: _notesController,
              enabled: !_isDialogLoading,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'savings_notes_label'.tr(ref),
                labelStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isDialogLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        final amount = _amountFormatter.getDouble().toDouble();
                        final walletId = _selectedWalletId!;
                        final notes = _notesController.text.trim().isEmpty
                            ? (widget.type == 'deposit'
                                ? 'savings_auto_note_deposit'.tr(ref).replaceAll('{name}', widget.goal.name)
                                : 'savings_auto_note_withdraw'.tr(ref).replaceAll('{name}', widget.goal.name))
                            : _notesController.text.trim();

                        setState(() {
                          _isDialogLoading = true;
                        });

                        final scaffoldMessenger = ScaffoldMessenger.of(widget.screenContext);
                        final dialogMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        try {
                          final detailNotifier = ref.read(savingsDetailProvider(widget.goal.id).notifier);
                          if (widget.type == 'deposit') {
                            await detailNotifier.deposit(
                              amount: amount,
                              sourceWalletId: walletId,
                              notes: notes,
                            );
                          } else {
                            await detailNotifier.withdraw(
                              amount: amount,
                              sourceWalletId: walletId,
                              notes: notes,
                            );
                          }

                          // Sync related wallets and transactions
                          ref.invalidate(walletNotifierProvider);
                          ref.invalidate(transactionListProvider);
                          ref.invalidate(savingsListProvider);

                          if (mounted) {
                            navigator.pop(); // Close bottom sheet
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.type == 'deposit'
                                      ? 'savings_deposit_success'.tr(ref)
                                      : 'savings_withdraw_success'.tr(ref),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: colors.incomeGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isDialogLoading = false;
                            });
                            dialogMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'savings_detail_error'.tr(ref).replaceAll('{error}', e.toString()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: colors.expenseRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.type == 'deposit' ? colors.incomeGreen : colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isDialogLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.type == 'deposit'
                            ? 'savings_confirm_deposit'.tr(ref)
                            : 'savings_confirm_withdraw'.tr(ref),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
