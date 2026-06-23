import 'dart:io';
import 'package:dio/dio.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/core/utils/currency_utils.dart';

enum TransactionStatus { processing, success, failure, offlineSuccess }

class TransactionResultScreen extends ConsumerStatefulWidget {
  final TransactionParams params;

  const TransactionResultScreen({super.key, required this.params});

  @override
  ConsumerState<TransactionResultScreen> createState() =>
      _TransactionResultScreenState();
}

class _TransactionResultScreenState
    extends ConsumerState<TransactionResultScreen> {
  TransactionStatus _status = TransactionStatus.processing;
  String? _errorMessage;
  String? _transactionId;
  String? _finalTitle;
  String? _finalCategoryName;

  @override
  void initState() {
    super.initState();
    _executeSaveTransaction();
  }

  Future<void> _executeSaveTransaction() async {
    setState(() {
      _status = TransactionStatus.processing;
      _errorMessage = null;
    });

    try {
      MultipartFile? attachmentFile;
      if (widget.params.attachmentPath != null) {
        final file = File(widget.params.attachmentPath!);
        if (await file.exists()) {
          attachmentFile = await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          );
        }
      }

      final addTxUseCase = ref.read(addTransactionUseCaseProvider);

      final result = await addTxUseCase.execute(
        walletId: widget.params.walletId,
        categoryId: widget.params.categoryId,
        type: widget.params.type,
        amount: widget.params.amount,
        title: widget.params.title,
        notes: widget.params.notes,
        transactionDate: widget.params.transactionDate,
        currencyCode: widget.params.currencyCode,
        exchangeRate: widget.params.exchangeRate,
        timezone: widget.params.timezone,
        attachment: attachmentFile,
        payeeId: widget.params.payeeId,
        sourceType: widget.params.sourceType,
      );

      // Lưu trữ mã giao dịch trả về từ API
      _transactionId = result.id;
      _finalTitle = result.title;
      _finalCategoryName = result.categoryName;

      // Làm mới dữ liệu các ví và danh sách giao dịch
      await ref.read(walletNotifierProvider.notifier).refreshWallets();
      await ref.read(transactionListProvider.notifier).refreshTransactions();

      // Làm mới danh sách thông báo để cập nhật badge và danh sách realtime
      await ref.read(notificationNotifierProvider.notifier).refresh();

      // Refresh budget providers smoothly (báo cáo sẽ tự động làm mới ngầm nhờ transactionListProvider)
      await ref.read(budgetListProvider.notifier).refreshBudgets(silent: true);
      try {
        await ref
            .read(filteredTransactionListProvider.notifier)
            .refreshTransactions(silent: true);
      } catch (_) {}
      // Force rebuild to trigger budget threshold checks
      ref
          .read(currentMonthBudgetsProvider.future)
          .catchError((_) => <BudgetDto>[]);

      // Hiển thị thông báo giao dịch thành công ngoài app
      try {
        final currencyCode = widget.params.currencyCode ?? 'VND';
        final currencySymbol = AppConstant.getCurrencySymbol(currencyCode);
        final formattedAmount = AppConstant.formatMoney(
          widget.params.amount,
          currencyCode,
        );
        final walletPart = ' ví "${widget.params.walletName}"';

        String notifTitle = 'Biến động số dư';
        String notifBody = '';

        if (widget.params.type.toLowerCase() == 'income') {
          notifBody =
              '+$formattedAmount $currencySymbol vào$walletPart. Nội dung: ${widget.params.title}';
        } else if (widget.params.type.toLowerCase() == 'expense') {
          notifBody =
              '-$formattedAmount $currencySymbol từ$walletPart. Nội dung: ${widget.params.title}';
        } else if (widget.params.type.toLowerCase() == 'transfer') {
          notifTitle = 'Chuyển tiền';
          notifBody =
              'Chuyển $formattedAmount $currencySymbol từ$walletPart. Nội dung: ${widget.params.title}';
        } else {
          notifBody =
              'Giao dịch mới: $formattedAmount $currencySymbol - ${widget.params.title}';
        }

        await LocalNotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
          title: notifTitle,
          body: notifBody,
        );

        final userId = ref.read(currentUserProvider)?.id ?? '';
        if (userId.isNotEmpty) {
          final localNotif = await LocalNotificationStorage.createAndSave(
            userId: userId,
            type: 'transaction',
            title: notifTitle,
            body: notifBody,
          );
          if (localNotif != null) {
            ref
                .read(notificationNotifierProvider.notifier)
                .addLocalNotification(localNotif);
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _status = TransactionStatus.success;
        });
      }
    } catch (e) {
      final isNetError =
          e is SocketException ||
          (e is DioException &&
              (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.sendTimeout ||
                  e.type == DioExceptionType.receiveTimeout ||
                  e.type == DioExceptionType.connectionError ||
                  e.error is SocketException ||
                  e.message?.contains('SocketException') == true));

      if (isNetError) {
        try {
          await ref
              .read(transactionListProvider.notifier)
              .addPendingTransaction(widget.params);
          if (mounted) {
            setState(() {
              _status = TransactionStatus.offlineSuccess;
            });
          }
          return;
        } catch (saveError) {
          _errorMessage = saveError.toString();
        }
      }

      if (mounted) {
        setState(() {
          _status = TransactionStatus.failure;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'VND':
      default:
        return 'đ';
    }
  }

  String _formatAmount(double amount, String currencyCode) {
    final format = currencyCode == 'VND' ? '#,###' : '#,##0.00';
    final formatted = NumberFormat(format).format(amount);
    final symbol = _getCurrencySymbol(currencyCode);

    // Thu nhập + , Chi tiêu -
    final prefix = widget.params.type == 'income' ? '+' : '-';
    return '$prefix$formatted $symbol';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final tzName = widget.params.timezone;
      try {
        final location = tz.getLocation(tzName);
        final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
        return DateFormat('dd/MM/yyyy - HH:mm').format(tzDateTime);
      } catch (_) {
        return DateFormat('dd/MM/yyyy - HH:mm').format(date.toLocal());
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'result_title'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_status) {
      case TransactionStatus.processing:
        return const TransactionResultShimmer();
      case TransactionStatus.success:
        return _buildSuccessView(context);
      case TransactionStatus.offlineSuccess:
        return _buildOfflineSuccessView(context);
      case TransactionStatus.failure:
        return _buildFailureView(context);
    }
  }

  Widget _buildSuccessView(BuildContext context) {
    final colors = context.colors;
    final localeCode = ref.watch(localeProvider);
    final isIncome = widget.params.type == 'income';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Checkmark động hình tròn kiểu Momo
                    const AnimatedCheckmark(isSuccess: true),
                    const SizedBox(height: 20),
                    Text(
                      'save_transaction_success'.tr(ref),
                      style: TextStyle(
                        color: colors.incomeGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Phiếu hóa đơn kiểu MOMO
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Phần trên cùng hiển thị số tiền rất to nổi bật
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  _formatAmount(
                                    widget.params.amount,
                                    widget.params.currencyCode,
                                  ),
                                  style: TextStyle(
                                    color: isIncome
                                        ? colors.incomeGreen
                                        : colors.expenseRed,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.params.currencyCode == 'VND' ||
                                    widget.params.currencyCode == null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '(${formatNumberToWords(widget.params.amount, localeCode)})',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  (_finalTitle != null &&
                                          _finalTitle!.isNotEmpty)
                                      ? _finalTitle!
                                      : (widget.params.title.isNotEmpty
                                            ? widget.params.title
                                            : (widget.params.categoryName ??
                                                  'uncategorized'.tr(ref))),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Đường đứt nét ngăn cách hóa đơn
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: DottedLine(
                              color: colors.textSecondary.withOpacity(0.2),
                              height: 1.5,
                            ),
                          ),
                          // Thông tin chi tiết hóa đơn bên dưới
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                _buildReceiptRow(
                                  context,
                                  'transaction_type'.tr(ref),
                                  isIncome
                                      ? 'income'.tr(ref)
                                      : 'expense'.tr(ref),
                                ),
                                _buildReceiptRow(
                                  context,
                                  'category_label'.tr(ref),
                                  _finalCategoryName ??
                                      widget.params.categoryName ??
                                      'uncategorized'.tr(ref),
                                ),
                                _buildReceiptRow(
                                  context,
                                  'payment_wallet'.tr(ref),
                                  widget.params.walletName,
                                ),
                                _buildReceiptRow(
                                  context,
                                  'transaction_time'.tr(ref),
                                  _formatDate(widget.params.transactionDate),
                                ),
                                if (_transactionId != null)
                                  _buildReceiptRow(
                                    context,
                                    'transaction_code'.tr(ref),
                                    _transactionId!,
                                  ),
                                if (widget.params.notes != null &&
                                    widget.params.notes!.isNotEmpty)
                                  _buildReceiptRow(
                                    context,
                                    'description'.tr(ref),
                                    widget.params.notes!,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Các nút hành động dưới cùng
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Quay lại màn thêm giao dịch mới
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'create_new_gd'.tr(ref),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Quay lại màn hình chính của ứng dụng
                      while (context.canPop()) {
                        context.pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'main_screen'.tr(ref),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureView(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Cảnh báo chéo đỏ
            const AnimatedCheckmark(isSuccess: false),
            const SizedBox(height: 24),
            Text(
              'transaction_failed'.tr(ref),
              style: TextStyle(
                color: colors.expenseRed,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.expenseRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.expenseRed.withOpacity(0.15)),
              ),
              child: Text(
                _errorMessage ?? 'unknown_error'.tr(ref),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.expenseRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Quay lại chỉnh sửa, dữ liệu được giữ nguyên
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colors.textSecondary.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'back_to_edit'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _executeSaveTransaction();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'retry'.tr(ref),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineSuccessView(BuildContext context) {
    final colors = context.colors;
    final localeCode = ref.watch(localeProvider);
    final isIncome = widget.params.type == 'income';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'offline_mode_title'.tr(ref),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  _formatAmount(
                                    widget.params.amount,
                                    widget.params.currencyCode,
                                  ),
                                  style: TextStyle(
                                    color: isIncome
                                        ? colors.incomeGreen
                                        : colors.expenseRed,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.params.currencyCode == 'VND' ||
                                    widget.params.currencyCode == null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '(${formatNumberToWords(widget.params.amount, localeCode)})',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  widget.params.title.isNotEmpty
                                      ? widget.params.title
                                      : (widget.params.categoryName ??
                                            'uncategorized'.tr(ref)),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: DottedLine(
                              color: colors.textSecondary.withOpacity(0.2),
                              height: 1.5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                _buildReceiptRow(
                                  context,
                                  'transaction_type'.tr(ref),
                                  isIncome
                                      ? 'income'.tr(ref)
                                      : 'expense'.tr(ref),
                                ),
                                _buildReceiptRow(
                                  context,
                                  'category_label'.tr(ref),
                                  widget.params.categoryName ??
                                      'uncategorized'.tr(ref),
                                ),
                                _buildReceiptRow(
                                  context,
                                  'payment_wallet'.tr(ref),
                                  widget.params.walletName,
                                ),
                                _buildReceiptRow(
                                  context,
                                  'transaction_time'.tr(ref),
                                  _formatDate(widget.params.transactionDate),
                                ),
                                _buildReceiptRow(
                                  context,
                                  'transaction_code'.tr(ref),
                                  'transaction_status_pending'.tr(ref),
                                  valueColor: Colors.orange,
                                  isBoldValue: true,
                                ),
                                if (widget.params.notes != null &&
                                    widget.params.notes!.isNotEmpty)
                                  _buildReceiptRow(
                                    context,
                                    'description'.tr(ref),
                                    widget.params.notes!,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'save_transaction_offline'.tr(ref),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'create_new_gd'.tr(ref),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      while (context.canPop()) {
                        context.pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'main_screen'.tr(ref),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? colors.textPrimary,
                fontSize: 14,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DottedLine extends StatelessWidget {
  final Color color;
  final double height;

  const DottedLine({super.key, required this.color, this.height = 1.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}

class AnimatedCheckmark extends StatefulWidget {
  final bool isSuccess;
  const AnimatedCheckmark({super.key, required this.isSuccess});

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: widget.isSuccess ? colors.incomeGreen : colors.expenseRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (widget.isSuccess ? colors.incomeGreen : colors.expenseRed)
                  .withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          widget.isSuccess ? Icons.check_rounded : Icons.close_rounded,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }
}

class TransactionResultShimmer extends StatelessWidget {
  const TransactionResultShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 180,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 2,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < 5; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
