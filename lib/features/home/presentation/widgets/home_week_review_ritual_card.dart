import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/review/domain/entities/week_review_data.dart';
import 'package:beltech/features/review/presentation/providers/review_ritual_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeWeekReviewRitualCard extends ConsumerWidget {
  const HomeWeekReviewRitualCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ritualState = ref.watch(weekReviewRitualProvider);
    return ritualState.when(
      data: (ritual) {
        if (ritual == null) {
          return const SizedBox.shrink();
        }
        final accent = switch (ritual.tone) {
          WeekReviewInsightTone.positive => AppColors.success,
          WeekReviewInsightTone.caution => AppColors.warning,
          WeekReviewInsightTone.neutral => AppColors.accent,
        };
        return GlassCard(
          tone: GlassCardTone.accent,
          accentColor: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Ritual',
                style: AppTypography.sectionTitle(context),
              ),
              const SizedBox(height: 8),
              Text(
                ritual.headline,
                style: AppTypography.cardTitle(context),
              ),
              const SizedBox(height: 6),
              Text(
                ritual.summary,
                style: AppTypography.bodySm(context),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ritual.focusLabel}: ${ritual.focusDetail}',
                      style: AppTypography.bodySm(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => context.pushNamed('week-review'),
                    child: Text(ritual.ctaLabel),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const AppEmptyState(
        icon: Icons.date_range_rounded,
        title: 'Weekly ritual unavailable',
        subtitle: 'Pull to refresh and try again.',
      ),
    );
  }
}
