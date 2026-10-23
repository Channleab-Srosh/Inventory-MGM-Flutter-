import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/settings_provider.dart';
import 'package:inventory_management/data/api_service.dart';
import 'package:inventory_management/models/dashboard_summary.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/product.dart';
import '../widgets/report_header_banner.dart';

/// Stock Summary Report Tab
/// Displays catalog health, unit totals, inventory valuation, category breakdown, and status distribution chart.
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
  final ApiService _api = ApiService();
  DashboardSummary? _backendSummary;

  @override
  void initState() {
    super.initState();
    _loadBackendSummary();
  }

  Future<void> _loadBackendSummary() async {
    try {
      final data = await _api.getDashboardSummary();
      if (mounted) {
        setState(() {
          _backendSummary = DashboardSummary.fromJson(data);
        });
      }
    } catch (_) {
      // Keep local state if backend call fails
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>().allCategories;
    final settings = context.watch<SettingsProvider>();

    final inStockCount = _backendSummary != null
        ? (_backendSummary!.totalProducts - _backendSummary!.lowStockCount - _backendSummary!.outOfStockCount).clamp(0, 999999)
        : products.allProducts
            .where((p) => p.stockStatus == StockStatus.inStock)
            .length;
    final lowStockCount = _backendSummary != null
        ? _backendSummary!.lowStockCount
        : products.allProducts
            .where((p) => p.stockStatus == StockStatus.lowStock)
            .length;
    final outOfStockCount = _backendSummary != null
        ? _backendSummary!.outOfStockCount
        : products.allProducts
            .where((p) => p.stockStatus == StockStatus.outOfStock)
            .length;

    final totalItems = _backendSummary != null ? _backendSummary!.totalProducts : products.totalProducts;
    final totalUnits = _backendSummary != null ? _backendSummary!.totalStockQuantity : products.totalQuantity;
    final totalVal = _backendSummary != null ? _backendSummary!.totalInventoryValue : products.totalStockValue;

    return RefreshIndicator(
      onRefresh: _loadBackendSummary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReportHeaderBanner(
            title: 'Stock Summary Report',
            period: widget.periodLabel,
            subtitle: 'Complete overview of catalog health and stock levels',
          ),
          const SizedBox(height: 16),

          // Summary metric cards
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

          // Stock Status Pie Chart
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
                            PieChartSectionData(
                              value: inStockCount.toDouble(),
                              color: AppColors.inStock,
                              title: '$inStockCount',
                              radius: isCompact ? 35 : 45,
                              titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          if (lowStockCount > 0)
                            PieChartSectionData(
                              value: lowStockCount.toDouble(),
                              color: AppColors.warning,
                              title: '$lowStockCount',
                              radius: isCompact ? 35 : 45,
                              titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          if (outOfStockCount > 0)
                            PieChartSectionData(
                              value: outOfStockCount.toDouble(),
                              color: AppColors.danger,
                              title: '$outOfStockCount',
                              radius: isCompact ? 35 : 45,
                              titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );

                  final legendWidget = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        'In Stock ($inStockCount)',
                        AppColors.inStock,
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'Low Stock ($lowStockCount)',
                        AppColors.warning,
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'Out of Stock ($outOfStockCount)',
                        AppColors.danger,
                      ),
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

          // Breakdown by Category
          const SectionHeader(title: 'Category Stock Breakdown'),
          const SizedBox(height: 8),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final catProducts =
                    products.allProducts.where((p) => p.categoryId == cat.id).toList();
                final catQty = catProducts.fold<int>(0, (s, p) => s + p.quantity);
                final catVal =
                    catProducts.fold<double>(0.0, (s, p) => s + p.price * p.quantity);

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
                  title: Text(cat.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${catProducts.length} items · $catQty units'),
                  trailing: Text(
                    AppUtils.formatCurrency(catVal,
                        symbol: settings.currencySymbol),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
