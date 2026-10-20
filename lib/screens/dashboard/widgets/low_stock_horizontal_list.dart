import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/product.dart';

/// Low stock items carousel section for the Dashboard.
class LowStockHorizontalList extends StatelessWidget {
  final ProductProvider products;

  const LowStockHorizontalList({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final lowStockItems = products.lowStockProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Low Stock Alerts',
          trailing: TextButton(
            onPressed: () {
              products.setStatusFilter(StockStatus.lowStock);
              context.go('/products');
            },
            child: const Text('View All →'),
          ),
        ),
        const SizedBox(height: 8),
        if (lowStockItems.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'All products have healthy stock levels',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lowStockItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = lowStockItems[i];
                final isOut = p.stockStatus == StockStatus.outOfStock;
                final badgeColor = isOut ? AppColors.danger : AppColors.warning;
                final statusLabel = isOut ? 'OUT OF STOCK' : 'LOW STOCK';

                return InkWell(
                  onTap: () => context.push('/products/${p.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock: ${p.quantity} ${p.unit} / Min: ${p.minStockLevel} ${p.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
