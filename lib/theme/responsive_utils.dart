import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class ResponsiveUtils {
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isCompact(BuildContext context) => screenWidth(context) < 360;

  static bool isTablet(BuildContext context) => screenWidth(context) >= 600;

  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1024;

  static double pageMaxWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1400) return 1320;
    if (width >= 1100) return 1180;
    if (width >= 900) return 980;
    return width;
  }

  static double shellHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 28;
    if (isTablet(context)) return 20;
    return 0;
  }

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 28;
    if (isTablet(context)) return 24;
    return isCompact(context) ? 14 : 18;
  }

  static double contentGap(BuildContext context) {
    if (isTablet(context)) return 22;
    return isCompact(context) ? 12 : 16;
  }

  static double responsiveFont(
    BuildContext context, {
    required double compact,
    required double regular,
    double? tablet,
  }) {
    if (isTablet(context)) {
      return tablet ?? regular + 2;
    }
    return isCompact(context) ? compact : regular;
  }

  static int adaptiveGridColumns(
    BuildContext context, {
    int compact = 2,
    int regular = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    final width = screenWidth(context);
    if (width >= 1100) return desktop;
    if (width >= 600) return tablet;
    if (width < 360) return compact;
    return regular;
  }

  static double playerArtworkSize(BuildContext context) {
    final width = screenWidth(context);
    final height = screenHeight(context);
    return math.min(width * 0.82, height * 0.34).clamp(220.0, 420.0);
  }

  static double miniPlayerHeight(BuildContext context) {
    if (isDesktop(context)) return 88;
    if (isTablet(context)) return 82;
    return isCompact(context) ? 68 : 74;
  }

  static double navIconSize(BuildContext context, {required bool selected}) {
    if (isDesktop(context)) return selected ? 30 : 24;
    if (isTablet(context)) return selected ? 36 : 30;
    if (isCompact(context)) return selected ? 30 : 24;
    return selected ? 34 : 28;
  }
}
