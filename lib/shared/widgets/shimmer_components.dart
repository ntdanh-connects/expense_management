import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class BoxShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const BoxShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CardShimmer extends StatelessWidget {
  final double height;
  const CardShimmer({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return BoxShimmer(height: height, borderRadius: 24);
  }
}

class ListShimmer extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  const ListShimmer({super.key, this.itemCount = 3, this.itemHeight = 70});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: BoxShimmer(height: itemHeight, borderRadius: 16),
        ),
      ),
    );
  }
}
