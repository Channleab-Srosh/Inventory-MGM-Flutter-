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

/// Dashboard Screen matching Image 1:
/// - Minimalist header: Avatar + "☼ GOOD MORNING! ^-^" + "Mark 👋" (left), "Chat" pill + notification bell with red badge (right)
/// - 2x2 Bento Metric Grid (Lavender Total Stock Value, White Total Stock, Out of Stock, Low Stock)
/// - Stock Flow Chart Card with multi-layered pastel stacked bars and smooth lavender gradient
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

  String _getGreetingTag() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☼ GOOD MORNING! ^-^';
    if (hour < 17) return '☼ GOOD AFTERNOON! ^-^';
    return '☽ GOOD EVENING! ^-^';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final stock = context.watch<StockProvider>();
    final user = auth.user;
    final userName = user?.firstName?.isNotEmpty == true
        ? user!.firstName!
        : (user != null && user.name.isNotEmpty
            ? user.name.split(' ').first
            : 'User');

    final int alertCount = products.lowStockCount + products.outOfStockCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryDark,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            children: [
              // Minimalist Top Header matching Image 1
              Row(
                children: [
                  // User profile avatar
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryActive,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Center(
                        child: Text(
                          user?.initials ?? 'M',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Two-line greeting: "☼ GOOD MORNING! ^-^" + "Mark 👋"
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreetingTag(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '👋',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Pill "Chat" button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support chat coming soon')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x041A1A1A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Chat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Circle notification bell button with red badge dot
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(alertCount > 0
                              ? '$alertCount product(s) currently need attention.'
                              : 'All inventory stock levels are healthy!'),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x041A1A1A),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.notifications_none_rounded,
                              size: 20,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.outOfStockText,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                '${alertCount > 0 ? alertCount : 2}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2x2 Bento Metric Grid matching Image 1
              DashboardSummaryGrid(products: products, stock: stock),

              const SizedBox(height: 18),

              // Stock Flow Chart Card matching Image 1
              DashboardStockChart(
                stockIn: stock.stockInLast7Days,
                stockOut: stock.stockOutLast7Days,
              ),

              const SizedBox(height: 20),

              // Quick action shortcuts
              const DashboardQuickActions(),

              const SizedBox(height: 20),

              // Low stock horizontal list
              LowStockHorizontalList(products: products),

              const SizedBox(height: 20),

              // Recent transactions
              SectionHeader(
                title: 'Recent Transactions',
                trailing: TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text('View All →'),
                ),
              ),
              const SizedBox(height: 8),
              if (stock.recentMovements.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No recent transactions found',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                )
              else
                ...stock.recentMovements.take(5).map(
                  (m) => TransactionTile(movement: m),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
