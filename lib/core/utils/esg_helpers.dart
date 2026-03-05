import 'package:flutter/material.dart';
import '../constants/app_colors.dart';


class EsgHelpers {
  EsgHelpers._();

  /// Returns color based on ESG rating string
  static Color ratingColor(String rating) {
    switch (rating.toUpperCase()) {
      case 'AAA':
      case 'AA':
        return AppColors.esgExcellent;
      case 'A':
        return AppColors.esgGood;
      case 'BBB':
        return AppColors.esgAverage;
      case 'BB':
        return AppColors.esgBelowAvg;
      case 'B':
      case 'CCC':
        return AppColors.esgPoor;
      default:
        return Colors.grey;
    }
  }

  /// Returns color based on ESG score (0-100)
  static Color scoreColor(double score) {
    if (score >= 80) return AppColors.esgExcellent;
    if (score >= 60) return AppColors.esgGood;
    if (score >= 40) return AppColors.esgAverage;
    if (score >= 20) return AppColors.esgBelowAvg;
    return AppColors.esgPoor;
  }

  /// Returns label for ESG score range
  static String scoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    if (score >= 20) return 'Below Average';
    return 'Poor';
  }

  /// Checks if stock needs eco-friendly alternative suggestion
  static bool needsAlternative(double esgScore) => esgScore < 50;

  /// Mock eco-friendly alternatives by sector
  static List<String> suggestAlternatives(String symbol) {
    final alternatives = <String, List<String>>{
      'XOM': ['NEE', 'ENPH', 'SEDG'],
      'CVX': ['NEE', 'BEP', 'FSLR'],
      'BP': ['PLUG', 'RUN', 'ENPH'],
      'default': ['NEE', 'TSLA', 'ENPH'],
    };
    return alternatives[symbol.toUpperCase()] ?? alternatives['default']!;
  }
}
