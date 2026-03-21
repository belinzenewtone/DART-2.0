import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Quick-prompt chip row — chips scroll horizontally so they never wrap
/// to a second line and don't consume extra vertical space.
class AssistantPromptGrid extends StatelessWidget {
  const AssistantPromptGrid({
    required this.prompts,
    required this.onPromptTap,
    super.key,
  });

  final List<String> prompts;
  final Future<void> Function(String) onPromptTap;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (int i = 0; i < prompts.length; i++) ...[
            ActionChip(
              label: Text(
                prompts[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              onPressed: () => onPromptTap(prompts[i]),
              side: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
              backgroundColor: AppColors.accentSoft.withValues(alpha: 0.6),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            if (i < prompts.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
