import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/product.dart';
import 'package:inventory_management/models/inventory_report.dart';
import '../widgets/report_header_banner.dart';

/// Low Stock Report Tab
/// Highlights inventory shortages, reorder deficits, and direct restock navigation backed by ReportController.
class LowStockReportTab extends StatefulWidget {
  final String periodLabel;

  const LowStockReportTab({
    super.key,
    required this.periodLabel,
  });

  @override
  State<LowStockReportTab> createState() => _LowStockReportTabState();
}

class _LowStockReportTabState extends State<LowStockReportTab> {
  List<InventoryReportItem>? _reportItems;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    final products = context.read<ProductProvider>();
    final items = await products.fetchInventoryReport(lowStockOnly: true);
    if (mounted) {
      setState(() {
        _reportItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>();

    final lowStockCount = _reportItems != null
        ? _reportItems!.where((i) => i.isLowStock || i.isOutOfStock).length
        : products.lowStockCount;
    final outOfStockCount = _reportItems != null
        ? _reportItems!.where((i) => i.isOutOfStock).length
        : products.outOfStockCount;

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
                value: '$lowStockCount',
                icon: Icons.warning_amber_outlined,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Out of Stock',
                value: '$outOfStockCount',
                icon: Icons.cancel_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SectionHeader(
          title: 'Actionable Items (${_reportItems?.length ?? products.lowStockProducts.length})',
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if ((_reportItems != null && _reportItems!.isEmpty) ||
            (_reportItems == null && products.lowStockProducts.isEmpty))
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
        else if (_reportItems != null)
          ..._reportItems!.map((p) {
            final isOut = p.isOutOfStock;
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
                    Text('Category: ${p.categoryName} · SKU: ${p.sku}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      'Current: ${p.quantity} | Min Required: ${p.minStockLevel} (Deficit: $deficit)',
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
          })
        else
          ...products.lowStockProducts.map((p) {
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
