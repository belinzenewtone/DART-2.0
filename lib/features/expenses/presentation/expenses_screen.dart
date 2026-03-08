import 'package:beltech/core/widgets/action_button.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expense_dialogs.dart';
import 'package:beltech/features/expenses/presentation/widgets/expenses_snapshot_content.dart';
import 'package:beltech/features/expenses/presentation/widgets/sms_import_dialogs.dart';
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
    final contentSwitchDuration =
        AppMotion.duration(context, normalMs: 180, reducedMs: 0);
    final snapshotChild = snapshotState.when(
      data: (snapshot) => KeyedSubtree(
        key: const ValueKey<String>('expenses-data'),
        child: ExpensesSnapshotContent(
          snapshot: snapshot,
          selectedFilter: selectedFilter,
          busy: writeState.isLoading,
          onFilterChanged: (filter) {
            ref.read(expenseFilterProvider.notifier).state = filter;
          },
          onEditExpense: (expense) async {
            final updated =
                await showEditExpenseDialog(context, expense: expense);
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
      ),
      loading: () => const KeyedSubtree(
        key: ValueKey<String>('expenses-loading'),
        child: Center(child: LoadingIndicator()),
      ),
      error: (_, __) => KeyedSubtree(
        key: const ValueKey<String>('expenses-error'),
        child: ErrorMessage(
          label: 'Unable to load expenses',
          onRetry: () => ref.invalidate(expensesSnapshotProvider),
        ),
      ),
    );
    ref.listen<AsyncValue<void>>(expenseWriteControllerProvider,
        (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        AppFeedback.success(context, 'Expense changes saved successfully.');
      } else if (next.hasError) {
        AppFeedback.error(context, 'Unable to save expense changes.');
      }
    });
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: AppSpacing.screenPadding(
              context,
              bottom: AppSpacing.contentBottomSafe + 20,
            ),
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
                                  AppFeedback.info(context, label);
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
                                AppFeedback.info(context, label);
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
                  duration: contentSwitchDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: snapshotChild,
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: AppSpacing.fabBottom(context),
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
