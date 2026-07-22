import 'package:flutter/material.dart';

/// Khoảng cách & bo góc dùng chung.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;

  static const pagePadding = EdgeInsets.symmetric(horizontal: lg);
  static const sectionGap = SizedBox(height: md);
}
