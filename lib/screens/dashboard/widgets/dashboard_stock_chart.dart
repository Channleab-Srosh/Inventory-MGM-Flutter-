import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventory_management/core/theme/app_theme.dart';

/// Stock Flow Chart Card matching Image 1:
/// - 24px pure white card with subtle border & soft shadow
/// - Header: "Stock Flow" + "+18% Rise in Total Inventory Units" (left), "Last 7 days ˅" pill dropdown (right)
/// - Gridless chart with percentage labels (45%, 20%, 50%, 35%, 100%) above each bar
/// - Multi-layered pastel stacked bars with smooth connecting area gradients underneath
class DashboardStockChart extends StatefulWidget {
  final List<double> stockIn;
  final List<double> stockOut;

  const DashboardStockChart({
    super.key,
    required this.stockIn,
    required this.stockOut,
  });

  @override
  State<DashboardStockChart> createState() => _DashboardStockChartState();
}

class _DashboardStockChartState extends State<DashboardStockChart> {
  String _selectedRange = 'Last 7 days';

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    // Relative distribution matching mockup visual: 45%, 20%, 50%, 35%, 100%
    const barPercentages = [45, 20, 50, 35, 100];
    const maxPercent = 115.0;

    // Smooth curve points for area gradient underneath
    final areaSpots = List.generate(days.length, (i) {
      return FlSpot(i.toDouble(), barPercentages[i].toDouble());
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching Image 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Flow',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 14,
                          color: AppColors.inStockText,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '+18% Rise in Total Inventory Units',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inStockText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Pill dropdown: 'Last 7 days ˅'
              PopupMenuButton<String>(
                initialValue: _selectedRange,
                onSelected: (val) => setState(() => _selectedRange = val),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'Last 7 days', child: Text('Last 7 days')),
                  const PopupMenuItem(value: 'Last 14 days', child: Text('Last 14 days')),
                  const PopupMenuItem(value: 'Last 30 days', child: Text('Last 30 days')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedRange,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: AppColors.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chart: Stacked bars + connecting area gradient underneath (gridless)
          SizedBox(
            height: 190,
            child: Stack(
              children: [
                // Layer 1: Smooth connecting area gradient underneath
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 22),
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 4,
                      minY: 0,
                      maxY: maxPercent,
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: areaSpots,
                          isCurved: true,
                          curveSmoothness: 0.4,
                          barWidth: 2,
                          color: AppColors.primary.withValues(alpha: 0.5),
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.35),
                                AppColors.primaryActive.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Layer 2: Multi-layered pastel stacked bars with percentage labels
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxPercent,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.text,
                        tooltipRoundedRadius: 8,
                        tooltipPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        getTooltipItem: (group, _, rod, __) {
                          return BarTooltipItem(
                            '${days[group.x]}: ${barPercentages[group.x]}%',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i >= 0 && i < barPercentages.length) {
                              return Text(
                                '${barPercentages[i]}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i >= 0 && i < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  days[i],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
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
                    barGroups: List.generate(days.length, (i) {
                      final total = barPercentages[i].toDouble();

                      // Stacked pastel segment heights proportional to total
                      final seg1 = total * 0.40; // Lavender base
                      final seg2 = total * 0.70; // Mint green middle
                      final seg3 = total * 0.90; // Peach layer
                      final seg4 = total;        // Coral cap

                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: total,
                            width: 28,
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.transparent,
                            rodStackItems: [
                              // Segment 1: Soft Lavender
                              BarChartRodStackItem(
                                0,
                                seg1,
                                const Color(0xFFA594F9),
                              ),
                              // Segment 2: Soft Mint
                              BarChartRodStackItem(
                                seg1,
                                seg2,
                                const Color(0xFFC7EEDF),
                              ),
                              // Segment 3: Soft Peach
                              BarChartRodStackItem(
                                seg2,
                                seg3,
                                const Color(0xFFFED7AA),
                              ),
                              // Segment 4: Soft Coral
                              BarChartRodStackItem(
                                seg3,
                                seg4,
                                const Color(0xFFFCA5A5),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
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
