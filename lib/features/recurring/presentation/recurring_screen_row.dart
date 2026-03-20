part of 'recurring_screen.dart';

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.template,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTemplate template;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = template.nextRunAt;
    final typeColor = AppColors.categoryColorFor(template.category ?? 'other');

    return GlassCard(
      tone: GlassCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: AppTypography.cardTitle(context),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppCapsule(
                          label: template.kind.name,
                          color: typeColor,
                          variant: AppCapsuleVariant.subtle,
                          size: AppCapsuleSize.sm,
                        ),
                        const SizedBox(width: 8),
                        AppCapsule(
                          label: template.cadence.name,
                          color: AppColors.slate,
                          variant: AppCapsuleVariant.subtle,
                          size: AppCapsuleSize.sm,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (template.amountKes != null)
                Text(
                  CurrencyFormatter.money(template.amountKes!),
                  style: AppTypography.amount(context),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Next: ${DateFormat('MMM d, yyyy HH:mm').format(date)}',
                  style: AppTypography.bodySm(context),
                ),
              ),
              IconButton(
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                iconSize: 20,
              ),
              IconButton(
                onPressed: busy ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
