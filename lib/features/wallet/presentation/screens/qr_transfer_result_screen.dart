import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_storage.dart';
import 'package:expense_management/features/notification/presentation/providers/notification_provider.dart';

class QrTransferResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> resultData;

  const QrTransferResultScreen({super.key, required this.resultData});

  @override
  ConsumerState<QrTransferResultScreen> createState() => _QrTransferResultScreenState();
}

class _QrTransferResultScreenState extends ConsumerState<QrTransferResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isExecuting = true;
  bool _isSuccess = false;
  Map<String, dynamic>? _apiResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    final isPending = widget.resultData['is_pending_execution'] == true;
    if (isPending) {
      _isExecuting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTransfer();
      });
    } else {
      _isExecuting = false;
      final result = widget.resultData['result'] as Map<String, dynamic>? ?? {};
      _isSuccess = result['status'] == 'success';
      _apiResult = result;
      _animationController.forward();
    }
  }

  Future<void> _startTransfer() async {
    try {
      final notifier = ref.read(qrTransferProvider.notifier);
      final result = await notifier.executeTransfer(
        fromWalletId: widget.resultData['from_wallet_id'] as String,
        payeeType: widget.resultData['payee_type'] as String,
        amount: widget.resultData['amount'] as double,
        notes: widget.resultData['notes'] as String?,
        payeeUserId: widget.resultData['payee_user_id'] as String?,
        bankCode: widget.resultData['bank_code'] as String?,
        accountNumber: widget.resultData['account_number'] as String?,
        payeeName: widget.resultData['payee_name'] as String?,
        toWalletId: widget.resultData['to_wallet_id'] as String?,
        categoryId: widget.resultData['category_id'] as String?,
      );

      if (mounted) {
        if (result != null && result['status'] == 'success') {
          setState(() {
            _isExecuting = false;
            _isSuccess = true;
            _apiResult = result;
          });
          _animationController.forward();

          // Run background sync tasks
          _runBackgroundSyncTasks(result);
        } else {
          final errMsg = (result != null && result['message'] != null)
              ? result['message'].toString()
              : 'transfer_failed_msg'.trRead(ref);
          setState(() {
            _isExecuting = false;
            _isSuccess = false;
            _apiResult = result;
            _errorMessage = errMsg;
          });
          _animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _isSuccess = false;
          _errorMessage = e.toString();
        });
        _animationController.forward();
      }
    }
  }

  Future<void> _runBackgroundSyncTasks(Map<String, dynamic> result) async {
    try {
      final amount = widget.resultData['amount'] as double;
      final bankName = widget.resultData['bank_name'] ?? '';
      final identifier = widget.resultData['identifier'] ?? '';
      final isInternal = widget.resultData['payee_type'] == 'internal';
      final payeeName = widget.resultData['payee_name'] ?? '';
      final fromWalletId = widget.resultData['from_wallet_id'] as String;

      AppLogger.info("🔄 [QR-Result-BG] Syncing wallets in background...");
      ref.read(walletNotifierProvider.notifier).refreshWallets();
      
      AppLogger.info("🔄 [QR-Result-BG] Refreshing transaction history in background...");
      ref.read(transactionListProvider.notifier).refreshTransactions(silent: true);

      // Trigger system and local notifications
      try {
        final wallets = ref.read(walletNotifierProvider).value ?? [];
        final selectedWallet = wallets.firstWhere((w) => w.id == fromWalletId, orElse: () => wallets.first);
        final currencySymbol = AppConstant.getCurrencySymbol(selectedWallet.currencyCode);
        final formattedAmount = AppConstant.formatMoney(amount, selectedWallet.currencyCode);
        final walletPart = ' ví "${selectedWallet.name}"';
        final destination = isInternal ? payeeName : '$bankName - $identifier ($payeeName)';
        final title = 'Chuyển tiền';
        final body = 'Đã chuyển $formattedAmount $currencySymbol từ$walletPart đến "$destination".';

        await LocalNotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
          title: title,
          body: body,
        );

        final userId = ref.read(currentUserProvider)?.id ?? '';
        if (userId.isNotEmpty) {
          final localNotif = await LocalNotificationStorage.createAndSave(
            userId: userId,
            type: 'transaction',
            title: title,
            body: body,
          );
          if (localNotif != null) {
            ref.read(notificationNotifierProvider.notifier).addLocalNotification(localNotif);
          }
        }
      } catch (e) {
        AppLogger.error("🚨 [QR-Result-BG] Notification error: $e");
      }
    } catch (e) {
      AppLogger.error("🚨 [QR-Result-BG] Background sync task error: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return '${NumberFormat('#,###').format(amount)} đ';
  }

  Widget _buildShimmerBlock({required double width, required double height, double borderRadius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildReceiptShimmerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildShimmerBlock(width: 80, height: 14),
          _buildShimmerBlock(width: 120, height: 14),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Parse result payload
    final result = _apiResult ?? {};
    final data = result['data'] as Map<String, dynamic>? ?? {};
    
    final double rawAmount = double.tryParse(data['amount']?.toString() ?? '') ?? 
        (double.tryParse(widget.resultData['amount']?.toString() ?? '') ?? 0.0);
    
    // Recipient Name
    final rawRecipientName = (data['payee_name'] ?? data['recipient_name'] ?? widget.resultData['payee_name'] ?? '').toString().trim();
    final recipientName = (rawRecipientName.isEmpty || rawRecipientName.toUpperCase() == 'UNKNOWN RECIPIENT')
        ? 'qr_transfer_unknown'.tr(ref)
        : rawRecipientName;

    final senderWallet = widget.resultData['sender_wallet'] ?? 'Ví mặc định';
    final notes = widget.resultData['notes'] ?? 'Chuyển khoản QR';
    final bankName = widget.resultData['bank_name'] ?? '';
    final identifier = widget.resultData['identifier'] ?? data['account_number'] ?? '';
    final type = widget.resultData['type'] ?? 'internal';
    final isInternal = type == 'internal';
    
    final transactionId = data['transfer_id'] ?? data['expense_id'] ?? '';
    final formattedTime = DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: color.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      
                      // Animated checkmark, error mark or shimmer circle
                      _isExecuting
                          ? Shimmer.fromColors(
                              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: _isSuccess ? color.incomeGreen : color.expenseRed,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isSuccess ? color.incomeGreen : color.expenseRed).withOpacity(0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isSuccess ? Icons.check_rounded : Icons.close_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                      const SizedBox(height: 24),
                      
                      // Title and description or shimmer
                      _isExecuting
                          ? Shimmer.fromColors(
                              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                              child: Column(
                                children: [
                                  _buildShimmerBlock(width: 180, height: 24),
                                  const SizedBox(height: 10),
                                  _buildShimmerBlock(width: 240, height: 16),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Text(
                                  _isSuccess ? 'qr_transfer_success_title'.tr(ref) : 'qr_transfer_failed_title'.tr(ref),
                                  style: TextStyle(
                                    color: _isSuccess ? color.incomeGreen : color.expenseRed,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSuccess 
                                      ? 'qr_transfer_success_desc'.tr(ref) 
                                      : (_errorMessage ?? (result['message'] ?? 'qr_transfer_failed_default_desc'.tr(ref))),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: color.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 32),
                      
                      // Receipt Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: color.textSecondary.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header amount section
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  _isExecuting
                                      ? Shimmer.fromColors(
                                          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                                          child: Column(
                                            children: [
                                              _buildShimmerBlock(width: 160, height: 32),
                                              const SizedBox(height: 8),
                                              _buildShimmerBlock(width: 100, height: 14),
                                            ],
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            Text(
                                              _isSuccess ? '- ${_formatAmount(rawAmount)}' : '0 đ',
                                              style: TextStyle(
                                                color: _isSuccess ? color.expenseRed : color.textPrimary,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              isInternal ? 'qr_transfer_p2p_internal'.tr(ref) : 'qr_transfer_vietqr'.tr(ref),
                                              style: TextStyle(
                                                color: color.textSecondary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                            
                            // Dotted separator line
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: CustomPaint(
                                size: const Size(double.infinity, 1),
                                painter: DottedLinePainter(color: color.textSecondary.withOpacity(0.2)),
                              ),
                            ),
                            
                            // Body receipt fields
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  _isExecuting
                                      ? Shimmer.fromColors(
                                          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                                          child: Column(
                                            children: [
                                              _buildReceiptShimmerRow(),
                                              _buildReceiptShimmerRow(),
                                              _buildReceiptShimmerRow(),
                                              _buildReceiptShimmerRow(),
                                              _buildReceiptShimmerRow(),
                                            ],
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            _buildReceiptRow(color, 'qr_transfer_sender'.tr(ref), senderWallet),
                                            _buildReceiptRow(color, 'qr_transfer_recipient'.tr(ref), recipientName, isBoldValue: true),
                                            if (!isInternal && bankName.isNotEmpty)
                                              _buildReceiptRow(color, 'qr_transfer_recipient_bank'.tr(ref), bankName),
                                            _buildReceiptRow(
                                              color, 
                                              isInternal ? 'qr_transfer_identifier'.tr(ref) : 'qr_transfer_account_number'.tr(ref), 
                                              identifier
                                            ),
                                            _buildReceiptRow(color, 'qr_transfer_notes'.tr(ref), notes),
                                            _buildReceiptRow(color, 'qr_transfer_time'.tr(ref), formattedTime),
                                            if (_isSuccess && transactionId.isNotEmpty)
                                              _buildReceiptRow(color, 'qr_transfer_transaction_id'.tr(ref), transactionId, valueColor: color.primary),
                                          ],
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
              const SizedBox(height: 24),
              
              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isExecuting
                          ? null
                          : () {
                              // Pop back to scanner (clearing confirm and going back to scan)
                              context.pop(); // Pop Result
                              context.pop(); // Pop Confirm
                            },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _isExecuting ? Colors.grey.shade300 : color.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'qr_transfer_scan_other'.tr(ref),
                        style: TextStyle(
                          color: _isExecuting ? Colors.grey.shade400 : color.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isExecuting
                          ? null
                          : () {
                              // Pop confirm screen, go router to dashboard root
                              context.go('/dashboard');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isExecuting ? Colors.grey.shade300 : color.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'qr_transfer_go_home'.tr(ref),
                        style: TextStyle(
                          color: _isExecuting ? Colors.grey.shade500 : Colors.white,
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
      ),
    );
  }

  Widget _buildReceiptRow(
    AppColorsExtension color,
    String label,
    String value, {
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? color.textPrimary,
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

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
