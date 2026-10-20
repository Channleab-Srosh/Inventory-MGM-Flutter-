import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/app_components.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import 'widgets/product_filter_sheet.dart';

/// Products list with search, filter chips, slidable actions
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProductProvider>();
      if (p.allProducts.isEmpty) p.fetchProducts();
      final c = context.read<CategoryProvider>();
      if (c.allCategories.isEmpty) c.fetchCategories();
      final s = context.read<SupplierProvider>();
      if (s.allSuppliers.isEmpty) s.fetchSuppliers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilterBottomSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final canViewCategories = auth.user?.canViewCategories ?? true;
    final products = context.read<ProductProvider>();
    final categories = canViewCategories ? context.read<CategoryProvider>().categories : <Category>[];
    final suppliers = context.read<SupplierProvider>().allSuppliers;

    ProductFilterSheet.show(
      context: context,
      initialCategoryId: products.selectedCategoryId,
      initialSupplierId: products.selectedSupplierId,
      initialStatus: products.statusFilter,
      categories: categories,
      suppliers: suppliers,
      onApply: (categoryId, supplierId, status) {
        products.setCategoryFilter(categoryId);
        products.setSupplierFilter(supplierId);
        products.setStatusFilter(status);
      },
    );
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Product',
      message: 'Delete "${product.name}"? This action cannot be undone.',
    );
    if (confirmed && context.mounted) {
      context.read<ProductProvider>().deleteProduct(product.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManageProducts = auth.user?.canManageProducts ?? true;
    final canViewCategories = auth.user?.canViewCategories ?? true;
    final products = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>();
    final filtered = products.filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            tooltip: 'Filter Products',
            onPressed: () => _openFilterBottomSheet(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search products, SKU...',
              onChanged: products.setSearch,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                AppFilterChip(
                  label: 'All',
                  selected: products.selectedCategoryId == null &&
                      products.statusFilter == null &&
                      products.selectedSupplierId == null,
                  onSelected: () => products.clearFilters(),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Low Stock',
                  selected: products.statusFilter == StockStatus.lowStock,
                  onSelected: () =>
                      products.setStatusFilter(StockStatus.lowStock),
                  color: AppColors.lowStock,
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Out of Stock',
                  selected: products.statusFilter == StockStatus.outOfStock,
                  onSelected: () =>
                      products.setStatusFilter(StockStatus.outOfStock),
                  color: AppColors.outOfStock,
                ),
                const SizedBox(width: 8),
                if (canViewCategories)
                  ...categories.categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppFilterChip(
                          label: cat.name,
                          selected: products.selectedCategoryId == cat.id,
                          onSelected: () => products.setCategoryFilter(cat.id),
                        ),
                      )),
              ],
            ),
          ),

          // List
          Expanded(
            child: products.isLoading && products.allProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : products.error != null && products.allProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text(
                                products.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.danger, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => products.fetchProducts(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await Future.wait([
                            products.fetchProducts(),
                            categories.fetchCategories(),
                          ]);
                        },
                        child: filtered.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  EmptyState(
                                    message: 'No products found',
                                    subtitle: products.searchQuery.isNotEmpty
                                        ? 'Try a different search term'
                                        : 'Add a product using the + button',
                                    icon: Icons.inventory_2_outlined,
                                  ),
                                ],
                              )
                            : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (_, i) {
                      final product = filtered[i];
                      final cat = canViewCategories ? categories.findById(product.categoryId) : null;
                      return Slidable(
                        key: ValueKey(product.id),
                        endActionPane: canManageProducts
                            ? ActionPane(
                                motion: const DrawerMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (_) =>
                                        context.push('/products/edit/${product.id}'),
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit_outlined,
                                    label: 'Edit',
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(12)),
                                  ),
                                  SlidableAction(
                                    onPressed: (_) =>
                                        _deleteProduct(context, product),
                                    backgroundColor: AppColors.outOfStock,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_outlined,
                                    label: 'Delete',
                                    borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(12)),
                                  ),
                                ],
                              )
                            : null,
                        child: ProductCard(
                          product: product,
                          categoryName: canViewCategories
                              ? (cat?.name ?? product.categoryName ?? 'Unknown')
                              : '',
                          onTap: () => context.push('/products/${product.id}'),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: canManageProducts
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/products/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
