import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';
import 'package:beltech/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:beltech/features/recurring/presentation/widgets/recurring_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesState = ref.watch(recurringTemplatesProvider);
    final writeState = ref.watch(recurringWriteControllerProvider);

    ref.listen<AsyncValue<void>>(recurringWriteControllerProvider,
        (previous, next) {
      if (next.hasError) {
        AppFeedback.error(context, 'Recurring action failed.');
      } else if (previous is AsyncLoading && next is AsyncData<void>) {
        AppFeedback.success(context, 'Recurring template saved successfully.');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring'),
        actions: [
          TextButton.icon(
            onPressed: writeState.isLoading
                ? null
                : () async {
                    final count = await ref
                        .read(recurringWriteControllerProvider.notifier)
                        .materializeNow();
                    if (context.mounted) {
                      AppFeedback.info(context, 'Generated $count item(s).');
                    }
                  },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Now'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: writeState.isLoading
            ? null
            : () async {
                final input = await showRecurringTemplateDialog(context);
                if (input == null) {
                  return;
                }
                await ref
                    .read(recurringWriteControllerProvider.notifier)
                    .addTemplate(
                      kind: input.kind,
                      title: input.title,
                      description: input.description,
                      category: input.category,
                      amountKes: input.amountKes,
                      priority: input.priority,
                      cadence: input.cadence,
                      nextRunAt: input.nextRunAt,
                    );
              },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.sectionPadding(context),
          child: templatesState.when(
            data: (templates) {
              if (templates.isEmpty) {
                return const GlassCard(
                  child: Text('No recurring templates yet'),
                );
              }
              return ListView.separated(
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _RecurringRow(
                    template: template,
                    busy: writeState.isLoading,
                    onDelete: () async {
                      await ref
                          .read(recurringWriteControllerProvider.notifier)
                          .deleteTemplate(template.id);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ErrorMessage(
              label: 'Unable to load recurring templates',
              onRetry: () => ref.invalidate(recurringTemplatesProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.template,
    required this.busy,
    required this.onDelete,
  });

  final RecurringTemplate template;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = template.nextRunAt;
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            child: Icon(_iconFor(template.kind)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.title),
                Text('${template.kind.name} · ${template.cadence.name}'),
                Text(
                  'Next: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                  '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ),
          if (template.amountKes != null)
            Text('KES ${template.amountKes!.toStringAsFixed(2)}'),
          IconButton(
            onPressed: busy ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(RecurringKind kind) {
    return switch (kind) {
      RecurringKind.expense => Icons.receipt_long_outlined,
      RecurringKind.income => Icons.account_balance_wallet_outlined,
      RecurringKind.task => Icons.check_circle_outline,
      RecurringKind.event => Icons.calendar_month_outlined,
    };
  }
}
