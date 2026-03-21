import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/expenses_screen_helpers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expense_dialogs.dart';
import 'package:beltech/features/expenses/presentation/widgets/expenses_snapshot_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(expensesSnapshotProvider);
    final selectedFilter = ref.watch(expenseFilterProvider);
    final writeState = ref.watch(expenseWriteControllerProvider);
    final importMetricsState = ref.watch(expenseImportMetricsProvider);
    final reviewQueueState = ref.watch(expenseReviewQueueProvider);
    final quarantineState = ref.watch(expenseQuarantineQueueProvider);
    final paybillProfilesState = ref.watch(expensePaybillProfilesProvider);
    final fulizaLifecycleState = ref.watch(expenseFulizaLifecycleProvider);
    final contentSwitchDuration = AppMotion.duration(
      context,
      normalMs: 180,
      reducedMs: 0,
    );
    final snapshotChild = snapshotState.when(
      data: (snapshot) {
        consumeExpenseSearchTarget(context, ref, snapshot);
        return KeyedSubtree(
          key: const ValueKey<String>('expenses-data'),
          child: ExpensesSnapshotContent(
            snapshot: snapshot,
            selectedFilter: selectedFilter,
            busy: writeState.isLoading,
            onFilterChanged: (filter) {
              ref.read(expenseFilterProvider.notifier).state = filter;
            },
            onEditExpense: (expense) async {
              await editExpenseEntry(context, ref, expense);
            },
            onDeleteExpense: (expense) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .deleteExpense(expense.id);
              if (context.mounted &&
                  !ref.read(expenseWriteControllerProvider).hasError) {
                AppFeedback.success(context, 'Transaction deleted', ref: ref);
              }
            },
            importMetrics: importMetricsState.valueOrNull ??
                const ExpenseImportMetrics(
                  reviewQueueCount: 0,
                  quarantineCount: 0,
                  retryQueueCount: 0,
                  failedQueueCount: 0,
                ),
            reviewItems: reviewQueueState.valueOrNull ?? const [],
            quarantineItems: quarantineState.valueOrNull ?? const [],
            paybillProfiles:
                paybillProfilesState.valueOrNull ?? const <PaybillProfile>[],
            fulizaEvents: fulizaLifecycleState.valueOrNull ??
                const <FulizaLifecycleEvent>[],
            onApproveReview: (item) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .approveReviewItem(item.id);
              if (context.mounted &&
                  !ref.read(expenseWriteControllerProvider).hasError) {
                AppFeedback.success(context, 'Review item approved', ref: ref);
              }
            },
            onRejectReview: (item) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .rejectReviewItem(item.id);
              if (context.mounted &&
                  !ref.read(expenseWriteControllerProvider).hasError) {
                AppFeedback.info(context, 'Review item rejected', ref: ref);
              }
            },
            onDismissQuarantine: (item) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .dismissQuarantineItem(item.id);
              if (context.mounted &&
                  !ref.read(expenseWriteControllerProvider).hasError) {
                AppFeedback.info(
                  context,
                  'Quarantine item dismissed',
                  ref: ref,
                );
              }
            },
            onReplayImportQueue: () async {
              await replayExpenseImportQueue(context, ref);
            },
          ),
        );
      },
      loading: () => const KeyedSubtree(
        key: ValueKey<String>('expenses-loading'),
        child: FinanceSkeletonList(),
      ),
      error: (_, __) => KeyedSubtree(
        key: const ValueKey<String>('expenses-error'),
        child: ErrorMessage(
          label: 'Unable to load expenses',
          onRetry: () => ref.invalidate(expensesSnapshotProvider),
        ),
      ),
    );
    ref.listen<AsyncValue<void>>(expenseWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(
          context,
          'Unable to save transaction. Please try again.',
          ref: ref,
        );
      }
    });
    return PageShell(
      scrollable: false,
      glowColor: AppColors.glowTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            eyebrow: 'MONEY',
            title: 'Finance',
            subtitle: 'Your financial picture',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Import SMS',
                  onPressed: writeState.isLoading
                      ? null
                      : () async => handleExpenseSmsImport(context, ref),
                  icon: const Icon(Icons.file_download_outlined),
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.12),
                  ),
                  child: IconButton(
                    tooltip: 'Add expense',
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
                            if (context.mounted &&
                                !ref
                                    .read(expenseWriteControllerProvider)
                                    .hasError) {
                              AppFeedback.success(
                                context,
                                'Transaction added',
                                ref: ref,
                              );
                            }
                          },
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: contentSwitchDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: snapshotChild,
            ),
          ),
        ],
      ),
    );
  }
}
