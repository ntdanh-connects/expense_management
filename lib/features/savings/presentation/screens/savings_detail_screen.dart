import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/utils/currency_utils.dart';
import 'package:expense_management/features/savings/domain/entities/savings_goal.dart';
import 'package:expense_management/features/savings/presentation/provider/savings_notifier.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class SavingsDetailScreen extends ConsumerWidget {
  final String goalId;
  const SavingsDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final detailState = ref.watch(savingsDetailProvider(goalId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'savings_detail_title'.tr(ref),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () {
            ref.invalidate(savingsListProvider);
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colors.expenseRed),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detailState.when(
        data: (goal) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCard(context, goal, colors, ref),
                const SizedBox(height: 20),
                // 2. ACTION BUTTONS (DEPOSIT / WITHDRAW)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openTransactionDialog(context, ref, goal, 'deposit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.incomeGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('savings_deposit_btn'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openTransactionDialog(context, ref, goal, 'withdraw'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.remove_circle_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('savings_withdraw_btn'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 4. TRANSACTION HISTORY
                Text(
                  'savings_history_title'.tr(ref),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTransactionHistoryList(context, goal, colors, ref),
              ],
            ),
          ),
        ),
        loading: () => const _SavingsDetailShimmer(),
        error: (err, _) => Center(
          child: Text(
            'savings_detail_error'.tr(ref).replaceAll('{error}', err.toString()),
            style: TextStyle(color: colors.expenseRed),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, SavingsGoalEntity goal, AppColorsExtension colors, WidgetRef ref) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final targetStr = currencyFormat.format(goal.targetAmount);
    final currentStr = currencyFormat.format(goal.currentAmount);
    final isCompleted = goal.status == 'completed' || goal.currentAmount >= goal.targetAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          // Circular progress graphic
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: goal.progressPercent / 100,
                  strokeWidth: 12,
                  backgroundColor: colors.primary.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? colors.incomeGreen : colors.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${goal.progressPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isCompleted ? colors.incomeGreen : colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? 'savings_status_completed'.tr(ref) : 'savings_status_saving'.tr(ref),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            goal.name,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildDetailRow('savings_accumulated'.tr(ref), '$currentStr đ', colors, valueColor: colors.primary),
          const SizedBox(height: 12),
          _buildDetailRow('savings_target_amount_label'.tr(ref), '$targetStr đ', colors),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow('savings_target_date_label'.tr(ref), DateFormat('dd/MM/yyyy').format(goal.targetDate!), colors),
          ],
          if (goal.sourceWalletName != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow('savings_linked_wallet_label'.tr(ref), goal.sourceWalletName!, colors),
          ],
          if (goal.autoSaveFrequency != null && goal.autoSaveAmount != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'savings_auto_save_title'.tr(ref),
              '${currencyFormat.format(goal.autoSaveAmount)}đ (${goal.autoSaveFrequency == 'daily' ? 'savings_freq_daily'.tr(ref) : goal.autoSaveFrequency == 'weekly' ? 'savings_freq_weekly'.tr(ref) : 'savings_freq_monthly'.tr(ref)})',
              colors,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, AppColorsExtension colors, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistoryList(BuildContext context, SavingsGoalEntity goal, AppColorsExtension colors, WidgetRef ref) {
    final list = goal.transactions ?? [];
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'savings_no_transactions'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final localeCode = ref.watch(localeProvider);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        final isDeposit = tx.type == 'deposit';
        final amountSign = isDeposit ? '+' : '-';
        final displayColor = isDeposit ? colors.incomeGreen : colors.expenseRed;
        final amountText = '$amountSign${currencyFormat.format(tx.amount)} đ';
        final dateText = _formatDateTime(tx.transactionDate, ref);
        
        // Chữ tiền bằng chữ theo ngôn ngữ hiện tại
        final amountWords = formatNumberToWords(tx.amount, localeCode);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: displayColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: displayColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.notes ?? (isDeposit ? 'savings_default_deposit_note'.tr(ref) : 'savings_default_withdraw_note'.tr(ref)),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      color: displayColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Text tiền bằng chữ ngay dưới số tiền của lịch sử giao dịch
                  Text(
                    '($amountWords)',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('savings_delete_dialog_title'.tr(ref)),
        content: Text(
          'savings_delete_dialog_desc'.tr(ref),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr(ref), style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                await ref.read(savingsListProvider.notifier).deleteGoal(goalId);

                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  context.pop(); // Back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('savings_delete_success'.tr(ref))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('savings_delete_error'.tr(ref).replaceAll('{error}', e.toString()))),
                  );
                }
              }
            },
            child: Text('delete'.tr(ref), style: TextStyle(color: colors.expenseRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openTransactionDialog(
    BuildContext screenContext,
    WidgetRef ref,
    SavingsGoalEntity goal,
    String type, // deposit or withdraw
  ) {
    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TransactionDialogContent(
          goal: goal,
          type: type,
          screenContext: screenContext,
        );
      },
    );
  }

  String _formatDateTime(DateTime date, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    try {
      final location = tz.getLocation(tzName);
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      final offset = tzDateTime.timeZoneOffset;
      final offsetStr = offset.inMinutes == 0
          ? 'UTC'
          : 'UTC${offset.isNegative ? '-' : '+'}${offset.inHours.abs()}';
      return '${DateFormat('dd/MM/yyyy HH:mm').format(tzDateTime)} ($offsetStr)';
    } catch (_) {
      return '${DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal())} (UTC+7)';
    }
  }
}

class _SavingsDetailShimmer extends StatelessWidget {
  const _SavingsDetailShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card Placeholder
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 20),
            // Actions Row Placeholder
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // History Title Placeholder
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // History List Placeholders
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _TransactionDialogContent extends ConsumerStatefulWidget {
  final SavingsGoalEntity goal;
  final String type;
  final BuildContext screenContext;

  const _TransactionDialogContent({
    required this.goal,
    required this.type,
    required this.screenContext,
  });

  @override
  ConsumerState<_TransactionDialogContent> createState() => _TransactionDialogContentState();
}

class _TransactionDialogContentState extends ConsumerState<_TransactionDialogContent> {
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
                  color: colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.type == 'deposit' ? 'savings_deposit_title'.tr(ref) : 'savings_withdraw_title'.tr(ref),
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
                  return 'savings_withdraw_exceed_error'.tr(ref).replaceAll('{amount}', NumberFormat('#,###').format(widget.goal.currentAmount));
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            // Text hiển thị số tiền bằng chữ ngay dưới ô nhập tiền
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
                    labelText: widget.type == 'deposit' ? 'savings_source_wallet_label'.tr(ref) : 'savings_dest_wallet_label'.tr(ref),
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
                      child: Text('${wallet.name} (${NumberFormat('#,###', 'vi_VN').format(wallet.balance)} đ)'),
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
              loading: () {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
                final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
                return Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              error: (err, _) => Text('savings_wallet_load_error'.tr(ref).replaceAll('{error}', err.toString())),
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
                            Navigator.pop(context); // Close bottom sheet
                            ScaffoldMessenger.of(widget.screenContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.type == 'deposit' 
                                      ? 'savings_deposit_success'.tr(ref) 
                                      : 'savings_withdraw_success'.tr(ref),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: colors.incomeGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isDialogLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'savings_detail_error'.tr(ref).replaceAll('{error}', e.toString()),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: colors.expenseRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.type == 'deposit' ? 'savings_confirm_deposit'.tr(ref) : 'savings_confirm_withdraw'.tr(ref),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
