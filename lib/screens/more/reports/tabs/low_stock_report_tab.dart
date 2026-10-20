import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/product.dart';
import '../widgets/report_header_banner.dart';

/// Low Stock Report Tab
/// Highlights inventory shortages, reorder deficits, and direct restock navigation.
class LowStockReportTab extends StatelessWidget {
  final String periodLabel;

  const LowStockReportTab({
    super.key,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>();
    final lowStockItems = products.lowStockProducts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ReportHeaderBanner(
          title: 'Low Stock Report',
          period: 'Current Inventory Status',
          subtitle: 'Products that have reached or breached their minimum replenishment point',
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Low Stock',
                value: '${products.lowStockCount}',
                icon: Icons.warning_amber_outlined,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Out of Stock',
                value: '${products.outOfStockCount}',
                icon: Icons.cancel_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SectionHeader(
          title: 'Actionable Items (${lowStockItems.length})',
        ),
        const SizedBox(height: 8),
        if (lowStockItems.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.inStock, size: 48),
                    SizedBox(height: 12),
                    Text('No inventory shortages!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('All product quantities exceed minimum required thresholds.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                  ],
                ),
              ),
            ),
          )
        else
          ...lowStockItems.map((p) {
            final cat = categories.findById(p.categoryId);
            final isOut = p.stockStatus == StockStatus.outOfStock;
            final deficit = (p.minStockLevel - p.quantity).clamp(0, 9999);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isOut ? AppColors.danger : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOut ? Icons.error_outline : Icons.warning_amber_outlined,
                    color: isOut ? AppColors.danger : AppColors.warning,
                  ),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: ${cat?.name ?? "General"} · SKU: ${p.sku}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      'Current: ${p.quantity} ${p.unit} | Min Required: ${p.minStockLevel} ${p.unit} (Deficit: $deficit ${p.unit})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOut ? AppColors.danger : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => context.go('/stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.chartIn,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text('Restock', style: TextStyle(fontSize: 12)),
                ),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }
}
