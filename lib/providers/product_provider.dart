import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../data/api_service.dart';

/// Manages product list with real backend fetching, search/filter, and CRUD support
class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Product> _products = [];
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  StockStatus? _statusFilter;
  bool _isLoading = false;
  String? _error;
  UserProfile? _currentUser;

  // Server dashboard summary metrics (optional cache)
  Map<String, dynamic>? _serverSummary;

  ProductProvider({UserProfile? currentUser}) : _currentUser = currentUser {
    if (_api.hasToken) {
      fetchProducts();
    }
  }

  void updateUser(UserProfile? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clear() {
    _products = [];
    _serverSummary = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ---- Getters ----
  UserProfile? get currentUser => _currentUser;
  List<Product> get filteredProducts => _applyFilters();
  List<Product> get allProducts => List.unmodifiable(_products);
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedSupplierId => _selectedSupplierId;
  StockStatus? get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---- Summary stats ----
  int get totalProducts => _serverSummary != null && _serverSummary!['totalProducts'] != null
      ? (_serverSummary!['totalProducts'] as num).toInt()
      : _products.length;

  int get totalQuantity => _serverSummary != null && _serverSummary!['totalStockQuantity'] != null
      ? (_serverSummary!['totalStockQuantity'] as num).toInt()
      : _products.fold(0, (s, p) => s + p.quantity);

  int get lowStockCount => _serverSummary != null && _serverSummary!['lowStockCount'] != null
      ? (_serverSummary!['lowStockCount'] as num).toInt()
      : _products.where((p) => p.stockStatus == StockStatus.lowStock).length;

  int get outOfStockCount => _serverSummary != null && _serverSummary!['outOfStockCount'] != null
      ? (_serverSummary!['outOfStockCount'] as num).toInt()
      : _products.where((p) => p.stockStatus == StockStatus.outOfStock).length;

  double get totalStockValue => _serverSummary != null && _serverSummary!['totalInventoryValue'] != null
      ? (_serverSummary!['totalInventoryValue'] as num).toDouble()
      : _products.fold(0.0, (s, p) => s + p.price * p.quantity);

  List<Product> get lowStockProducts => _products
      .where((p) =>
          p.stockStatus == StockStatus.lowStock ||
          p.stockStatus == StockStatus.outOfStock)
      .toList();

  /// Fetch products from backend API
  Future<void> fetchProducts() async {
    if (!_api.hasToken) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getProducts(size: 100);
      _products = list.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();

      // Also try fetching server summary metrics
      try {
        _serverSummary = await _api.getDashboardSummary();
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ---- Filter / search ----
  List<Product> _applyFilters() {
    var list = List<Product>.from(_products);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              (p.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (_selectedSupplierId != null) {
      list = list.where((p) => p.supplierId == _selectedSupplierId).toList();
    }
    if (_statusFilter != null) {
      list = list.where((p) => p.stockStatus == _statusFilter).toList();
    }
    return list;
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSupplierFilter(String? supplierId) {
    _selectedSupplierId = supplierId;
    notifyListeners();
  }

  void setStatusFilter(StockStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedSupplierId = null;
    _statusFilter = null;
    notifyListeners();
  }

  // ---- CRUD ----
  Product? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add product via API
  Future<Product?> addProduct(Product product) async {
    if (_currentUser != null && !_currentUser!.canManageProducts) {
      _error = 'Permission denied: Staff accounts have view-only access to products.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createProduct(
        sku: product.sku,
        name: product.name,
        description: product.description,
        categoryId: product.categoryId,
        supplierId: product.supplierId,
        unitOfMeasure: _normalizeUnit(product.unit),
        unitPrice: product.price,
        minimumStock: product.minStockLevel,
        active: product.status.toLowerCase() == 'active',
      );

      final created = Product.fromJson(data);

      // If initial quantity is greater than 0, perform an initial stock-in
      if (product.quantity > 0) {
        try {
          await _api.stockIn(
            productId: created.id,
            quantity: product.quantity,
            note: 'Initial stock on creation',
          );
          created.quantity = product.quantity;
        } catch (_) {}
      }

      _products.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Update product via API
  Future<bool> updateProduct(Product updated) async {
    if (_currentUser != null && !_currentUser!.canManageProducts) {
      _error = 'Permission denied: Staff accounts have view-only access to products.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.updateProduct(
        updated.id,
        sku: updated.sku,
        name: updated.name,
        description: updated.description,
        categoryId: updated.categoryId,
        supplierId: updated.supplierId,
        unitOfMeasure: _normalizeUnit(updated.unit),
        unitPrice: updated.price,
        minimumStock: updated.minStockLevel,
        active: updated.status.toLowerCase() == 'active',
      );

      final saved = Product.fromJson(data);
      // Preserve current quantity if backend didn't return updated quantity
      saved.quantity = updated.quantity;

      final idx = _products.indexWhere((p) => p.id == updated.id);
      if (idx >= 0) {
        _products[idx] = saved;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Delete product via API
  Future<bool> deleteProduct(String id) async {
    if (_currentUser != null && !_currentUser!.canManageProducts) {
      _error = 'Permission denied: Staff accounts have view-only access to products.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle status via API
  Future<bool> toggleProductStatus(String id) async {
    if (_currentUser != null && !_currentUser!.canManageProducts) {
      _error = 'Permission denied: Staff accounts have view-only access to products.';
      notifyListeners();
      return false;
    }

    final idx = _products.indexWhere((p) => p.id == id);
    if (idx < 0) return false;

    final current = _products[idx];
    final newActive = current.status.toLowerCase() != 'active';

    try {
      await _api.updateProductStatus(id, newActive);
      _products[idx] = current.copyWith(
        status: newActive ? 'Active' : 'Inactive',
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update quantity after a stock movement
  void adjustQuantity(String productId, int delta) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx >= 0) {
      final p = _products[idx];
      final newQty = (p.quantity + delta).clamp(0, 999999);
      _products[idx] = p.copyWith(quantity: newQty);
      notifyListeners();
    }
  }

  String _normalizeUnit(String? unit) {
    if (unit == null || unit.isEmpty) return 'PCS';
    final upper = unit.trim().toUpperCase();
    const valid = ['PCS', 'BOX', 'PACK', 'BOTTLE', 'CAN', 'KG', 'LITER'];
    if (valid.contains(upper)) return upper;
    return 'PCS';
  }

  String generateId() => 'p${DateTime.now().millisecondsSinceEpoch}';
}
