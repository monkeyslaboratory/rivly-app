import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 60,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.1),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }

  static Widget list({int count = 3, double itemHeight = 72}) {
    return Column(
      children: List.generate(
        count,
        (index) => LoadingShimmer(
          height: itemHeight,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        ),
      ),
    );
  }

  static Widget card() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingShimmer(width: 200, height: 20),
          SizedBox(height: 12),
          LoadingShimmer(height: 14),
          SizedBox(height: 8),
          LoadingShimmer(width: 150, height: 14),
        ],
      ),
    );
  }
}
