import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_spending_cards_balance.dart';
part 'home_spending_cards_insights.dart';

class HomeSpendSnapshotStrip extends StatelessWidget {
  const HomeSpendSnapshotStrip({super.key, required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    // Determine month approximation since data layer doesn't expose it directly yet
    final approxMonthKes = overview.weekKes * 4.2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildColumn(context, 'Today', overview.todayKes),
          _buildDivider(),
          _buildColumn(context, 'Week', overview.weekKes),
          _buildDivider(),
          _buildColumn(context, 'Month', approxMonthKes),
        ],
      ),
    );
  }

  Widget _buildColumn(BuildContext context, String label, double amount) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.bodySm(context)
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.money(amount),
              style: AppTypography.bodyMd(context).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.border.withValues(alpha: 0.5),
    );
  }
}

/// Single transaction row used in the dashboard recent transactions list.
class HomeDashboardTransactionTile extends StatelessWidget {
  const HomeDashboardTransactionTile({super.key, required this.tx});
  final HomeTransaction tx;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(tx.category);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visual.background,
              shape: BoxShape.circle,
            ),
            child: Icon(visual.icon, color: visual.foreground, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: AppTypography.cardTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  tx.category,
                  style: AppTypography.bodySm(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.money(tx.amountKes),
            style: AppTypography.bodyMd(context)
                .copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ],
      ),
    );
  }
}
