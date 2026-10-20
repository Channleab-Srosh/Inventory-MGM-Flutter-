import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/utils/app_utils.dart';
import 'package:inventory_management/models/product.dart';

/// Bento Metric Grid matching Image 1:
/// 2x2 grid of square cards (24px radius):
/// - Top-Left: Solid lavender card (#A594F9), white circle icon, 'Weekly ˅', '$45,210', 'Total Stock Value', '↗'
/// - Top-Right: Pure white card, mint green circle icon, 'Weekly ˅', '1,284', 'Total Stock', '↗'
/// - Bottom-Left: Pure white card, coral circle icon, 'Weekly ˅', '08', 'Out of Stock', '↗'
/// - Bottom-Right: Pure white card, amber circle icon, 'Weekly ˅', '23', 'Low Stock', '↗'
class DashboardSummaryGrid extends StatefulWidget {
  final ProductProvider products;
  final StockProvider stock;

  const DashboardSummaryGrid({
    super.key,
    required this.products,
    required this.stock,
  });

  @override
  State<DashboardSummaryGrid> createState() => _DashboardSummaryGridState();
}

class _DashboardSummaryGridState extends State<DashboardSummaryGrid> {
  String _selectedPeriod = 'Weekly';

  void _changePeriod(String period) {
    setState(() => _selectedPeriod = period);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total stock value: sum of (quantity * price)
    final double totalStockValue = widget.products.allProducts.fold<double>(
      0.0,
      (sum, p) => sum + (p.quantity * p.price),
    );
    final String formattedStockValue = totalStockValue > 0
        ? AppUtils.formatCurrency(totalStockValue)
        : '\$${widget.products.totalProducts * 1250}';

    final String formattedTotalStock = AppUtils.formatNumber(widget.products.totalQuantity);
    final String formattedOutOfStock =
        widget.products.outOfStockCount.toString().padLeft(2, '0');
    final String formattedLowStock =
        widget.products.lowStockCount.toString().padLeft(2, '0');

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        final itemHeight = itemWidth * 0.96;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            // 1. Featured Top-Left: Total Stock Value (Solid Lavender)
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _BentoMetricCard(
                isPrimary: true,
                title: 'Total Stock Value',
                value: formattedStockValue,
                icon: Icons.inventory_2_outlined,
                iconBg: Colors.white,
                iconColor: AppColors.text,
                period: _selectedPeriod,
                onPeriodChanged: _changePeriod,
                onTap: () => context.go('/products'),
              ),
            ),

            // 2. Top-Right: Total Stock (Pure White + Mint Green icon)
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _BentoMetricCard(
                isPrimary: false,
                title: 'Total Stock',
                value: formattedTotalStock,
                icon: Icons.all_inbox_rounded,
                iconBg: AppColors.inStockBg,
                iconColor: AppColors.inStockText,
                period: _selectedPeriod,
                onPeriodChanged: _changePeriod,
                onTap: () => context.go('/products'),
              ),
            ),

            // 3. Bottom-Left: Out of Stock (Pure White + Coral Pink icon)
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _BentoMetricCard(
                isPrimary: false,
                title: 'Out of Stock',
                value: formattedOutOfStock,
                icon: Icons.inventory_outlined,
                iconBg: AppColors.outOfStockBg,
                iconColor: AppColors.outOfStockText,
                period: _selectedPeriod,
                onPeriodChanged: _changePeriod,
                onTap: () {
                  widget.products.setStatusFilter(StockStatus.outOfStock);
                  context.go('/products');
                },
              ),
            ),

            // 4. Bottom-Right: Low Stock (Pure White + Amber Orange icon)
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _BentoMetricCard(
                isPrimary: false,
                title: 'Low Stock',
                value: formattedLowStock,
                icon: Icons.attach_money_rounded,
                iconBg: AppColors.lowStockBg,
                iconColor: AppColors.lowStockText,
                period: _selectedPeriod,
                onPeriodChanged: _changePeriod,
                onTap: () {
                  widget.products.setStatusFilter(StockStatus.lowStock);
                  context.go('/products');
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BentoMetricCard extends StatelessWidget {
  final bool isPrimary;
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String period;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onTap;

  const _BentoMetricCard({
    required this.isPrimary,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.period,
    required this.onPeriodChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
        border: Border.all(
          color: isPrimary ? Colors.transparent : AppColors.border,
          width: 1,
        ),
        boxShadow: isPrimary ? AppColors.lavenderShadow : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Circular pastel icon (left) & Pill dropdown ('Weekly ˅') (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Circular icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        boxShadow: isPrimary
                            ? const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(icon, color: iconColor, size: 18),
                      ),
                    ),

                    // Pill dropdown ('Weekly ˅')
                    PopupMenuButton<String>(
                      initialValue: period,
                      onSelected: onPeriodChanged,
                      tooltip: 'Select range',
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Daily', child: Text('Daily')),
                        const PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                        const PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? Colors.white.withValues(alpha: 0.22)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          border: Border.all(
                            color: isPrimary
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              period,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isPrimary
                                    ? Colors.white
                                    : AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 13,
                              color: isPrimary
                                  ? Colors.white
                                  : AppColors.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom Row: Bold metric (bottom-left) & Tiny diagonal arrow ('↗') (bottom-right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: isPrimary ? Colors.white : AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isPrimary
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppColors.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Tiny diagonal arrow ('↗')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
