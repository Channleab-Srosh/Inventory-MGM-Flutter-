import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/core/theme/app_theme.dart';

/// Stock Movement Chart (fl_chart) showing 7-day Stock In vs Stock Out.
class DashboardStockChart extends StatelessWidget {
  final List<double> stockIn;
  final List<double> stockOut;

  const DashboardStockChart({
    super.key,
    required this.stockIn,
    required this.stockOut,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d).substring(0, 2);
    });

    final maxVal = [
      ...stockIn,
      ...stockOut,
      10.0,
    ].reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _ChartLegend(label: 'Stock In', color: AppColors.success),
                SizedBox(width: 16),
                _ChartLegend(label: 'Stock Out', color: AppColors.danger),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxVal * 1.25).ceilToDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final type =
                            rod.color == AppColors.success ? 'In' : 'Out';
                        return BarTooltipItem(
                          '$type: ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i >= 0 && i < dayLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                dayLabels[i],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        ((maxVal * 1.25) / 3).ceilToDouble().clamp(1.0, 1000.0),
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final inQty = i < stockIn.length ? stockIn[i] : 0.0;
                    final outQty = i < stockOut.length ? stockOut[i] : 0.0;

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: inQty,
                          color: AppColors.success,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: outQty,
                          color: AppColors.danger,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final String label;
  final Color color;
  const _ChartLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
