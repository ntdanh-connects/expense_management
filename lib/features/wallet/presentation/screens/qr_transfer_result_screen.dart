import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class QrTransferResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> resultData;

  const QrTransferResultScreen({super.key, required this.resultData});

  @override
  ConsumerState<QrTransferResultScreen> createState() => _QrTransferResultScreenState();
}

class _QrTransferResultScreenState extends ConsumerState<QrTransferResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,###').format(amount) + ' đ';
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    
    // Parse result payload
    final result = widget.resultData['result'] as Map<String, dynamic>? ?? {};
    final status = result['status'] ?? 'success';
    final isSuccess = status == 'success';
    
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final amount = double.tryParse(data['amount']?.toString() ?? '') ?? 0.0;
    
    // Recipient Name
    final rawRecipientName = (data['payee_name'] ?? data['recipient_name'] ?? '').toString().trim();
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
                      
                      // Animated checkmark or error mark
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: isSuccess ? color.incomeGreen : color.expenseRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isSuccess ? color.incomeGreen : color.expenseRed).withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSuccess ? Icons.check_rounded : Icons.close_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        isSuccess ? 'qr_transfer_success_title'.tr(ref) : 'qr_transfer_failed_title'.tr(ref),
                        style: TextStyle(
                          color: isSuccess ? color.incomeGreen : color.expenseRed,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSuccess 
                            ? 'qr_transfer_success_desc'.tr(ref) 
                            : (result['message'] ?? 'qr_transfer_failed_default_desc'.tr(ref)),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color.textSecondary,
                          fontSize: 14,
                        ),
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
                                  Text(
                                    isSuccess ? '- ${_formatAmount(amount)}' : '0 đ',
                                    style: TextStyle(
                                      color: isSuccess ? color.expenseRed : color.textPrimary,
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
                                  if (isSuccess && transactionId.isNotEmpty)
                                    _buildReceiptRow(color, 'qr_transfer_transaction_id'.tr(ref), transactionId, valueColor: color.primary),
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
                      onPressed: () {
                        // Pop back to scanner (clearing confirm and going back to scan)
                        context.pop(); // Pop Result
                        context.pop(); // Pop Confirm
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'qr_transfer_scan_other'.tr(ref),
                        style: TextStyle(
                          color: color.primary,
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
                        // Pop confirm screen, go router to dashboard root
                        context.go('/dashboard');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'qr_transfer_go_home'.tr(ref),
                        style: TextStyle(
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
