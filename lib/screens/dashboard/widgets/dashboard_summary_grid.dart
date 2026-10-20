import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/product.dart';

/// 6 Summary Cards for Dashboard:
/// Total Products, Total Stock, Low Stock, Out of Stock, Stock In Today, Stock Out Today
class DashboardSummaryGrid extends StatelessWidget {
  final ProductProvider products;
  final StockProvider stock;

  const DashboardSummaryGrid({
    super.key,
    required this.products,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        final cards = [
          SummaryCard(
            title: 'Total Products',
            value: '${products.totalProducts}',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
            onTap: () => context.go('/products'),
          ),
          SummaryCard(
            title: 'Total Stock',
            value: AppUtils.formatNumber(products.totalQuantity),
            icon: Icons.layers_outlined,
            color: AppColors.inStock,
            onTap: () => context.go('/products'),
          ),
          SummaryCard(
            title: 'Low Stock',
            value: '${products.lowStockCount}',
            icon: Icons.warning_amber_outlined,
            color: AppColors.warning,
            onTap: () {
              products.setStatusFilter(StockStatus.lowStock);
              context.go('/products');
            },
          ),
          SummaryCard(
            title: 'Out of Stock',
            value: '${products.outOfStockCount}',
            icon: Icons.cancel_outlined,
            color: AppColors.danger,
            onTap: () {
              products.setStatusFilter(StockStatus.outOfStock);
              context.go('/products');
            },
          ),
          SummaryCard(
            title: 'Stock In Today',
            value: '+${stock.stockInToday}',
            icon: Icons.arrow_downward,
            color: AppColors.chartIn,
            onTap: () => context.go('/stock'),
          ),
          SummaryCard(
            title: 'Stock Out Today',
            value: '-${stock.stockOutToday}',
            icon: Icons.arrow_upward,
            color: AppColors.chartOut,
            onTap: () => context.go('/stock'),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }
}
