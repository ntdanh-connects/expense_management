import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';

class PayeesTab extends ConsumerStatefulWidget {
  const PayeesTab({super.key});

  @override
  ConsumerState<PayeesTab> createState() => _PayeesTabState();
}

class _PayeesTabState extends ConsumerState<PayeesTab> {
  List<dynamic> _payees = [];
  bool _isLoadingPayees = false;
  final TextEditingController _searchPayeeController = TextEditingController();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchPayees();
  }

  @override
  void dispose() {
    _searchPayeeController.dispose();
    super.dispose();
  }

  Future<void> _fetchPayees({String? search}) async {
    setState(() {
      _isLoadingPayees = true;
    });

    final result = await ref.read(qrTransferProvider.notifier).fetchPayees(
      search: search,
      perPage: 30,
    );

    if (mounted) {
      setState(() {
        _payees = result?['data'] ?? [];
        _isLoadingPayees = false;
      });
    }
  }

  Future<void> _deletePayee(String id) async {
    final success = await ref.read(qrTransferProvider.notifier).removePayee(id);
    if (success && mounted) {
      ElegantNotification.success(
        title: Text('success'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Đã xóa khỏi danh bạ người nhận.'),
      ).show(context);
      _fetchPayees(search: _searchPayeeController.text);
    }
  }

  Widget _buildPayeesShimmer(AppColorsExtension color, bool isDark) {
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Card(
            color: color.surface,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(radius: 20),
              title: Container(
                width: 150,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Container(
                width: 100,
                height: 12,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchPayeeController,
            style: TextStyle(color: color.textPrimary),
            decoration: InputDecoration(
              hintText: 'search_payee_hint'.tr(ref),
              hintStyle: TextStyle(color: color.textSecondary.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search_rounded, color: color.textSecondary),
              filled: true,
              fillColor: color.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (val) => _fetchPayees(search: val),
          ),
        ),
        Expanded(
          child: _isLoadingPayees
              ? _buildPayeesShimmer(color, isDark)
              : _payees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contact_phone_outlined, size: 60, color: color.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'no_payee_found'.tr(ref),
                            style: TextStyle(color: color.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _payees.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final payee = _payees[index];
                        final isInternal = payee['payee_type'] == 'internal';

                        return Card(
                          color: color.surface,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: isInternal
                                ? CircleAvatar(
                                    backgroundImage: payee['avatar_url'] != null ? NetworkImage(payee['avatar_url']) : null,
                                    child: payee['avatar_url'] == null ? const Icon(Icons.person) : null,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.account_balance_rounded, color: Colors.blue),
                                  ),
                            title: Text(
                              () {
                                final name = payee['payee_name']?.toString().trim() ?? '';
                                return (name.isEmpty || name.toUpperCase() == 'UNKNOWN RECIPIENT')
                                    ? 'Không xác định'
                                    : name;
                              }(),
                              style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isInternal ? payee['identifier'] : "${payee['bank_name']} - ${payee['identifier']}",
                              style: TextStyle(color: color.textSecondary, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  onPressed: _isNavigating ? null : () => _deletePayee(payee['id']),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              ],
                            ),
                            onTap: _isNavigating
                                ? null
                                : () async {
                                    setState(() {
                                      _isNavigating = true;
                                    });
                                    final mappedPayee = {
                                      'payee_id': payee['id'],
                                      'type': payee['payee_type'],
                                      'payee_user_id': payee['payee_user_id'],
                                      'identifier': payee['identifier'],
                                      'payee_name': payee['payee_name'],
                                      'bank_code': payee['bank_code'],
                                      'bank_name': payee['bank_name'],
                                      'account_number': payee['identifier'],
                                      'amount': null,
                                      'description': null,
                                      'recipient_wallet_name': payee['recipient_wallet_name'] ?? payee['wallet_name'] ?? payee['recipient_wallet'],
                                      'is_qr': false,
                                    };
                                    await context.push('/add-transaction', extra: mappedPayee);
                                    if (mounted) {
                                      setState(() {
                                        _isNavigating = false;
                                      });
                                    }
                                  },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
