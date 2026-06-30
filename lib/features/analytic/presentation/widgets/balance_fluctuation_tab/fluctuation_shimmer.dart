import 'package:flutter/material.dart';
import 'package:expense_management/shared/widgets/shimmer_components.dart';

class FluctuationShimmer extends StatelessWidget {
  const FluctuationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        BoxShimmer(height: 80),
        SizedBox(height: 16),
        BoxShimmer(height: 180),
        SizedBox(height: 16),
        ListShimmer(itemCount: 3, itemHeight: 65),
      ],
    );
  }
}
