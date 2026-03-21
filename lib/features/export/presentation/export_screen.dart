import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:beltech/features/export/presentation/providers/export_providers.dart';
import 'package:beltech/features/export/presentation/widgets/export_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportControllerProvider);
    final latestResult = exportState.valueOrNull;

    ref.listen<AsyncValue<ExportResult?>>(exportControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(
          context,
          '${next.error}'.replaceFirst('Exception: ', ''),
        );
      } else if (previous is AsyncLoading && next.hasValue) {
        final result = next.valueOrNull;
        if (result != null) {
          AppFeedback.success(
            context,
            'Export complete: ${result.rowsExported} row(s).',
          );
        }
      }
    });

    return SecondaryPageShell(
      title: 'Export Data',
      glowColor: AppColors.glowBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Export all — prominent full-width card ───────────────────────
          GlassCard(
            tone: GlassCardTone.accent,
            accentColor: AppColors.accent,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export All',
                          style: AppTypography.cardTitle(context)),
                      const SizedBox(height: 2),
                      Text(
                        'One CSV with every data type',
                        style: AppTypography.bodySm(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: exportState.isLoading
                      ? null
                      : () async {
                          final confirmed = await _confirmExport(
                            context,
                            scope: ExportScope.all,
                          );
                          if (confirmed != true) {
                            return;
                          }
                          await ref
                              .read(exportControllerProvider.notifier)
                              .export(ExportScope.all);
                        },
                  child: exportState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Export'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'By Category',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),

          // ── Per-scope cards ──────────────────────────────────────────────
          for (final meta in exportScopeMetas) ...[
            ExportScopeCard(
              meta: meta,
              isLoading: exportState.isLoading,
              isActive: latestResult?.scope == meta.scope,
              rowsExported: latestResult?.scope == meta.scope
                  ? latestResult!.rowsExported
                  : null,
              onExport: () async {
                final confirmed = await _confirmExport(
                  context,
                  scope: meta.scope,
                );
                if (confirmed != true) {
                  return;
                }
                await ref
                    .read(exportControllerProvider.notifier)
                    .export(meta.scope);
              },
            ),
            const SizedBox(height: 8),
          ],

          // ── Latest export result ─────────────────────────────────────────
          if (latestResult != null) ...[
            const SizedBox(height: 8),
            LatestExportCard(
              result: latestResult,
              isLoading: exportState.isLoading,
            ),
          ],

          const SizedBox(height: 8),
          GlassCard(
            tone: GlassCardTone.muted,
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Files are saved as CSV to the app documents directory.',
                    style: AppTypography.bodySm(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> _confirmExport(
  BuildContext context, {
  required ExportScope scope,
}) {
  final label = exportScopeLabel(scope);
  return showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Export $label?'),
      content: Text(
        'This creates a CSV file for $label in the app documents directory. '
        'Continue only if this is the export you want right now.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Export'),
        ),
      ],
    ),
  );
}
