import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class ExpenseTransactionRow extends StatelessWidget {
  const ExpenseTransactionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onEdit,
    required this.onDelete,
    required this.busy,
  });

  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.accentSoft,
            child: Icon(Icons.more_horiz),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyLarge),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
          Text(amount, style: textTheme.bodyLarge),
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
