import 'package:flutter/widgets.dart';

/// Device type for responsive layouts
enum DeviceType { mobile, tablet, desktop }

/// Responsive utility providing breakpoints and adaptive sizing
class Responsive {
  Responsive._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Get device type from screen width
  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).shortestSide;
    if (width >= tabletBreakpoint) return DeviceType.desktop;
    if (width >= mobileBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      deviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceType(context) == DeviceType.desktop;

  /// Number of grid columns based on device
  static int gridColumns(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return 4;
      case DeviceType.tablet:
        return 2;
      case DeviceType.mobile:
        return 1;
    }
  }

  /// Horizontal padding based on device
  static double horizontalPadding(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return 48;
      case DeviceType.tablet:
        return 32;
      case DeviceType.mobile:
        return 16;
    }
  }

  /// Content max width for centering on large screens
  static double contentMaxWidth(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return 1200;
      case DeviceType.tablet:
        return 800;
      case DeviceType.mobile:
        return double.infinity;
    }
  }

  /// Adaptive font scale factor
  static double fontScale(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return 1.15;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.mobile:
        return 1.0;
    }
  }

  /// Chart height based on device
  static double chartHeight(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return 300;
      case DeviceType.tablet:
        return 260;
      case DeviceType.mobile:
        return 200;
    }
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, Responsive.deviceType(context));
      },
    );
  }
}

/// Widget that constrains content width on large screens
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveContent({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final max = maxWidth ?? Responsive.contentMaxWidth(context);
    if (max == double.infinity) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}

/// Responsive grid that adapts column count based on device
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final cols = columns ?? Responsive.gridColumns(context);
    if (cols == 1) {
      return Column(
        children: children
            .map((c) => Padding(
                  padding: EdgeInsets.only(bottom: runSpacing),
                  child: c,
                ))
            .toList(),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += cols) {
      final rowChildren = <Widget>[];
      for (int j = 0; j < cols; j++) {
        if (i + j < children.length) {
          if (j > 0) rowChildren.add(SizedBox(width: spacing));
          rowChildren.add(Expanded(child: children[i + j]));
        } else {
          if (j > 0) rowChildren.add(SizedBox(width: spacing));
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: runSpacing),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      ));
    }
    return Column(children: rows);
  }
}
