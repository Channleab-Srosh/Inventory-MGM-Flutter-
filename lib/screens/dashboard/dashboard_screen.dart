import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/transaction_tile.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_summary_grid.dart';
import 'widgets/low_stock_horizontal_list.dart';
import 'widgets/dashboard_stock_chart.dart';

/// Features 4 & 5: Mobile Dashboard matching Notion specifications
/// Metrics: Total Products, Total Stock Quantity, Low Stock, Out of Stock, Stock In Today, Stock Out Today
/// Plus: Quick Actions, Recent Transactions, Low Stock Horizontal List, Stock Movement Chart
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final products = context.read<ProductProvider>();
    final stock = context.read<StockProvider>();
    final categories = context.read<CategoryProvider>();
    final suppliers = context.read<SupplierProvider>();

    await Future.wait([
      products.fetchProducts(),
      stock.fetchMovements(),
      categories.fetchCategories(),
      suppliers.fetchSuppliers(),
    ]);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final stock = context.watch<StockProvider>();
    final theme = Theme.of(context);
    final user = auth.user;
    final userName = user?.firstName?.isNotEmpty == true
        ? user!.firstName!
        : (user?.name ?? 'User');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_getGreeting()}, $userName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 6),
                Builder(builder: (context) {
                  final Color roleColor = user?.isAdmin == true
                      ? AppColors.primary
                      : (user?.isWarehouseManager == true
                          ? const Color(0xFFD97706)
                          : const Color(0xFF0EA5E9));
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user?.roleBadgeLabel ?? 'STAFF',
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
            Text(
              "Today's Inventory Overview",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Stock History',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              final count = products.lowStockCount + products.outOfStockCount;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(count > 0
                      ? '$count product(s) currently need replenishment attention.'
                      : 'All inventory stock levels are healthy!'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if ((products.error != null && products.allProducts.isEmpty) ||
                (stock.error != null && stock.allMovements.isEmpty))
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        products.error ?? stock.error ?? 'Failed to load inventory data.',
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Quick action shortcuts
            const DashboardQuickActions(),
            const SizedBox(height: 16),

            // Summary Grid: Total Products, Stock, Low Stock, Out of Stock, In Today, Out Today
            DashboardSummaryGrid(products: products, stock: stock),
            const SizedBox(height: 20),

            // Low Stock Carousel
            LowStockHorizontalList(products: products),
            const SizedBox(height: 20),

            // Stock Movement Chart (fl_chart)
            const SectionHeader(title: 'Stock Movement (Last 7 Days)'),
            const SizedBox(height: 10),
            DashboardStockChart(
              stockIn: stock.stockInLast7Days,
              stockOut: stock.stockOutLast7Days,
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            SectionHeader(
              title: 'Recent Transactions',
              trailing: TextButton(
                onPressed: () => context.push('/history'),
                child: const Text('View All →'),
              ),
            ),
            const SizedBox(height: 8),
            if (stock.recentMovements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No recent transactions found',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              )
            else
              ...stock.recentMovements.map(
                (m) => TransactionTile(movement: m),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
