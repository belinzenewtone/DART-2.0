import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Legacy dark palette tokens
  static const Color background = Color(0xFF020B1E);
  static const Color backgroundTop = Color(0xFF0A1B3E);
  static const Color backgroundBottom = Color(0xFF030713);

  static const Color surface = Color(0xFF16243D);
  static const Color surfaceMuted = Color(0xFF101C31);
  static const Color border = Color(0xFF2E4A78);

  static const Color accent = Color(0xFF2F82FF);
  static const Color accentStrong = Color(0xFF175FFF);
  static const Color accentSoft = Color(0x663486FF);
  static const Color success = Color(0xFF4AC36B);
  static const Color warning = Color(0xFFF2A63A);
  static const Color danger = Color(0xFFE45C5C);

  static const Color textPrimary = Color(0xFFF3F7FF);
  static const Color textSecondary = Color(0xFFA8B9D6);

  // Extended restrained palette
  static const Color teal = Color(0xFF2AAE9D);
  static const Color violet = Color(0xFF6D77E8);
  static const Color slate = Color(0xFF5F7395);

  static Color backgroundFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const Color(0xFFF2F6FC);
    }
    return background;
  }

  static Color surfaceFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const Color(0xFFFFFFFF);
    }
    return surface;
  }

  static Color surfaceMutedFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const Color(0xFFF1F5FB);
    }
    return surfaceMuted;
  }

  static Color borderFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const Color(0xFFB7C6DC);
    }
    return border;
  }

  static Color textPrimaryFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const Color(0xFF11233F);
    }
    return textPrimary;
  }

  static Color textSecondaryFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const Color(0xFF516584);
    }
    return textSecondary;
  }
}
