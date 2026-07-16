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
import 'package:expense_management/features/transaction/presentation/widgets/transaction_result/transaction_result_shimmer.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_result/transaction_result_success_view.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_result/transaction_result_offline_success_view.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_result/transaction_result_failure_view.dart';

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
        splits: widget.params.splits,
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
          widget.params.amount ?? 0.0,
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
        return TransactionResultSuccessView(
          params: widget.params,
          transactionId: _transactionId,
          finalTitle: _finalTitle,
          finalCategoryName: _finalCategoryName,
          formattedAmount: _formatAmount(
            widget.params.amount ?? 0.0,
            widget.params.currencyCode,
          ),
          formattedDate: _formatDate(widget.params.transactionDate),
          onCreateNewTransaction: () => context.pop(),
          onMainScreen: () {
            while (context.canPop()) {
              context.pop();
            }
          },
        );
      case TransactionStatus.offlineSuccess:
        return TransactionResultOfflineSuccessView(
          params: widget.params,
          formattedAmount: _formatAmount(
            widget.params.amount ?? 0.0,
            widget.params.currencyCode,
          ),
          formattedDate: _formatDate(widget.params.transactionDate),
          onCreateNewTransaction: () => context.pop(),
          onMainScreen: () {
            while (context.canPop()) {
              context.pop();
            }
          },
        );
      case TransactionStatus.failure:
        return TransactionResultFailureView(
          errorMessage: _errorMessage,
          onBackToEdit: () => context.pop(),
          onRetry: _executeSaveTransaction,
        );
    }
  }
}
