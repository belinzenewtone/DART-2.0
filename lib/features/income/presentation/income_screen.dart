import 'package:dart_2_0/core/utils/currency_formatter.dart';
import 'package:dart_2_0/core/widgets/error_message.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/income/domain/entities/income_item.dart';
import 'package:dart_2_0/features/income/presentation/providers/income_providers.dart';
import 'package:dart_2_0/features/income/presentation/widgets/income_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesState = ref.watch(incomesProvider);
    final writeState = ref.watch(incomeWriteControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    ref.listen<AsyncValue<void>>(incomeWriteControllerProvider,
        (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income update failed')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: writeState.isLoading
            ? null
            : () async {
                final input = await showIncomeDialog(context);
                if (input == null) {
                  return;
                }
                await ref
                    .read(incomeWriteControllerProvider.notifier)
                    .addIncome(
                      title: input.title,
                      amountKes: input.amountKes,
                      receivedAt: input.receivedAt,
                    );
              },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: incomesState.when(
            data: (incomes) {
              if (incomes.isEmpty) {
                return const GlassCard(child: Text('No income records yet'));
              }
              final total =
                  incomes.fold<double>(0, (sum, item) => sum + item.amountKes);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        Text('Total Income', style: textTheme.titleMedium),
                        const Spacer(),
                        Text(CurrencyFormatter.money(total),
                            style: textTheme.titleMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: incomes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = incomes[index];
                        return _IncomeRow(
                          item: item,
                          busy: writeState.isLoading,
                          onEdit: () async {
                            final input = await showIncomeDialog(
                              context,
                              initialTitle: item.title,
                              initialAmount: item.amountKes,
                              initialDate: item.receivedAt,
                            );
                            if (input == null) {
                              return;
                            }
                            await ref
                                .read(incomeWriteControllerProvider.notifier)
                                .updateIncome(
                                  incomeId: item.id,
                                  title: input.title,
                                  amountKes: input.amountKes,
                                  receivedAt: input.receivedAt,
                                );
                          },
                          onDelete: () async {
                            await ref
                                .read(incomeWriteControllerProvider.notifier)
                                .deleteIncome(item.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ErrorMessage(
              label: 'Unable to load incomes',
              onRetry: () => ref.invalidate(incomesProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final IncomeItem item;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          const CircleAvatar(
            child: Icon(Icons.account_balance_wallet_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: textTheme.bodyLarge),
                Text(
                  '${item.receivedAt.year}-${item.receivedAt.month.toString().padLeft(2, '0')}-${item.receivedAt.day.toString().padLeft(2, '0')}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(CurrencyFormatter.money(item.amountKes),
              style: textTheme.bodyLarge),
          IconButton(
            onPressed: busy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: busy ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
