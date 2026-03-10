import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/providers/global_search_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalSearchScreen extends ConsumerWidget {
  const GlobalSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(globalSearchQueryProvider);
    final resultsState = ref.watch(globalSearchResultsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Global Search')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.sectionPadding(context),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  ref.read(globalSearchQueryProvider.notifier).state = value;
                },
                decoration: const InputDecoration(
                  hintText:
                      'Search expenses, income, tasks, events, budgets, recurring...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: resultsState.when(
                  data: (results) {
                    if (query.trim().isEmpty) {
                      return const GlassCard(
                        child: Text('Start typing to search across the app'),
                      );
                    }
                    if (results.isEmpty) {
                      return const GlassCard(
                        child: Text('No matching results'),
                      );
                    }
                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return GlassCard(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _navigateTo(context, result.kind),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  child: Icon(_iconFor(result.kind)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(result.primaryText,
                                          style: textTheme.bodyLarge),
                                      Text(
                                        result.secondaryText,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(result.trailingText),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => ErrorMessage(
                    label: 'Search failed',
                    onRetry: () => ref.invalidate(globalSearchResultsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(GlobalSearchKind kind) {
    return switch (kind) {
      GlobalSearchKind.expense => Icons.receipt_long_outlined,
      GlobalSearchKind.income => Icons.account_balance_wallet_outlined,
      GlobalSearchKind.task => Icons.check_circle_outline,
      GlobalSearchKind.event => Icons.calendar_month_outlined,
      GlobalSearchKind.budget => Icons.savings_outlined,
      GlobalSearchKind.recurring => Icons.autorenew,
    };
  }

  void _navigateTo(BuildContext context, GlobalSearchKind kind) {
    switch (kind) {
      case GlobalSearchKind.expense:
        context.pop();
      case GlobalSearchKind.income:
        context.pushNamed('income');
      case GlobalSearchKind.task:
        context.pop();
      case GlobalSearchKind.event:
        context.pop();
      case GlobalSearchKind.budget:
        context.pushNamed('budget');
      case GlobalSearchKind.recurring:
        context.pushNamed('recurring');
    }
  }
}
