import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_bar_chart.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_category_breakdown.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_overview_cards.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(analyticsSnapshotProvider);
    final period = ref.watch(analyticsPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.sectionPadding(context),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend Window',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<AnalyticsPeriod>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: AnalyticsPeriod.week,
                        icon: Icon(Icons.view_week_outlined),
                        label: Text('Weekly'),
                      ),
                      ButtonSegment(
                        value: AnalyticsPeriod.month,
                        icon: Icon(Icons.calendar_month_outlined),
                        label: Text('Monthly'),
                      ),
                    ],
                    selected: {period},
                    onSelectionChanged: (next) {
                      ref.read(analyticsPeriodProvider.notifier).state =
                          next.first;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            snapshotState.when(
              data: (snapshot) => _AnalyticsContent(
                snapshot: snapshot,
                period: period,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ErrorMessage(
                label: 'Unable to load analytics',
                onRetry: () => ref.invalidate(analyticsSnapshotProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.snapshot,
    required this.period,
  });

  final AnalyticsSnapshot snapshot;
  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final trendPoints = switch (period) {
      AnalyticsPeriod.week => snapshot.weeklySpending,
      AnalyticsPeriod.month => snapshot.monthlySpending,
    };
    final trendTitle = period == AnalyticsPeriod.week
        ? 'Weekly Spending Trend'
        : 'Monthly Spending Trend';

    return Column(
      children: [
        AnalyticsOverviewCards(snapshot: snapshot),
        const SizedBox(height: 12),
        AnalyticsTrendChart(
          title: trendTitle,
          points: trendPoints,
        ),
        const SizedBox(height: 12),
        AnalyticsBarChart(
          title: period == AnalyticsPeriod.week
              ? 'Weekly Spend Distribution'
              : 'Daily Spend Distribution',
          points: trendPoints,
        ),
        const SizedBox(height: 12),
        AnalyticsCategoryBreakdown(
          categories: snapshot.categoryBreakdown,
        ),
      ],
    );
  }
}
