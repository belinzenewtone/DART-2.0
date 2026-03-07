import 'package:dart_2_0/core/widgets/action_button.dart';
import 'package:dart_2_0/core/widgets/error_message.dart';
import 'package:dart_2_0/core/widgets/loading_indicator.dart';
import 'package:dart_2_0/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:dart_2_0/features/expenses/presentation/widgets/expense_dialogs.dart';
import 'package:dart_2_0/features/expenses/presentation/widgets/expenses_snapshot_content.dart';
import 'package:dart_2_0/features/expenses/presentation/widgets/sms_import_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final snapshotState = ref.watch(expensesSnapshotProvider);
    final selectedFilter = ref.watch(expenseFilterProvider);
    final writeState = ref.watch(expenseWriteControllerProvider);
    ref.listen<AsyncValue<void>>(expenseWriteControllerProvider,
        (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added')),
        );
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add expense')),
        );
      }
    });
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('Expenses', style: textTheme.titleLarge)),
                    TextButton(
                      onPressed: writeState.isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final method = await showSmsImportMethodDialog(
                                context,
                              );
                              if (method == null) {
                                return;
                              }
                              if (method == SmsImportMethod.deviceInbox) {
                                if (!context.mounted) {
                                  return;
                                }
                                final window = await showSmsWindowDialog(
                                  context,
                                );
                                if (window == null) {
                                  return;
                                }
                                final count = await ref
                                    .read(
                                        expenseWriteControllerProvider.notifier)
                                    .importFromDevice(window: window);
                                if (context.mounted) {
                                  final label = count == 0
                                      ? 'No MPESA messages found in ${importWindowLabel(window)}'
                                      : 'Imported $count MPESA transactions from device';
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(label)),
                                  );
                                }
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }
                              final input = await showSmsImportDialog(context);
                              if (input == null ||
                                  input.payload.trim().isEmpty) {
                                return;
                              }
                              final count = await ref
                                  .read(expenseWriteControllerProvider.notifier)
                                  .importSmsPayload(
                                    input.payload,
                                    window: input.window,
                                  );
                              if (context.mounted) {
                                final label = count == 0
                                    ? 'No MPESA messages found in ${importWindowLabel(input.window)}'
                                    : 'Imported $count MPESA transactions';
                                messenger.showSnackBar(
                                    SnackBar(content: Text(label)));
                              }
                            },
                      child: const Text('Import SMS'),
                    ),
                  ],
                ),
                Text('Track your MPESA transactions',
                    style: textTheme.bodyMedium),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: snapshotState.when(
                    data: (snapshot) => ExpensesSnapshotContent(
                      snapshot: snapshot,
                      selectedFilter: selectedFilter,
                      busy: writeState.isLoading,
                      onFilterChanged: (filter) {
                        ref.read(expenseFilterProvider.notifier).state = filter;
                      },
                      onEditExpense: (expense) async {
                        final updated = await showEditExpenseDialog(context,
                            expense: expense);
                        if (updated == null) {
                          return;
                        }
                        await ref
                            .read(expenseWriteControllerProvider.notifier)
                            .updateExpense(
                              transactionId: expense.id,
                              title: updated.title,
                              category: updated.category,
                              amountKes: updated.amountKes,
                              occurredAt: updated.occurredAt,
                            );
                      },
                      onDeleteExpense: (expense) async {
                        await ref
                            .read(expenseWriteControllerProvider.notifier)
                            .deleteExpense(expense.id);
                      },
                    ),
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (_, __) =>
                        const ErrorMessage(label: 'Unable to load expenses'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 104,
            child: ActionButton(
              icon: Icons.add,
              isLoading: writeState.isLoading,
              onPressed: writeState.isLoading
                  ? null
                  : () async {
                      final input = await showAddExpenseDialog(context);
                      if (input == null) {
                        return;
                      }
                      await ref
                          .read(expenseWriteControllerProvider.notifier)
                          .addExpense(
                            title: input.title,
                            category: input.category,
                            amountKes: input.amountKes,
                            occurredAt: input.occurredAt,
                          );
                    },
            ),
          ),
        ],
      ),
    );
  }
}
