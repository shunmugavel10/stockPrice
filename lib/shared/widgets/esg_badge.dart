import 'package:flutter/material.dart';
import '../../core/utils/esg_helpers.dart';

/// Small badge displaying ESG rating with color coding
class EsgBadge extends StatelessWidget {
  final String rating;
  final double? score;

  const EsgBadge({super.key, required this.rating, this.score});

  @override
  Widget build(BuildContext context) {
    final color = EsgHelpers.ratingColor(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            rating,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
