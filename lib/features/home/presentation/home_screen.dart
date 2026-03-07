import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/widgets/error_message.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/core/widgets/loading_indicator.dart';
import 'package:dart_2_0/core/widgets/stagger_reveal.dart';
import 'package:dart_2_0/features/home/domain/entities/home_overview.dart';
import 'package:dart_2_0/features/home/presentation/providers/home_providers.dart';
import 'package:dart_2_0/features/home/presentation/widgets/spending_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final overviewState = ref.watch(homeOverviewProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Evening', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text("Here's your day at a glance", style: textTheme.bodyMedium),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: overviewState.when(
                data: (overview) => _OverviewContent(overview: overview),
                loading: () => const Center(child: LoadingIndicator()),
                error: (_, __) =>
                    const ErrorMessage(label: 'Unable to load dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.overview});

  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StaggerReveal(
                delay: const Duration(milliseconds: 30),
                child: _SummaryCard(
                  title: 'Today',
                  amount: 'KES ${overview.todayKes.toStringAsFixed(2)}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StaggerReveal(
                delay: const Duration(milliseconds: 80),
                child: _SummaryCard(
                  title: 'This Week',
                  amount: 'KES ${overview.weekKes.toStringAsFixed(2)}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StaggerReveal(
          delay: const Duration(milliseconds: 130),
          child: _InfoCard(
            icon: Icons.check_circle,
            title: 'Productivity',
            subtitle:
                '${overview.completedCount} completed today · ${overview.pendingCount} pending',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 14),
        StaggerReveal(
          delay: const Duration(milliseconds: 180),
          child: _InfoCard(
            icon: Icons.event,
            title: 'Upcoming Events',
            subtitle: overview.upcomingEventsCount == 0
                ? 'No upcoming events'
                : '${overview.upcomingEventsCount} upcoming events',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 14),
        StaggerReveal(
          delay: const Duration(milliseconds: 230),
          child: _WeeklySpendingCard(dayValues: overview.weeklySpendingKes),
        ),
        const SizedBox(height: 14),
        Text('Recent Transactions', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final tx in overview.recentTransactions) ...[
          _TransactionCard(
            title: tx.title,
            category: tx.category,
            amount: 'KES ${tx.amountKes.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.amount});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(amount, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.22),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklySpendingCard extends StatelessWidget {
  const _WeeklySpendingCard({required this.dayValues});

  final Map<String, double> dayValues;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Spending', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SpendingChart(dayValues: dayValues),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.title,
    required this.category,
    required this.amount,
  });

  final String title;
  final String category;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.accentSoft,
            child: Icon(Icons.payments_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyLarge),
                Text(category, style: textTheme.bodyMedium),
              ],
            ),
          ),
          Text(amount, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
