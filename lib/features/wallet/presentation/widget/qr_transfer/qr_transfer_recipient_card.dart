import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class QrTransferRecipientCard extends StatelessWidget {
  final bool isInternal;
  final Map<String, dynamic> payeeData;
  final String payeeName;
  final String identifier;
  final String bankName;
  final String? bankLogo;

  const QrTransferRecipientCard({
    super.key,
    required this.isInternal,
    required this.payeeData,
    required this.payeeName,
    required this.identifier,
    required this.bankName,
    this.bankLogo,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.textSecondary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          if (isInternal)
            CircleAvatar(
              radius: 24,
              backgroundImage: payeeData['avatar_url'] != null ? NetworkImage(payeeData['avatar_url']) : null,
              child: payeeData['avatar_url'] == null ? const Icon(Icons.person) : null,
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
                        imageUrl: bankLogo!,
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
                  style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  isInternal ? "ID: $identifier" : "$bankName - $identifier",
                  style: TextStyle(color: color.textSecondary, fontSize: 13),
                ),
                if (isInternal && payeeData['recipient_wallet_name'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Ví nhận: ${payeeData['recipient_wallet_name']}",
                    style: TextStyle(
                      color: color.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
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
