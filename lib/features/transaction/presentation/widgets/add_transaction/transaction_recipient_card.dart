import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class TransactionRecipientCard extends StatelessWidget {
  final Map<String, dynamic>? qrData;
  final String? recipientWalletName;
  final bool isLoadingRecipientWallet;

  const TransactionRecipientCard({
    super.key,
    required this.qrData,
    required this.recipientWalletName,
    required this.isLoadingRecipientWallet,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isTransfer = qrData != null &&
        (qrData!['type'] == 'internal' ||
         qrData!['type'] == 'external' ||
         qrData!['payee_type'] == 'internal' ||
         qrData!['payee_type'] == 'external');

    if (!isTransfer) {
      return const SizedBox.shrink();
    }

    final qr = qrData!;
    final isInternal = qr['type'] == 'internal' || qr['payee_type'] == 'internal';
    final activeRecipientWalletName = recipientWalletName ??
        qr['recipient_wallet_name'] ??
        qr['wallet_name'] ??
        qr['recipient_wallet'];
    final rawPayeeName = qr['payee_name']?.toString().trim() ?? '';
    final payeeName =
        (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
            ? 'Không xác định'
            : rawPayeeName;
    final identifier = qr['identifier'] ?? qr['account_number'] ?? '';
    final bankName = qr['bank_name'] ?? '';
    final bankLogo = qr['bank_logo'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.authCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          if (isInternal)
            CircleAvatar(
              radius: 24,
              backgroundImage:
                  qr['avatar_url'] != null ? NetworkImage(qr['avatar_url']) : null,
              child: qr['avatar_url'] == null ? const Icon(Icons.person) : null,
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: bankLogo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: bankLogo,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.blue,
                        ),
                      ),
                    )
                  : const Icon(Icons.account_balance_rounded, color: Colors.blue),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payeeName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isInternal ? "ID: $identifier" : "$bankName - $identifier",
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                if (isInternal) ...[
                  const SizedBox(height: 6),
                  if (isLoadingRecipientWallet)
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Shimmer.fromColors(
                          baseColor: colors.textSecondary.withOpacity(0.1),
                          highlightColor: colors.textSecondary.withOpacity(0.05),
                          child: Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (activeRecipientWalletName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Ví nhận: $activeRecipientWalletName",
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
