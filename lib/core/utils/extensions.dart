import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'responsive.dart';

/// Numeric formatting extensions
extension NumFormatting on num {
  /// Formats as currency: $1,234.56
  String toCurrency() {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(this);
  }

  /// Formats with commas: 1,234
  String toCompact() {
    final formatter = NumberFormat.compact();
    return formatter.format(this);
  }

  /// Formats CO2 emissions: 1,234.5 t
  String toCO2() {
    final formatter = NumberFormat('#,##0.1');
    return '${formatter.format(this)} t CO₂';
  }
}

/// String helpers
extension StringX on String {
  /// Capitalizes first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// BuildContext convenience extensions
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Responsive helpers
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  DeviceType get deviceType => Responsive.deviceType(this);
  double get horizontalPadding => Responsive.horizontalPadding(this);
  double get contentMaxWidth => Responsive.contentMaxWidth(this);
  int get gridColumns => Responsive.gridColumns(this);
  double get chartHeight => Responsive.chartHeight(this);

  /// Cupertino theme data (safe fallback)
  CupertinoThemeData get cupertinoTheme => CupertinoTheme.of(this);
}
