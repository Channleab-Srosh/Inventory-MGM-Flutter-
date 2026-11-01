import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventory_management/providers/settings_provider.dart';
import 'package:inventory_management/core/services/report_data_service.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/inventory_report.dart';
import '../widgets/report_header_banner.dart';

/// Stock Summary Report Tab
/// Catalog health, unit totals, inventory valuation, category breakdown and
/// status distribution for products updated inside the selected period.
class StockSummaryReportTab extends StatefulWidget {
  final DateTimeRange dateRange;
  final String periodLabel;

  const StockSummaryReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
  });

  @override
  State<StockSummaryReportTab> createState() => _StockSummaryReportTabState();
}

class _StockSummaryReportTabState extends State<StockSummaryReportTab> {
  InventorySummaryReport? _summary; // calculated by the server
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StockSummaryReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Period changed (Today / This Week / This Month / Custom): reload
    if (oldWidget.dateRange != widget.dateRange) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final summary =
          await ReportDataService.fetchInventorySummary(widget.dateRange);
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  PieChartSectionData _section(int value, Color color, bool compact) {
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      title: '$value',
      radius: compact ? 35 : 45,
      titleStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final header = ReportHeaderBanner(
      title: 'Stock Summary Report',
      period: widget.periodLabel,
      subtitle: 'Products updated in this period: catalog health and stock levels',
    );

    if (_loading && _summary == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header,
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_failed || _summary == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header,
          const SizedBox(height: 24),
          const Center(child: Text('Could not load the report.')),
          Center(
            child: TextButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }

    // Totals and category breakdown come from GET /reports/inventory/summary
    final summary = _summary!;
    final totalItems = summary.totalItems;
    final totalUnits = summary.totalUnits;
    final totalVal = summary.totalInventoryValuation;
    final inStockCount = summary.inStockCount;
    final lowStockCount = summary.lowStockCount;
    final outOfStockCount = summary.outOfStockCount;

    // Largest valuation first
    final categories = [...summary.categoryBreakdown]
      ..sort((a, b) => b.totalValuation.compareTo(a.totalValuation));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header,
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Total Items',
                  value: '$totalItems',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  title: 'Total Units',
                  value: '$totalUnits',
                  icon: Icons.layers_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SummaryCard(
            title: 'Total Inventory Valuation',
            value: AppUtils.formatCurrency(totalVal,
                symbol: settings.currencySymbol),
            icon: Icons.attach_money,
            color: AppColors.inStock,
          ),
          const SizedBox(height: 20),

          if (totalItems == 0)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No products were updated in this period.'),
                ),
              ),
            )
          else ...[
            const SectionHeader(title: 'Stock Status Distribution'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;

                    final pieWidget = SizedBox(
                      height: isCompact ? 160 : 180,
                      width: isCompact ? 160 : 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: isCompact ? 35 : 45,
                          sections: [
                            if (inStockCount > 0)
                              _section(inStockCount, AppColors.inStock, isCompact),
                            if (lowStockCount > 0)
                              _section(lowStockCount, AppColors.warning, isCompact),
                            if (outOfStockCount > 0)
                              _section(outOfStockCount, AppColors.danger, isCompact),
                          ],
                        ),
                      ),
                    );

                    final legendWidget = Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                            'In Stock ($inStockCount)', AppColors.inStock),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                            'Low Stock ($lowStockCount)', AppColors.warning),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                            'Out of Stock ($outOfStockCount)', AppColors.danger),
                      ],
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          pieWidget,
                          const SizedBox(height: 16),
                          legendWidget,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        pieWidget,
                        const SizedBox(width: 20),
                        Expanded(child: legendWidget),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            const SectionHeader(title: 'Category Stock Breakdown'),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) {
                  final c = categories[i];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.category_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    title: Text(c.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${c.totalItems} items · ${c.totalUnits} units'),
                    trailing: Text(
                      AppUtils.formatCurrency(c.totalValuation,
                          symbol: settings.currencySymbol),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}