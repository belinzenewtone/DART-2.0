import 'dart:ui';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:flutter/material.dart';

enum GlassCardTone { standard, accent, muted }

/// A surface card that adapts between two design languages:
///
/// **Light mode** — iOS-style clean card:
///   • Pure white (#FFFFFF) fill
///   • Single soft shadow (no border, no blur, no gradient)
///   • "muted" tone uses #F2F2F7 fill (iOS grouped cell bg)
///
/// **Dark mode** — frosted glass card (unchanged):
///   • Semi-transparent gradient surface
///   • BackdropFilter blur
///   • Coloured border + glow shadow
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = GlassStyles.cardPadding,
    this.margin,
    this.borderRadius = GlassStyles.borderRadius,
    this.tone = GlassCardTone.standard,
    this.accentColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final GlassCardTone tone;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? _LightCard(
            padding: padding,
            margin: margin,
            borderRadius: borderRadius,
            tone: tone,
            accentColor: accentColor ?? Theme.of(context).colorScheme.primary,
            onTap: onTap,
            child: child,
          )
        : _DarkGlassCard(
            padding: padding,
            margin: margin,
            borderRadius: borderRadius,
            tone: tone,
            accentColor: accentColor ?? Theme.of(context).colorScheme.primary,
            onTap: onTap,
            child: child,
          );
  }
}

// ── Light mode — clean iOS white card ────────────────────────────────────────

class _LightCard extends StatelessWidget {
  const _LightCard({
    required this.child,
    required this.padding,
    required this.borderRadius,
    required this.tone,
    required this.accentColor,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final GlassCardTone tone;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Surface color
    final fillColor = switch (tone) {
      GlassCardTone.muted => const Color(0xFFEFEFF4),
      GlassCardTone.accent =>
        Color.alphaBlend(accentColor.withValues(alpha: 0.06), Colors.white),
      GlassCardTone.standard => Colors.white,
    };

    // Shadow — single soft drop, iOS-style
    final shadows = [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

    final decoration = BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: tone == GlassCardTone.muted ? [] : shadows,
    );

    Widget inner = RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: accentColor.withValues(alpha: 0.06),
          highlightColor: accentColor.withValues(alpha: 0.04),
          child: inner,
        ),
      );
    }

    return inner;
  }
}

// ── Dark mode — frosted glass card (original implementation) ─────────────────

class _DarkGlassCard extends StatelessWidget {
  const _DarkGlassCard({
    required this.child,
    required this.padding,
    required this.borderRadius,
    required this.tone,
    required this.accentColor,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final GlassCardTone tone;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const brightness = Brightness.dark;

    final gradient = switch (tone) {
      GlassCardTone.accent =>
        GlassStyles.accentGlassGradientFor(brightness, accentColor),
      GlassCardTone.muted => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x180D1B30),
            const Color(0x100A1424),
          ],
        ),
      GlassCardTone.standard => GlassStyles.glassGradientFor(brightness),
    };

    final borderColor = switch (tone) {
      GlassCardTone.muted => AppColors.border.withValues(alpha: 0.18),
      _ => Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
    };

    final double shadowAlpha =
        tone == GlassCardTone.muted ? 0.06 : 0.22;
    final shadowColor = Colors.black.withValues(alpha: shadowAlpha);

    final glowBase =
        tone == GlassCardTone.accent ? accentColor : AppColors.teal;
    final glowColor = tone == GlassCardTone.muted
        ? Colors.transparent
        : glowBase.withValues(alpha: 0.14);

    final blurSigma = tone == GlassCardTone.muted
        ? GlassStyles.blurSigma * 0.65
        : GlassStyles.blurSigma;

    final skipBlur = AppMotion.reduceMotion(context);
    const highlightColor = Color(0x1FFFFFFF);

    final innerDecoration = BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        if (tone != GlassCardTone.muted)
          BoxShadow(
            color: glowColor,
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
      ],
    );

    Widget inner = RepaintBoundary(
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: skipBlur
              ? _DarkCardSurface(
                  decoration: innerDecoration,
                  padding: padding,
                  highlightColor: highlightColor,
                  child: child,
                )
              : BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: _DarkCardSurface(
                    decoration: innerDecoration,
                    padding: padding,
                    highlightColor: highlightColor,
                    child: child,
                  ),
                ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: inner,
        ),
      );
    }

    return inner;
  }
}

class _DarkCardSurface extends StatelessWidget {
  const _DarkCardSurface({
    required this.decoration,
    required this.padding,
    required this.highlightColor,
    required this.child,
  });

  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final Color highlightColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
