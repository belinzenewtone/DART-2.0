import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GlassStyles {
  GlassStyles._();

  // In dark mode we keep the frosted glass look.
  // In light mode we use clean iOS-style solid white surfaces — no blur needed.
  static const double blurSigma = 12;
  static const double borderRadius = 20;
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  static double blurSigmaFor(Brightness brightness) {
    // Light mode: zero blur — iOS uses solid white cards, not glass
    if (brightness == Brightness.light) return 0;
    return blurSigma;
  }

  static LinearGradient backgroundGradientFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      // Solid iOS systemGroupedBackground — no gradient needed
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF2F2F7),
          Color(0xFFF2F2F7),
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
    );
  }

  static LinearGradient glassGradientFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      // Pure white — no tinting, clean iOS card surface
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xD21A2A45),
        Color(0xB6122036),
      ],
    );
  }

  static LinearGradient accentGlassGradientFor(
    Brightness brightness,
    Color accent,
  ) {
    if (brightness == Brightness.light) {
      // Soft tinted card — accent at 8% opacity, fading to white
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.08),
          const Color(0xFFFFFFFF),
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent.withValues(alpha: 0.24),
        const Color(0xC2143156),
      ],
    );
  }
}
