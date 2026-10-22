import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/providers/settings_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/product.dart';
import '../widgets/report_header_banner.dart';

/// Stock Summary Report Tab
/// Displays catalog health, unit totals, inventory valuation, category breakdown, and status distribution chart.
class StockSummaryReportTab extends StatelessWidget {
  final DateTimeRange dateRange;
  final String periodLabel;

  const StockSummaryReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>().allCategories;
    final settings = context.watch<SettingsProvider>();

    final inStockCount = products.allProducts
        .where((p) => p.stockStatus == StockStatus.inStock)
        .length;
    final lowStockCount = products.allProducts
        .where((p) => p.stockStatus == StockStatus.lowStock)
        .length;
    final outOfStockCount = products.allProducts
        .where((p) => p.stockStatus == StockStatus.outOfStock)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportHeaderBanner(
          title: 'Stock Summary Report',
          period: periodLabel,
          subtitle: 'Complete overview of catalog health and stock levels',
        ),
        const SizedBox(height: 16),

        // Summary metric cards
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Items',
                value: '${products.totalProducts}',
                icon: Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Units in Stock',
                value: AppUtils.formatNumber(products.totalQuantity),
                icon: Icons.layers_outlined,
                color: AppColors.inStock,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Inventory Value',
                value: AppUtils.formatCurrency(products.totalStockValue,
                    symbol: settings.currencySymbol),
                icon: Icons.attach_money,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Needs Reorder',
                value: '${lowStockCount + outOfStockCount}',
                icon: Icons.warning_amber_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Stock Health Chart
        const SectionHeader(title: 'Stock Health Distribution'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pieWidget = SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: [
                        if (inStockCount > 0)
                          PieChartSectionData(
                            color: AppColors.inStock,
                            value: inStockCount.toDouble(),
                            radius: 20,
                            showTitle: false,
                          ),
                        if (lowStockCount > 0)
                          PieChartSectionData(
                            color: AppColors.warning,
                            value: lowStockCount.toDouble(),
                            radius: 20,
                            showTitle: false,
                          ),
                        if (outOfStockCount > 0)
                          PieChartSectionData(
                            color: AppColors.danger,
                            value: outOfStockCount.toDouble(),
                            radius: 20,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                );

                final legendWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportLegendItem(
                      label: 'In Stock',
                      count: inStockCount,
                      color: AppColors.inStock,
                    ),
                    const SizedBox(height: 8),
                    ReportLegendItem(
                      label: 'Low Stock',
                      count: lowStockCount,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 8),
                    ReportLegendItem(
                      label: 'Out of Stock',
                      count: outOfStockCount,
                      color: AppColors.danger,
                    ),
                  ],
                );

                if (constraints.maxWidth < 340) {
                  return Column(
                    children: [
                      Center(child: pieWidget),
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
    );
  }
}
