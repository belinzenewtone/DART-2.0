import 'dart:ui';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:flutter/material.dart';

enum GlassCardTone {
  standard,
  accent,
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = GlassStyles.cardPadding,
    this.margin,
    this.borderRadius = GlassStyles.borderRadius,
    this.tone = GlassCardTone.standard,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final GlassCardTone tone;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final effectiveAccent = accentColor ?? colorScheme.primary;
    final gradient = tone == GlassCardTone.accent
        ? GlassStyles.accentGlassGradientFor(
            brightness,
            effectiveAccent,
          )
        : GlassStyles.glassGradientFor(brightness);
    final borderColor = brightness == Brightness.light
        ? AppColors.borderFor(brightness).withValues(alpha: 0.68)
        : colorScheme.outline.withValues(alpha: 0.35);
    final shadowColor = brightness == Brightness.light
        ? const Color(0xFF4D6487).withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.22);
    final glowBase =
        tone == GlassCardTone.accent ? effectiveAccent : AppColors.teal;
    final glowColor = brightness == Brightness.light
        ? glowBase.withValues(alpha: 0.08)
        : glowBase.withValues(alpha: 0.14);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassStyles.blurSigmaFor(brightness),
            sigmaY: GlassStyles.blurSigmaFor(brightness),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: brightness == Brightness.light ? 18 : 28,
                  offset: Offset(0, brightness == Brightness.light ? 8 : 14),
                ),
                BoxShadow(
                  color: glowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
