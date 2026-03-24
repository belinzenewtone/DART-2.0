import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Lightweight selection chip used for filter rows.
///
/// Uses an [AnimatedContainer] instead of a full [GlassCard] so the row
/// stays compact — no backdrop blur, no shadow, no glow. The selected state
/// is conveyed purely through fill colour and text colour transitions.
class CategoryChip extends StatefulWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    // Light mode: solid white unselected → solid accent selected (iOS HIG style)
    // Dark mode: original tinted glass style
    final selectedBg = isLight ? AppColors.accent : AppColors.accent.withValues(alpha: 0.22);
    final unselectedBg = isLight
        ? Colors.white
        : AppColors.surfaceSubtle.withValues(alpha: 0.92);

    final selectedBorder = isLight ? AppColors.accent : AppColors.accent.withValues(alpha: 0.82);
    final unselectedBorder = isLight
        ? const Color(0xFFE5E5EA)
        : AppColors.border.withValues(alpha: 0.42);

    final selectedTextColor = isLight ? Colors.white : AppColors.textPrimary;
    final unselectedTextColor = isLight ? AppColors.textSecondary : AppColors.textSecondary;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected ? selectedBg : unselectedBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.selected ? selectedBorder : unselectedBorder,
                width: 1,
              ),
              // Light mode: no shadow on chips — iOS style
              // Dark mode: subtle lift shadow
              boxShadow: isLight
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Text(
              widget.label,
              style: AppTypography.bodySm(context).copyWith(
                color: widget.selected ? selectedTextColor : unselectedTextColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
