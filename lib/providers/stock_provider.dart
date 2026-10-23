import 'package:flutter/foundation.dart';
import '../models/stock_movement.dart';
import '../models/user_profile.dart';
import '../data/api_service.dart';

/// Manages stock movements (in/out history) with real backend API integration
class StockProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  String? _error;
  UserProfile? _currentUser;

  // Filter state
  String _search = '';
  MovementType? _typeFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _productFilter;
  String? _userFilter;

  StockProvider({UserProfile? currentUser}) : _currentUser = currentUser {
    if (_api.hasToken) {
      fetchMovements();
    }
  }

  void updateUser(UserProfile? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clear() {
    _movements = [];
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _totalElements = 0;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Pagination state
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _totalElements = 0;

  List<StockMovement> get allMovements => List.unmodifiable(_movements);
  List<StockMovement> get filteredMovements => _applyFilters();
  String get search => _search;
  MovementType? get typeFilter => _typeFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get productFilter => _productFilter;
  String? get userFilter => _userFilter;
  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get currentPage => _currentPage;
  int get totalElements => _totalElements;

  /// Fetch movements from API
  Future<void> fetchMovements({bool reset = true}) async {
    if (!_api.hasToken) return;
    if (reset) {
      _currentPage = 0;
      _hasMore = true;
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final paged = await _api.getStockHistoryPaged(
        productId: _productFilter,
        type: _typeFilter != null
            ? (_typeFilter == MovementType.stockIn ? 'STOCK_IN' : 'STOCK_OUT')
            : null,
        userId: _userFilter,
        fromDate: _startDate,
        toDate: _endDate,
        page: 0,
        size: _pageSize,
      );

      _movements = paged.items
          .map((item) => StockMovement.fromJson(item))
          .toList();
      _currentPage = paged.page;
      _hasMore = !paged.last;
      _totalElements = paged.totalElements;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Load next page for infinite scrolling
  Future<void> loadMoreMovements() async {
    if (!_api.hasToken || !_hasMore || _isLoadingMore || _isLoading) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paged = await _api.getStockHistoryPaged(
        productId: _productFilter,
        type: _typeFilter != null
            ? (_typeFilter == MovementType.stockIn ? 'STOCK_IN' : 'STOCK_OUT')
            : null,
        userId: _userFilter,
        fromDate: _startDate,
        toDate: _endDate,
        page: nextPage,
        size: _pageSize,
      );

      final newItems = paged.items
          .map((item) => StockMovement.fromJson(item))
          .toList();
      _movements.addAll(newItems);
      _currentPage = paged.page;
      _hasMore = !paged.last;
      _totalElements = paged.totalElements;
      _isLoadingMore = false;
      notifyListeners();
    } catch (_) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch stock transactions report from ReportController: GET /reports/stock-transactions
  Future<List<StockMovement>> fetchTransactionReport({
    String? productId,
    String? type,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final list = await _api.getStockTransactionReport(
        productId: productId,
        type: type,
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
        size: 100,
      );
      return list
          .map((item) => StockMovement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return getMovementsBetween(
        fromDate ?? DateTime(2000),
        toDate ?? DateTime.now(),
        type: type != null
            ? (type.contains('IN') ? MovementType.stockIn : MovementType.stockOut)
            : null,
      );
    }
  }

  /// Perform Stock In via API
  Future<StockMovement?> recordStockIn({
    required String productId,
    required int quantity,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.stockIn(
        productId: productId,
        quantity: quantity,
        note: note,
      );
      final movement = StockMovement.fromJson(data);
      _movements.insert(0, movement);
      _isLoading = false;
      notifyListeners();
      return movement;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Perform Stock Out via API (Blocked for Staff accounts)
  Future<StockMovement?> recordStockOut({
    required String productId,
    required int quantity,
    String? note,
  }) async {
    if (_currentUser != null && !_currentUser!.canStockOut) {
      final msg = 'Permission denied: ${_currentUser!.roleDisplayName} accounts are not authorized to perform stock out.';
      _error = msg;
      notifyListeners();
      throw Exception(msg);
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.stockOut(
        productId: productId,
        quantity: quantity,
        note: note,
      );
      final movement = StockMovement.fromJson(data);
      _movements.insert(0, movement);
      _isLoading = false;
      notifyListeners();
      return movement;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Today metrics for dashboard
  int get stockInToday {
    final now = DateTime.now();
    return _movements
        .where((m) =>
            m.type == MovementType.stockIn &&
            m.date.year == now.year &&
            m.date.month == now.month &&
            m.date.day == now.day)
        .fold<int>(0, (sum, m) => sum + m.quantity);
  }

  int get stockOutToday {
    final now = DateTime.now();
    return _movements
        .where((m) =>
            m.type == MovementType.stockOut &&
            m.date.year == now.year &&
            m.date.month == now.month &&
            m.date.day == now.day)
        .fold<int>(0, (sum, m) => sum + m.quantity);
  }

  /// Last 6 movements for dashboard
  List<StockMovement> get recentMovements {
    final sorted = List<StockMovement>.from(_movements)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(6).toList();
  }

  /// Recent transactions for stock screen (last 10)
  List<StockMovement> get recentTransactions {
    final sorted = List<StockMovement>.from(_movements)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  List<StockMovement> _applyFilters() {
    var list = List<StockMovement>.from(_movements);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((m) =>
              m.productName.toLowerCase().contains(q) ||
              (m.reference?.toLowerCase().contains(q) ?? false) ||
              (m.userName.toLowerCase().contains(q)))
          .toList();
    }
    if (_typeFilter != null) {
      list = list.where((m) => m.type == _typeFilter).toList();
    }
    if (_startDate != null) {
      final s = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      list = list.where((m) => !m.date.isBefore(s)).toList();
    }
    if (_endDate != null) {
      final e = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      list = list.where((m) => !m.date.isAfter(e)).toList();
    }
    if (_productFilter != null && _productFilter!.isNotEmpty) {
      list = list.where((m) => m.productId == _productFilter).toList();
    }
    if (_userFilter != null && _userFilter!.isNotEmpty) {
      list = list.where((m) => m.userId == _userFilter).toList();
    }
    // Sort newest first
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  void setTypeFilter(MovementType? t) {
    if (_typeFilter != t) {
      _typeFilter = t;
      fetchMovements(reset: true);
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    if (_startDate != start || _endDate != end) {
      _startDate = start;
      _endDate = end;
      fetchMovements(reset: true);
    }
  }

  void setProductFilter(String? id) {
    if (_productFilter != id) {
      _productFilter = id;
      fetchMovements(reset: true);
    }
  }

  void setUserFilter(String? id) {
    if (_userFilter != id) {
      _userFilter = id;
      fetchMovements(reset: true);
    }
  }

  void clearFilters() {
    _search = '';
    _typeFilter = null;
    _startDate = null;
    _endDate = null;
    _productFilter = null;
    _userFilter = null;
    fetchMovements(reset: true);
  }

  /// Add a new movement locally and return it
  StockMovement addMovement(StockMovement movement) {
    _movements.insert(0, movement);
    notifyListeners();
    return movement;
  }

  String generateId() => 'm${DateTime.now().millisecondsSinceEpoch}';

  /// Stock movements for a specific product
  List<StockMovement> movementsForProduct(String productId) {
    return _movements
        .where((m) => m.productId == productId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ---- Dynamic Chart data from movements ----
  List<double> get stockInLast7Days => _aggregateByDay(MovementType.stockIn);
  List<double> get stockOutLast7Days => _aggregateByDay(MovementType.stockOut);

  List<double> _aggregateByDay(MovementType type) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _movements
          .where((m) =>
              m.type == type &&
              m.date.year == day.year &&
              m.date.month == day.month &&
              m.date.day == day.day)
          .fold<double>(0, (sum, m) => sum + m.quantity);
    });
  }

  /// Helper for reports: filter movements by arbitrary date range
  List<StockMovement> getMovementsBetween(DateTime start, DateTime end, {MovementType? type}) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _movements.where((m) {
      if (type != null && m.type != type) return false;
      return !m.date.isBefore(s) && !m.date.isAfter(e);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
