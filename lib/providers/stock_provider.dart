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
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

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

  /// Fetch movements from API
  Future<void> fetchMovements() async {
    if (!_api.hasToken) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getStockHistory(size: 100);
      _movements = list
          .map((item) => StockMovement.fromJson(item as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
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
    _typeFilter = t;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setProductFilter(String? id) {
    _productFilter = id;
    notifyListeners();
  }

  void setUserFilter(String? id) {
    _userFilter = id;
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _typeFilter = null;
    _startDate = null;
    _endDate = null;
    _productFilter = null;
    _userFilter = null;
    notifyListeners();
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
