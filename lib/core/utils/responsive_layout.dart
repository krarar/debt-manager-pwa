import 'package:flutter/material.dart';

enum QistiScreenType { mobile, tablet, desktop, largeDesktop }

abstract final class ResponsiveLayout {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1440;

  static QistiScreenType typeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return QistiScreenType.mobile;
    if (width < tabletBreakpoint) return QistiScreenType.tablet;
    if (width < desktopBreakpoint) return QistiScreenType.desktop;
    return QistiScreenType.largeDesktop;
  }

  static bool isMobile(BuildContext context) =>
      typeOf(context) == QistiScreenType.mobile;
  static bool isTablet(BuildContext context) =>
      typeOf(context) == QistiScreenType.tablet;
  static bool isDesktop(BuildContext context) =>
      typeOf(context) != QistiScreenType.mobile &&
      typeOf(context) != QistiScreenType.tablet;

  static double maxContentWidth(BuildContext context) {
    final type = typeOf(context);
    switch (type) {
      case QistiScreenType.mobile:
        return 640;
      case QistiScreenType.tablet:
        return 920;
      case QistiScreenType.desktop:
        return 1200;
      case QistiScreenType.largeDesktop:
        return 1360;
    }
  }

  static int metricColumns(BuildContext context) {
    switch (typeOf(context)) {
      case QistiScreenType.mobile:
        return 1;
      case QistiScreenType.tablet:
        return 2;
      case QistiScreenType.desktop:
        return 4;
      case QistiScreenType.largeDesktop:
        return 4;
    }
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return const EdgeInsets.all(12);
    if (width < 600) return const EdgeInsets.all(16);
    if (width < 900) return const EdgeInsets.all(20);
    return const EdgeInsets.all(24);
  }
}
