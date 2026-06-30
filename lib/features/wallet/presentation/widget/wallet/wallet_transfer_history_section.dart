import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/entities/internal_transfer_record.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/internal_transfer_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'transfer_history_shimmer.dart';

class WalletTransferHistorySection extends ConsumerStatefulWidget {
  const WalletTransferHistorySection({super.key});

  @override
  ConsumerState<WalletTransferHistorySection> createState() =>
      _WalletTransferHistorySectionState();
}

class _WalletTransferHistorySectionState
    extends ConsumerState<WalletTransferHistorySection> {
  String? _filterWalletName;
  DateTimeRange? _filterDateRange;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final walletState = ref.watch(walletNotifierProvider);
    final transferState = ref.watch(internalTransferHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🧾 TIÊU ĐỀ LỊCH SỬ CHUYỂN KHOẢN NỘI BỘ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'internal_transfer_history'.tr(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'details'.tr(ref),
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Bộ lọc ví và ngày
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Wallet filter chip
              _buildFilterChip(
                context: context,
                label: _filterWalletName ?? 'Tất cả ví',
                icon: Icons.account_balance_wallet_rounded,
                isActive: _filterWalletName != null,
                onTap: () {
                  walletState.whenData((wallets) {
                    _showFilterWalletSelector(context, wallets);
                  });
                },
                onClear: _filterWalletName != null
                    ? () {
                        setState(() {
                          _filterWalletName = null;
                        });
                      }
                    : null,
                colors: colors,
              ),
              const SizedBox(width: 8),
              // Date filter chip
              _buildFilterChip(
                context: context,
                label: _filterDateRange == null
                    ? 'Tất cả ngày'
                    : '${DateFormat('dd/MM').format(_filterDateRange!.start)} - ${DateFormat('dd/MM').format(_filterDateRange!.end)}',
                icon: Icons.calendar_today_rounded,
                isActive: _filterDateRange != null,
                onTap: () async {
                  final pickedRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365),
                    ),
                    initialDateRange: _filterDateRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: colors.primary,
                            primary: colors.primary,
                            onPrimary: Colors.white,
                            surface: colors.surface,
                            onSurface: colors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedRange != null) {
                    setState(() {
                      _filterDateRange = pickedRange;
                    });
                  }
                },
                onClear: _filterDateRange != null
                    ? () {
                        setState(() {
                          _filterDateRange = null;
                        });
                      }
                    : null,
                colors: colors,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List lịch sử giao dịch
        transferState.when(
          data: (transfersList) {
            var filteredList = transfersList;
            if (_filterWalletName != null) {
              filteredList = filteredList
                  .where(
                    (tx) =>
                        tx.fromWalletName == _filterWalletName ||
                        tx.toWalletName == _filterWalletName,
                  )
                  .toList();
            }
            if (_filterDateRange != null) {
              final start = DateTime(
                _filterDateRange!.start.year,
                _filterDateRange!.start.month,
                _filterDateRange!.start.day,
              );
              final end = DateTime(
                _filterDateRange!.end.year,
                _filterDateRange!.end.month,
                _filterDateRange!.end.day,
                23,
                59,
                59,
              );
              filteredList = filteredList
                  .where(
                    (tx) =>
                        tx.date.isAfter(
                          start.subtract(const Duration(seconds: 1)),
                        ) &&
                        tx.date.isBefore(
                          end.add(const Duration(seconds: 1)),
                        ),
                  )
                  .toList();
            }

            if (filteredList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'no_transfer_history'.tr(ref),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final tx = filteredList[index];
                return _buildTransferHistoryItem(
                  tx,
                  colors,
                  AppConstant.getCurrencySymbol(
                    tx.currencyCode ?? 'VND',
                  ),
                );
              },
            );
          },
          loading: () => const TransferHistoryShimmer(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'load_transfer_history_error'.tr(ref),
                style: TextStyle(color: colors.expenseRed),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
    required AppColorsExtension colors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isActive
        ? colors.primary.withOpacity(0.12)
        : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6));
    final textColor = isActive ? colors.primary : colors.textPrimary;
    final iconColor = isActive ? colors.primary : colors.textSecondary;
    final borderColor = isActive
        ? colors.primary.withOpacity(0.3)
        : colors.textSecondary.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded, size: 14, color: iconColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterWalletSelector(
    BuildContext context,
    List<WalletEntity> wallets,
  ) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.5,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lọc theo ví',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.all_inclusive_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Tất cả ví',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: _filterWalletName == null
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: colors.primary,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _filterWalletName = null;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                    const Divider(height: 1),
                    ...wallets.map((wallet) {
                      final isSelected = _filterWalletName == wallet.name;
                      final walletColor = Color(
                        int.parse(
                          wallet.color.replaceAll('#', 'FF'),
                          radix: 16,
                        ),
                      );
                      return ListTile(
                        leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: walletColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: walletColor,
                          size: 18,
                        ),
                      ),
                        title: Text(wallet.name),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: colors.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _filterWalletName = wallet.name;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransferHistoryItem(
    InternalTransferRecord tx,
    AppColorsExtension colors,
    String currencySymbol,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tx.fromWalletName} ➔ ${tx.toWalletName}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(tx.date, timezoneOverride: tx.timezone),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '-${_formatMoney(tx.amount, tx.currencyCode)}$currencySymbol',
            style: TextStyle(
              color: colors.expenseRed,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value, [String? currencyCode]) {
    final String code = (currencyCode ?? 'VND').toUpperCase();
    final int decimals = (code == 'VND' || code == 'JPY') ? 0 : 2;

    if (decimals == 0) {
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String mathFunc(Match match) => '${match[1]}.';
      return value.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
    } else {
      final parts = value.toStringAsFixed(2).split('.');
      final String wholePart = parts[0];
      final String decimalPart = parts[1];

      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String mathFunc(Match match) => '${match[1]},';
      final String formattedWhole = wholePart.replaceAllMapped(reg, mathFunc);
      return '$formattedWhole.$decimalPart';
    }
  }

  String _formatDate(DateTime date, {String? timezoneOverride}) {
    final user = ref.read(currentUserProvider);
    final timezoneName =
        timezoneOverride ?? user?.timezone ?? 'Asia/Ho_Chi_Minh';

    DateTime userDate;
    String formattedOffset = 'UTC';
    try {
      final location = tz.getLocation(timezoneName);
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      userDate = tzDateTime;

      final offsetMs = tzDateTime.timeZoneOffset.inMilliseconds;
      final offsetHours = (offsetMs / 3600000).truncate();
      final offsetMinutes = ((offsetMs.abs() % 3600000) / 60000).truncate();
      final sign = offsetHours >= 0 ? '+' : '-';
      final hoursStr = offsetHours.abs().toString().padLeft(2, '0');
      final minutesStr = offsetMinutes.toString().padLeft(2, '0');
      formattedOffset = 'UTC$sign$hoursStr:$minutesStr';
    } catch (_) {
      userDate = date.toUtc();
    }

    final hour = userDate.hour.toString().padLeft(2, '0');
    final minute = userDate.minute.toString().padLeft(2, '0');
    final second = userDate.second.toString().padLeft(2, '0');
    final day = userDate.day.toString().padLeft(2, '0');
    final month = userDate.month.toString().padLeft(2, '0');
    final year = userDate.year;

    return '$hour:$minute:$second $day/$month/$year ($formattedOffset)';
  }
}
