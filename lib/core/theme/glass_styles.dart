import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GlassStyles {
  GlassStyles._();

  static const double blurSigma = 12;
  static const double borderRadius = 24;
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  static LinearGradient backgroundGradientFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEFF5FF), Color(0xFFDCEBFF)],
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
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xBFEFFFFF),
          Color(0x99DDE9FF),
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x3B1E3A67),
        Color(0x1C102542),
      ],
    );
  }
}
