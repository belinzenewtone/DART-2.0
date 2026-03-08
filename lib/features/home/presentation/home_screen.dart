import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/app_motion.dart';
import 'package:dart_2_0/core/utils/currency_formatter.dart';
import 'package:dart_2_0/core/widgets/beltech_logo.dart';
import 'package:dart_2_0/core/widgets/error_message.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/core/widgets/loading_indicator.dart';
import 'package:dart_2_0/core/widgets/stagger_reveal.dart';
import 'package:dart_2_0/features/home/domain/entities/home_overview.dart';
import 'package:dart_2_0/features/home/presentation/providers/home_providers.dart';
import 'package:dart_2_0/features/home/presentation/widgets/spending_chart.dart';
import 'package:dart_2_0/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final overviewState = ref.watch(homeOverviewProvider);
    final profileState = ref.watch(profileProvider);
    final firstName = profileState.valueOrNull?.name.trim().split(' ').first;
    final greeting = _buildGreeting(firstName);
    final contentSwitchDuration =
        AppMotion.duration(context, normalMs: 180, reducedMs: 0);
    final overviewChild = overviewState.when(
      data: (overview) => KeyedSubtree(
        key: const ValueKey<String>('overview-data'),
        child: _OverviewContent(overview: overview),
      ),
      loading: () => const KeyedSubtree(
        key: ValueKey<String>('overview-loading'),
        child: Center(child: LoadingIndicator()),
      ),
      error: (_, __) => KeyedSubtree(
        key: const ValueKey<String>('overview-error'),
        child: ErrorMessage(
          label: 'Unable to load dashboard',
          onRetry: () => ref.invalidate(homeOverviewProvider),
        ),
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BeltechLogo(size: 38, borderRadius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(greeting, style: textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("Here's your day at a glance", style: textTheme.bodyMedium),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: contentSwitchDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: overviewChild,
            ),
          ],
        ),
      ),
    );
  }

  String _buildGreeting(String? firstName) {
    final hour = DateTime.now().hour;
    final salutation = switch (hour) {
      >= 5 && < 12 => 'Good Morning',
      >= 12 && < 17 => 'Good Afternoon',
      >= 17 && < 21 => 'Good Evening',
      _ => 'Good Night',
    };
    if (firstName == null || firstName.isEmpty) {
      return salutation;
    }
    return '$salutation, $firstName';
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
                  amount: CurrencyFormatter.money(overview.todayKes),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StaggerReveal(
                delay: const Duration(milliseconds: 80),
                child: _SummaryCard(
                  title: 'This Week',
                  amount: CurrencyFormatter.money(overview.weekKes),
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
            color: AppColors.teal,
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
            color: AppColors.violet,
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
            amount: CurrencyFormatter.money(tx.amountKes),
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
    final iconBackground = Theme.of(context).brightness == Brightness.light
        ? AppColors.accent.withValues(alpha: 0.16)
        : AppColors.accentSoft;
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconBackground,
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
