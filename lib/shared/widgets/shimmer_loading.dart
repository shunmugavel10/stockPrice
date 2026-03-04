import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

/// Reusable shimmer placeholder for loading states
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<GreenInvestThemeExtension>();
    return Shimmer.fromColors(
      baseColor: ext?.shimmerBase ?? Colors.grey.shade300,
      highlightColor: ext?.shimmerHighlight ?? Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer card placeholder mimicking a holding card
class ShimmerHoldingCard extends StatelessWidget {
  const ShimmerHoldingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          const ShimmerLoading(height: 90),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: ShimmerLoading(height: 16)),
              const SizedBox(width: 16),
              const ShimmerLoading(width: 80, height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashboard shimmer placeholder
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShimmerLoading(height: 120),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: ShimmerLoading(height: 80)),
              SizedBox(width: 12),
              Expanded(child: ShimmerLoading(height: 80)),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerLoading(height: 200),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerLoading(height: 80),
          )),
        ],
      ),
    );
  }
}
