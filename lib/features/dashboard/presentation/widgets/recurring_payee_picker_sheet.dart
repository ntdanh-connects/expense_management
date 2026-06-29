import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/features/dashboard/presentation/widgets/recurring_qr_scanner_page.dart';

class RecurringPayeePickerSheet extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic>? payee) onSelected;
  final String? selectedPayeeId;

  const RecurringPayeePickerSheet({
    super.key,
    required this.onSelected,
    this.selectedPayeeId,
  });

  @override
  ConsumerState<RecurringPayeePickerSheet> createState() =>
      _RecurringPayeePickerSheetState();
}

class _RecurringPayeePickerSheetState
    extends ConsumerState<RecurringPayeePickerSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _payees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPayees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayees({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(qrTransferProvider.notifier).fetchPayees(
            search: search,
            perPage: 100,
          );
      if (res != null && res['data'] is List) {
        setState(() {
          _payees = List<Map<String, dynamic>>.from(res['data']);
        });
      }
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                Text(
                  'recurring_select_payee'.tr(ref),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner_rounded, color: colors.primary),
                  onPressed: () async {
                    final qrString = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RecurringQrScannerPage()),
                    );
                    if (qrString != null) {
                      setState(() => _isLoading = true);
                      try {
                        final res = await ref
                            .read(qrTransferProvider.notifier)
                            .decodeQrCode(qrString);
                        if (res != null) {
                          final payeeMap = {
                            'id': res['payee_id'],
                            'payee_name': res['payee_name'],
                            'identifier': res['account_number'] ?? res['identifier'],
                            'bank_name': res['bank_name'],
                            'payee_type': res['type'],
                          };
                          widget.onSelected(payeeMap);
                          if (mounted) Navigator.pop(context); // Close sheet
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Mã QR không hợp lệ hoặc không thể giải mã!')),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
                const Spacer(),
                if (widget.selectedPayeeId != null)
                  TextButton(
                    onPressed: () {
                      widget.onSelected(null);
                      Navigator.pop(context);
                    },
                    child: Text('cancel'.tr(ref),
                        style: TextStyle(color: colors.expenseRed)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'recurring_search_payee'.tr(ref),
                        hintStyle: TextStyle(
                            color: colors.textSecondary.withOpacity(0.5)),
                      ),
                      onChanged: (val) {
                        _loadPayees(search: val.trim());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payees.isEmpty
                    ? Center(
                        child: Text(
                          'recurring_no_payee'.tr(ref),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _payees.length,
                        itemBuilder: (context, index) {
                          final payee = _payees[index];
                          final isSelected = widget.selectedPayeeId == payee['id'];
                          final payeeName = payee['payee_name'] ?? '';
                          final payeeType = payee['payee_type'] ?? '';
                          final identifier = payee['identifier'] ?? '';
                          final bankName = payee['bank_name'] ?? '';

                          IconData iconData = Icons.account_balance_rounded;
                          if (payeeType == 'e-wallet' || payeeType == 'e_wallet') {
                            iconData = Icons.qr_code_scanner_rounded;
                          } else if (payeeType == 'p2p') {
                            iconData = Icons.person_rounded;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: colors.primary.withOpacity(0.1),
                              child: Icon(iconData, color: colors.primary, size: 20),
                            ),
                            title: Text(
                              payeeName,
                              style: TextStyle(
                                color: isSelected ? colors.primary : colors.textPrimary,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              payeeType == 'bank'
                                  ? '$bankName - $identifier'
                                  : identifier,
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded,
                                    color: colors.primary)
                                : null,
                            onTap: () {
                              widget.onSelected(payee);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
