import 'package:flutter/widgets.dart';

abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 960;
  static const double expanded = 1180;

  /// Maximum readable content width for wide web windows.
  static const double contentMaxWidth = 1120;

  /// Horizontal gutter used by pages at a given viewport width.
  static double pagePaddingFor(double width) {
    if (width < compact) return 16;
    if (width < medium) return 24;
    return 32;
  }
}

extension AppResponsiveContext on BuildContext {
  Size get viewport => MediaQuery.sizeOf(this);

  bool get isCompact => viewport.width < AppBreakpoints.compact;

  bool get usesSideNavigation => viewport.width >= AppBreakpoints.medium;

  bool get isExpanded => viewport.width >= AppBreakpoints.expanded;

  double get pagePadding => isCompact ? 16 : 28;

  double get readableWidth => 1120;
}
