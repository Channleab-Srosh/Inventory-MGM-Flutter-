import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// App-wide constants
class AppConstants {
  // App info
  static const appName = 'Inventory Manager';
  static const appVersion = '1.0.0';

  // API Configuration
  static const hostWifiIp = '192.168.45.68';
  static const defaultPort = '8080';

  static const List<String> candidateBaseUrls = [
    'http://localhost:8080/api/v1',
    'http://192.168.45.68:8080/api/v1',
    'http://10.0.2.2:8080/api/v1',
  ];

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    try {
      if (Platform.isAndroid) return 'http://192.168.45.68:8080/api/v1';
    } catch (_) {}
    return 'http://localhost:8080/api/v1';
  }

  // Default low stock threshold
  static const defaultLowStockThreshold = 10;

  // Currency
  static const defaultCurrency = 'USD';
  static const defaultCurrencySymbol = '\$';

  // Route names (used by go_router)
  static const routeLogin = '/login';
  static const routeDashboard = '/dashboard';
  static const routeProducts = '/products';
  static const routeProductDetail = '/products/:id';
  static const routeAddProduct = '/products/add';
  static const routeStock = '/stock';
  static const routeReports = '/reports';
  static const routeProfile = '/profile';
  static const routeHistory = '/history';
  static const routeMore = '/more';
  static const routeCategories = '/more/categories';
  static const routeSuppliers = '/more/suppliers';
  static const routeUsers = '/more/users';
  static const routeSettings = '/more/settings';

  // Real backend credentials
  static const defaultAdminUsername = 'admin';
  static const defaultAdminPassword = 'Admin@12345';
  static const defaultStaffUsername = 'staff';
  static const defaultStaffPassword = 'Staff@12345';

  // Legacy/Fallback mock credentials
  static const mockEmail = 'admin@inventory.com';
  static const mockPassword = 'password123';
  static const mockUserName = 'System Administrator';
  static const mockUserRole = 'Admin';
}
