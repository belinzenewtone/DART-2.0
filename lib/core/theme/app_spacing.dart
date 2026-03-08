import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double screenHorizontal = 20;
  static const double screenTop = 12;
  static const double shellHorizontal = 12;
  static const double contentBottomSafe = 120;
  static const double sectionBottom = 24;
  static const double navBottomMargin = 16;
  static const double fabBottomOffset = 104;

  static EdgeInsets screenPadding(
    BuildContext context, {
    double bottom = contentBottomSafe,
  }) {
    return EdgeInsets.fromLTRB(
      screenHorizontal,
      screenTop,
      screenHorizontal,
      bottom + _safeBottomContribution(context),
    );
  }

  static EdgeInsets sectionPadding(
    BuildContext context, {
    double bottom = sectionBottom,
  }) {
    return EdgeInsets.fromLTRB(
      screenHorizontal,
      screenTop,
      screenHorizontal,
      bottom + _safeBottomContribution(context),
    );
  }

  static double fabBottom(BuildContext context) {
    return fabBottomOffset + _safeBottomContribution(context);
  }

  static double navBottom(BuildContext context) {
    return navBottomMargin + _safeBottomContribution(context);
  }

  static double _safeBottomContribution(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom > 0 ? safeBottom * 0.6 : 0;
  }
}
