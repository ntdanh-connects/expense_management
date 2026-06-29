import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class TransactionHistoryEmptyState extends ConsumerWidget {
  final bool hasMore;
  final bool isLoadingMore;
  final bool showRecentOnly;
  final VoidCallback onLoadMore;

  const TransactionHistoryEmptyState({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.showRecentOnly,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    if (hasMore && !showRecentOnly) {
      if (isLoadingMore) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tìm kiếm thêm giao dịch...',
                style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
              ),
            ],
          ),
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onLoadMore();
        });
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tìm kiếm giao dịch phù hợp...',
                style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
              ),
            ],
          ),
        );
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: colors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'no_transactions'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
