import 'dart:io' show Platform;

/// App-wide constants
class AppConstants {
  // App info
  static const appName = 'Inventory Manager';
  static const appVersion = '1.0.0';

  // API Configuration
  // Environment variable override (e.g. `flutter run --dart-define=API_BASE_URL=https://...`)
  static const String envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Current local LAN IP of developer machine
  static const hostWifiIp = '192.168.0.242';
  static const defaultPort = '8080';

  /// Intelligent list of candidate base URLs probed during auto-detection
  static List<String> get candidateBaseUrls {
    final list = <String>[];
    if (envBaseUrl.isNotEmpty) list.add(envBaseUrl);

    // Prioritized Android targets
    list.addAll([
      'http://10.0.2.2:8080/api/v1',       // Android Emulator (Default)
      'http://localhost:8080/api/v1',      // Physical phone with `adb reverse` / test runner
      'http://127.0.0.1:8080/api/v1',      // Physical phone loopback
      'http://192.168.0.242:8080/api/v1',  // Physical phone via host Wi-Fi LAN
      'http://10.0.3.2:8080/api/v1',       // Genymotion emulator loopback
      'http://192.168.45.68:8080/api/v1',  // Fallback LAN IP
    ]);

    return list.toSet().toList();
  }

  /// Default base URL based on platform and environment
  static String get defaultBaseUrl {
    if (envBaseUrl.isNotEmpty) return envBaseUrl;
    try {
      if (Platform.isAndroid) {
        // Android Emulator connects to host computer localhost via 10.0.2.2
        return 'http://10.0.2.2:8080/api/v1';
      }
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
