import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ExportHistoryShimmer extends StatelessWidget {
  final int itemCount;
  final bool isCompact; // true: hiển thị item nhỏ (ExportScreen), false: hiển thị card lớn (ExportHistoryScreen)

  const ExportHistoryShimmer({
    super.key,
    this.itemCount = 2,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: Column(
        children: List.generate(itemCount, (index) {
          if (isCompact) {
            return _buildCompactItem();
          } else {
            return _buildHistoryCard();
          }
        }),
      ),
    );
  }

  Widget _buildCompactItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      height: 146,
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
