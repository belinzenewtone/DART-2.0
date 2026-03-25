import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── Layout ───────────────────────────────────────────────────────────────────
  static const double screenHorizontal = 24;
  static const double screenTop = 16;
  static const double shellHorizontal = 16;
  static const double contentBottomSafe = 152;
  static const double sectionBottom = 20;
  static const double fabBottomOffset = 96;

  // ── Gaps ─────────────────────────────────────────────────────────────────────
  /// Between two sibling section blocks
  static const double sectionGap = 20;

  /// Between a section header and its first card
  static const double sectionHeaderGap = 16;

  /// Between adjacent cards in the same section
  static const double cardGap = 16;

  /// Between adjacent list items (tight)
  static const double listGap = 8;

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
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return math.max(safeBottom + 2, 4);
  }

  static double _safeBottomContribution(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom > 0 ? safeBottom * 0.6 : 0;
  }
}
