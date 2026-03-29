import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum GlassCardTone { standard, accent, muted }

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 22,
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
    final effectiveAccent = accentColor ?? AppColors.accent;

    // Resolve colors similar to RN GlassCard tone styles
    final bgColor = switch (tone) {
      GlassCardTone.accent => brightness == Brightness.light
          ? AppColors.surfaceFor(brightness) // fallback
          : AppColors.surfaceAccent,
      GlassCardTone.muted => brightness == Brightness.light
          ? AppColors.surfaceMutedFor(brightness)
          : AppColors.surfaceMuted,
      GlassCardTone.standard => brightness == Brightness.light
          ? AppColors.surfaceFor(brightness)
          : AppColors.surfaceElevated,
    };

    final borderColor = switch (tone) {
      GlassCardTone.accent => effectiveAccent.withValues(alpha: 0.26), // ~44 hex
      GlassCardTone.muted => brightness == Brightness.light
          ? AppColors.borderFor(brightness)
          : AppColors.border,
      GlassCardTone.standard => brightness == Brightness.light
          ? AppColors.borderFor(brightness)
          : AppColors.borderStrong,
    };

    final shadowColor = brightness == Brightness.light 
         ? const Color(0x1F0F172A)
         : Colors.black.withValues(alpha: 0.12);

    final innerDecoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    Widget inner = Container(
      margin: margin,
      decoration: innerDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
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
