import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/stock_movement.dart';
import 'widgets/movement_detail_card.dart';
import 'widgets/history_filter_sheet.dart';

/// Stock History Screen with minimalist header and pill filter UI
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

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

    final grouped = <String, List<StockMovement>>{};
    for (final m in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final hPad = AppResponsive.screenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppResponsive.contentMaxWidth(context)),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                  child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
                        ),
                      ),
                    ),
                  const Expanded(
                    child: Text(
                      'Stock History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  // Search circle button
                  GestureDetector(
                    onTap: () => setState(() => _showSearch = !_showSearch),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _showSearch ? AppColors.primaryActive : AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _showSearch
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _showSearch ? AppColors.primaryDark : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter circle button with badge dot
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      GestureDetector(
                        onTap: () => _showFilterSheet(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: hasActiveFilters ? AppColors.primaryActive : AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasActiveFilters
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: hasActiveFilters ? AppColors.primaryDark : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.outOfStockText,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Inline search field
            if (_showSearch) ...[
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: SearchField(
                  controller: _searchCtrl,
                  hint: 'Search product, user, or reference...',
                  onChanged: stock.setSearch,
                ),
              ),
            ],

            // Active filter pill banner
            if (hasActiveFilters)
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryActive,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filtered results (${filtered.length} transactions)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          stock.clearFilters();
                          _searchCtrl.clear();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: stock.isLoading && stock.allMovements.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDark,
                        strokeWidth: 3,
                      ),
                    )
                  : stock.error != null && stock.allMovements.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: AppColors.outOfStockBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline_rounded,
                                      size: 32,
                                      color: AppColors.outOfStockText,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  stock.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () => stock.fetchMovements(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryActive,
                                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                    ),
                                    child: const Text(
                                      'Retry',
                                      style: TextStyle(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => stock.fetchMovements(),
                          color: AppColors.primaryDark,
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
                                  padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 88),
                                  itemCount: sortedKeys.length,
                                  itemBuilder: (_, dayIdx) {
                                    final key = sortedKeys[dayIdx];
                                    final movements = grouped[key]!;
                                    final date = DateTime.parse(key);

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Date header pill
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryActive,
                                                  borderRadius: BorderRadius.circular(
                                                      AppTheme.pillRadius),
                                                ),
                                                child: Text(
                                                  _formatDateHeader(date),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primaryDark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Divider(
                                                  color: AppColors.border,
                                                  thickness: 1,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '${movements.length} record${movements.length > 1 ? "s" : ""}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.secondaryText,
                                                ),
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
      ),
    ),
  ),
);
  }
}
