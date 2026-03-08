import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsBarChart extends StatelessWidget {
  const AnalyticsBarChart({
    super.key,
    required this.title,
    required this.points,
  });

  final String title;
  final List<AnalyticsPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final barColor = theme.colorScheme.primary;
    final axisColor = AppColors.textSecondaryFor(brightness);
    final maxY = _maxY(points);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 1 : maxY * 1.2,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 0 ? 1 : maxY / 3,
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[index].label,
                            style: TextStyle(
                              color: axisColor,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List<BarChartGroupData>.generate(
                  points.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: points[index].amountKes,
                        color: barColor,
                        width: points.length > 12 ? 8 : 12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 420),
            ),
          ),
        ],
      ),
    );
  }

  double _maxY(List<AnalyticsPoint> points) {
    var max = 0.0;
    for (final point in points) {
      if (point.amountKes > max) {
        max = point.amountKes;
      }
    }
    return max;
  }
}
