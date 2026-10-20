import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/stock_movement.dart';
import 'widgets/movement_detail_card.dart';
import 'widgets/history_filter_sheet.dart';

/// Features 10, 11, 12: Stock History Screen
/// Records Date, Product, Type, Qty, Before, After, User
/// Users can filter by: Product, Transaction Type, Date From, Date To, User
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stock = context.read<StockProvider>();
      if (stock.allMovements.isEmpty) stock.fetchMovements();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    final stock = context.read<StockProvider>();
    final products = context.read<ProductProvider>().allProducts;
    final users = context.read<AuthProvider>().users;

    HistoryFilterSheet.show(
      context: context,
      currentType: stock.typeFilter,
      currentStart: stock.startDate,
      currentEnd: stock.endDate,
      currentProduct: stock.productFilter,
      currentUser: stock.userFilter,
      products: products,
      users: users,
      onApply: (type, start, end, productId, userId) {
        stock.setTypeFilter(type);
        stock.setDateRange(start, end);
        stock.setProductFilter(productId);
        stock.setUserFilter(userId);
        Navigator.pop(context);
      },
      onClear: () {
        stock.clearFilters();
        _searchCtrl.clear();
        Navigator.pop(context);
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    final filtered = stock.filteredMovements;
    final hasActiveFilters = stock.typeFilter != null ||
        stock.startDate != null ||
        stock.endDate != null ||
        stock.productFilter != null ||
        stock.userFilter != null;

    // Group movements by date string
    final grouped = <String, List<StockMovement>>{};
    for (final m in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Transaction History'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter History',
                onPressed: () => _showFilterSheet(context),
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search product, user, or reference...',
              onChanged: stock.setSearch,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Active filter chip row if any
          if (hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered results (${filtered.length} transactions)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      stock.clearFilters();
                      _searchCtrl.clear();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                    ),
                    child: const Text('Clear all', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: stock.isLoading && stock.allMovements.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : stock.error != null && stock.allMovements.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text(
                                stock.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.danger, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => stock.fetchMovements(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => stock.fetchMovements(),
                        child: filtered.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  EmptyState(
                                    message: 'No transaction history found',
                                    icon: Icons.history,
                                    subtitle:
                                        'Try adjusting your search terms or filter criteria',
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                                itemCount: sortedKeys.length,
                                itemBuilder: (_, dayIdx) {
                                  final key = sortedKeys[dayIdx];
                                  final movements = grouped[key]!;
                                  final date = DateTime.parse(key);

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Sticky date header
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _formatDateHeader(date),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Divider(
                                                  color: AppColors.grey200, thickness: 1),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${movements.length} record${movements.length > 1 ? "s" : ""}',
                                              style: const TextStyle(
                                                  fontSize: 11, color: AppColors.grey500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...movements.map(
                                        (m) => MovementDetailCard(movement: m),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
