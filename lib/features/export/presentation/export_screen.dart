import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/export/domain/entities/export_result.dart';
import 'package:dart_2_0/features/export/presentation/providers/export_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportControllerProvider);
    final latestResult = exportState.valueOrNull;

    ref.listen<AsyncValue<ExportResult?>>(exportControllerProvider,
        (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${next.error}'.replaceFirst('Exception: ', ''))),
        );
      } else if (previous is AsyncLoading && next.hasValue) {
        final result = next.valueOrNull;
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported ${result.rowsExported} rows')),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const GlassCard(
              child: Text(
                'Create CSV exports for backup and sharing. Files are saved in the app documents directory.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ExportScope.values
                  .map(
                    (scope) => FilledButton(
                      onPressed: exportState.isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(exportControllerProvider.notifier)
                                  .export(scope);
                            },
                      child: Text(_labelFor(scope)),
                    ),
                  )
                  .toList(),
            ),
            if (latestResult != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Latest Export'),
                    const SizedBox(height: 8),
                    Text('Scope: ${_labelFor(latestResult.scope)}'),
                    Text('Rows: ${latestResult.rowsExported}'),
                    const SizedBox(height: 6),
                    SelectableText(latestResult.filePath),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _labelFor(ExportScope scope) {
    return switch (scope) {
      ExportScope.all => 'Export All',
      ExportScope.expenses => 'Expenses',
      ExportScope.incomes => 'Incomes',
      ExportScope.tasks => 'Tasks',
      ExportScope.events => 'Events',
      ExportScope.budgets => 'Budgets',
      ExportScope.recurring => 'Recurring',
    };
  }
}
