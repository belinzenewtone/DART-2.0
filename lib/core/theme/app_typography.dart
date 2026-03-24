import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic text style helpers.
///
/// All styles are brightness-aware — light mode uses the iOS Human Interface
/// Guidelines letter-spacing and weight conventions (tighter tracking on large
/// text, medium weight for labels). Dark mode retains the original values.
///
/// Usage:
/// ```dart
/// Text('Good Morning', style: AppTypography.pageTitle(context))
/// Text('YOUR DAY',     style: AppTypography.eyebrow(context))
/// Text('KES 4,200',    style: AppTypography.amountLg(context))
/// ```
class AppTypography {
  AppTypography._();

  static bool _isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  // ── Page-level ───────────────────────────────────────────────────────────────

  /// 28 / 34px w700 — screen main title
  static TextStyle pageTitle(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: light ? 30 : 28,
      fontWeight: FontWeight.w700,
      height: light ? 36 / 30 : 34 / 28,
      letterSpacing: light ? 0.35 : 0,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// 11px w600 uppercase + letter-spacing — label above a title
  static TextStyle eyebrow(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: light ? 0.5 : 0.9,
      height: 1.4,
      color: light ? const Color(0xFF8E8EA0) : const Color(0xFF74839A),
    );
  }

  // ── Section-level ────────────────────────────────────────────────────────────

  /// 17px w600 — section label
  static TextStyle sectionTitle(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 24 / 17,
      letterSpacing: light ? -0.4 : 0,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  // ── Card-level ───────────────────────────────────────────────────────────────

  /// 15px w600 — card heading
  static TextStyle cardTitle(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 22 / 15,
      letterSpacing: light ? -0.23 : 0,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────────

  /// 15px w400 — default body copy
  static TextStyle bodyMd(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 22 / 15,
      letterSpacing: light ? -0.23 : 0,
      color: light ? const Color(0xFF515167) : const Color(0xFFA8B9D6),
    );
  }

  /// 13px w400 — small supporting text, metadata
  static TextStyle bodySm(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 20 / 13,
      letterSpacing: light ? -0.08 : 0,
      color: light ? const Color(0xFF8E8EA0) : const Color(0xFF74839A),
    );
  }

  // ── Numeric / financial ──────────────────────────────────────────────────────

  /// 22px w700 — inline amounts on cards
  static TextStyle amount(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 28 / 22,
      letterSpacing: light ? -0.5 : 0,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// 30px w700 — hero amounts (balance, total)
  static TextStyle amountLg(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: light ? 32 : 30,
      fontWeight: FontWeight.w700,
      height: 38 / 32,
      letterSpacing: light ? -0.5 : 0,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  // ── Meta / label ─────────────────────────────────────────────────────────────

  /// 12px w400 — chart axis labels, timestamp chips, fine-print metadata
  static TextStyle metaText(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 18 / 12,
      letterSpacing: light ? 0 : 0,
      color: light ? const Color(0xFF8E8EA0) : const Color(0xFF74839A),
    );
  }

  /// 12px w500 — small uppercase labels, form section headers
  static TextStyle label(BuildContext context) {
    final light = _isLight(context);
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 18 / 12,
      letterSpacing: light ? 0.06 : 0.3,
      color: light ? const Color(0xFF515167) : const Color(0xFFA8B9D6),
    );
  }

  // ── Utility ──────────────────────────────────────────────────────────────────

  /// Copy a style and apply a specific color without losing the rest.
  static TextStyle withColor(TextStyle style, Color color) =>
      style.copyWith(color: color);

  /// Copy a style and reduce opacity (for disabled / muted states).
  static TextStyle muted(TextStyle style) => style.copyWith(
        color: style.color?.withValues(alpha: 0.5),
      );
}
