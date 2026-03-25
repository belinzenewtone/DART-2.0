import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Background ──────────────────────────────────────────────────────────────
  // RN palette: near-black with subtle cool tint (matches screenshots exactly)
  static const Color background = Color(0xFF0B0F17);
  static const Color backgroundTop = Color(0xFF0E1520);
  static const Color backgroundBottom = Color(0xFF070A0F);

  // ── Surfaces ─────────────────────────────────────────────────────────────────
  // RN palette: dark neutral surfaces (not heavy blue-navy)
  static const Color surface = Color(0xFF131C2A);
  static const Color surfaceMuted = Color(0xFF0F1621);
  static const Color surfaceSubtle = Color(0xFF0C1019); // deepest surface
  static const Color border = Color(0xFF1E2D3E);

  // ── Accent — TEAL (matches RN primary color throughout) ──────────────────────
  static const Color accent = Color(0xFF14B8A6);
  static const Color accentStrong = Color(0xFF0D9488);
  static const Color accentSoft = Color(0x4014B8A6); // 25% alpha teal

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);   // green-500 — income / positive
  static const Color warning = Color(0xFFF59E0B);   // amber-400
  static const Color danger  = Color(0xFFEF4444);   // red-500 — expenses / danger
  static const Color orange  = Color(0xFFF97316);   // orange-500 (e.g. health events)

  // ── Semantic muted (swipe-action / status backgrounds) ───────────────────────
  static const Color successMuted = Color(0xFF14532D); // complete swipe bg
  static const Color dangerMuted  = Color(0xFF7F1D1D); // delete swipe bg
  static const Color warningMuted = Color(0xFF78350F); // edit swipe bg

  // ── Tooltip / chart overlay ───────────────────────────────────────────────────
  static const Color tooltipBackground = Color(0xDD0D1420);

  // ── Text (three levels) ──────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF1F5F9); // slate-100
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textMuted     = Color(0xFF64748B); // slate-500 — tertiary / metadata

  // ── Extended palette ─────────────────────────────────────────────────────────
  static const Color teal   = Color(0xFF0D9488); // teal-600 (secondary teal)
  static const Color violet = Color(0xFF8B5CF6); // violet-500
  static const Color slate  = Color(0xFF475569); // slate-600
  static const Color azure  = Color(0xFF3B82F6); // blue-500
  static const Color sky    = Color(0xFF0EA5E9); // sky-500

  // ── Glow colors (radial background atmosphere) ───────────────────────────────
  // Teal-based glows to match RN accent
  static const Color glowBlue   = Color(0x3314B8A6); // 20% teal (replaces old blue glow)
  static const Color glowTeal   = Color(0x2914B8A6); // 16% teal
  static const Color glowViolet = Color(0x298B5CF6); // 16% violet
  static const Color glowAmber  = Color(0x29F59E0B); // 16% amber

  // ── Category colors (foreground) — matching RN colored pill borders ───────────
  static const Color categoryWork      = Color(0xFF3B82F6); // blue-500
  static const Color categoryGrowth    = Color(0xFF8B5CF6); // violet-500
  static const Color categoryPersonal  = Color(0xFF10B981); // emerald-500
  static const Color categoryBill      = Color(0xFFF59E0B); // amber-400
  static const Color categoryHealth    = Color(0xFFEF4444); // red-500
  static const Color categoryOther     = Color(0xFF64748B); // slate-500
  static const Color categoryFood      = Color(0xFFF97316); // orange-500
  static const Color categoryAirtime   = Color(0xFFA855F7); // purple-500
  static const Color categoryTransport = Color(0xFF06B6D4); // cyan-500

  // ── Category muted backgrounds (for chips/avatars) ───────────────────────────
  static const Color categoryFoodBg      = Color(0xFF431407);
  static const Color categoryAirtimeBg   = Color(0xFF3B0764);
  static const Color categoryBillBg      = Color(0xFF451A03);
  static const Color categoryTransportBg = Color(0xFF083344);

  /// Returns the foreground color for a named category (case-insensitive).
  static Color categoryColorFor(String category) {
    return switch (category.toLowerCase()) {
      'work' => categoryWork,
      'growth' || 'personal growth' => categoryGrowth,
      'personal' => categoryPersonal,
      'bill' || 'bills' || 'utilities' => categoryBill,
      'health' || 'medical' || 'healthcare' => categoryHealth,
      'food' || 'restaurant' || 'groceries' || 'eating out' || 'food & dining' => categoryFood,
      'airtime' || 'mobile' || 'data' => categoryAirtime,
      'transport' || 'transit' || 'fuel' => categoryTransport,
      'shopping' => const Color(0xFFEC4899), // pink-500
      'rent' => const Color(0xFFEF4444),     // red-500
      'savings' => accent,                   // teal
      'loans' || 'loans & credit' || 'credit' => const Color(0xFFEF4444), // red-500
      'transfer' => const Color(0xFF6366F1), // indigo-500
      'education' => sky,                    // sky-500
      'entertainment' => warning,            // amber
      'family' => violet,                    // violet
      _ => categoryOther,
    };
  }

  // ── Brightness-aware helpers ─────────────────────────────────────────────────
  static Color backgroundFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFF2F6FC) : background;

  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFFFFFFF) : surface;

  static Color surfaceMutedFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFF1F5FB) : surfaceMuted;

  static Color surfaceSubtleFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFEBF1FA) : surfaceSubtle;

  static Color borderFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFCBD5E1) : border;

  static Color textPrimaryFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF0F172A) : textPrimary;

  static Color textSecondaryFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF475569) : textSecondary;

  static Color textMutedFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF94A3B8) : textMuted;
}
