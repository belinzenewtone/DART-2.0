import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ToolShortcut {
  const ToolShortcut({
    required this.label,
    required this.icon,
    required this.color,
    this.routeName,
    this.shellTab,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? routeName;
  final ShellTab? shellTab;
}

const defaultToolShortcuts = [
  ToolShortcut(
    label: 'Analytics',
    icon: Icons.query_stats_rounded,
    color: AppColors.accent,
    routeName: 'analytics',
  ),
  ToolShortcut(
    label: 'Review',
    icon: Icons.history_edu_rounded,
    color: AppColors.violet,
    routeName: 'week-review',
  ),
  ToolShortcut(
    label: 'Search',
    icon: Icons.search_rounded,
    color: AppColors.sky,
    routeName: 'search',
  ),
  ToolShortcut(
    label: 'Recurring',
    icon: Icons.repeat_rounded,
    color: AppColors.teal,
    routeName: 'recurring',
  ),
  ToolShortcut(
    label: 'Export',
    icon: Icons.download_rounded,
    color: AppColors.warning,
    routeName: 'export',
  ),
  ToolShortcut(
    label: 'Assistant',
    icon: Icons.forum_outlined,
    color: AppColors.success,
    shellTab: ShellTab.assistant,
  ),
];

class ToolShortcutGrid extends ConsumerWidget {
  const ToolShortcutGrid({
    super.key,
    this.shortcuts = defaultToolShortcuts,
  });

  final List<ToolShortcut> shortcuts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 290 ? 2 : 3;
        final aspectRatio = crossAxisCount == 3 ? 0.98 : 1.08;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.listGap,
            mainAxisSpacing: AppSpacing.listGap,
            childAspectRatio: aspectRatio,
          ),
          itemCount: shortcuts.length,
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            return _ToolShortcutTile(
              shortcut: shortcut,
              onTap: () {
                AppHaptics.lightImpact();
                if (shortcut.shellTab != null) {
                  ref.read(shellTabIndexProvider.notifier).state =
                      shortcut.shellTab!.index;
                  return;
                }
                context.pushNamed(shortcut.routeName!);
              },
            );
          },
        );
      },
    );
  }
}

class _ToolShortcutTile extends StatelessWidget {
  const _ToolShortcutTile({
    required this.shortcut,
    required this.onTap,
  });

  final ToolShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tone: GlassCardTone.muted,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shortcut.color.withValues(alpha: 0.14),
              border: Border.all(
                color: shortcut.color.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              shortcut.icon,
              color: shortcut.color,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            shortcut.label,
            textAlign: TextAlign.center,
            style: AppTypography.cardTitle(context).copyWith(
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
