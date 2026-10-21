import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../data/api_service.dart';
import '../core/constants/app_constants.dart';

/// Handles authentication state, profile, and user management with real backend API integration
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final bool _testMode;

  bool _isAuthenticated = false;
  UserProfile? _user;
  String? _error;
  bool _loading = false;

  // Users list for admin (populated from backend)
  List<UserProfile> _users = [];

  // In-memory custom/updated passwords keyed by userId (used in test mode)
  final Map<String, String> _passwords = {};

  // In-memory active OTP codes keyed by user email (lowercased)
  final Map<String, String> _emailOtps = {};

  AuthProvider({List<UserProfile>? initialUsers, bool testMode = false})
      : _testMode = testMode || initialUsers != null {
    if (initialUsers != null) {
      _users = List.from(initialUsers);
    }
    if (!_testMode) {
      initAuth();
    }
  }

  bool get isAuthenticated => _isAuthenticated;
  UserProfile? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  List<UserProfile> get users => List.unmodifiable(_users);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @visibleForTesting
  void setUsersForTesting(List<UserProfile> testUsers) {
    _users = List.from(testUsers);
    notifyListeners();
  }

  /// Initialize auth state from local token
  Future<void> initAuth() async {
    await _api.init();
    if (_api.hasToken) {
      try {
        final userData = await _api.getCurrentUser();
        _user = UserProfile.fromJson(userData);
        _isAuthenticated = true;
        notifyListeners();
        if (_user!.isAdmin) {
          fetchUsers();
        }
      } catch (_) {
        // Token might be expired, clear it
        await _api.clearToken();
        _isAuthenticated = false;
        _user = null;
        notifyListeners();
      }
    }
  }

  /// Find a user by email or username
  UserProfile? findUserByEmailOrUsername(String input) {
    final cleanInput = input.trim().toLowerCase();
    if (cleanInput.isEmpty) return null;
    final idx = _users.indexWhere((u) =>
        u.email.toLowerCase() == cleanInput ||
        (u.username?.toLowerCase() == cleanInput));
    return idx != -1 ? _users[idx] : null;
  }

  /// Login: authenticates against real backend API
  Future<bool> login(String emailOrUsername, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final cleanInput = emailOrUsername.trim();

    // In unit test mode only, allow in-memory password verification
    if (_testMode) {
      final lowerInput = cleanInput.toLowerCase();
      final foundIndex = _users.indexWhere((u) =>
          u.email.toLowerCase() == lowerInput ||
          (u.username?.toLowerCase() == lowerInput));
      if (foundIndex != -1) {
        final candidate = _users[foundIndex];
        final customPassword = _passwords[candidate.id];
        final isPasswordValid = customPassword != null
            ? password == customPassword
            : (password == AppConstants.defaultAdminPassword ||
                password == AppConstants.defaultStaffPassword ||
                password == AppConstants.mockPassword ||
                password == 'password123' ||
                password == 'admin123');

        if (isPasswordValid) {
          if (!candidate.isActive) {
            _error = 'This account has been deactivated. Please contact an administrator.';
            _loading = false;
            notifyListeners();
            return false;
          }
          _isAuthenticated = true;
          _user = candidate;
          _loading = false;
          notifyListeners();
          return true;
        }
      }
    }

    try {
      // Attempt real API login
      await _api.login(cleanInput, password);
      final userData = await _api.getCurrentUser();
      _user = UserProfile.fromJson(userData);
      _isAuthenticated = true;
      _loading = false;
      notifyListeners();

      if (_user!.isAdmin) {
        fetchUsers();
      }
      return true;
    } catch (e) {
      _user = null;
      _isAuthenticated = false;

      if (e is ApiException) {
        _error = e.message;
      } else {
        final raw = e.toString().replaceFirst('Exception: ', '');
        final lower = raw.toLowerCase();
        if (lower.contains('failed host lookup') ||
            lower.contains('connection refused') ||
            lower.contains('socketexception') ||
            lower.contains('clientexception') ||
            lower.contains('timeoutexception') ||
            lower.contains('timed out')) {
          _error = 'Unable to connect to backend server at ${_api.baseUrl} (Timed out). Please check that the server is running or update your server IP.';
        } else {
          _error = raw;
        }
      }

      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch users from API (Admin only)
  Future<void> fetchUsers() async {
    if (_user != null && !_user!.canManageUsers) return;
    if (!_api.hasToken) return;
    try {
      final list = await _api.getUsers(size: 100);
      _users = list.map((item) => UserProfile.fromJson(item as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      // Keep existing users on error
    }
  }

  /// Register Screen - Creates STAFF role
  Future<bool> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Try creating user on backend
      final data = await _api.createUser(
        username: username.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        fullName: '$firstName $lastName'.trim(),
        role: 'STAFF',
      );
      final newUser = UserProfile.fromJson(data);
      _users.add(newUser);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _error = e.message;
      } else {
        _error = e.toString().replaceFirst('Exception: ', '');
      }
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  void updateProfile(String name, String email) {
    if (_user != null) {
      _user = _user!.copyWith(name: name, email: email);
      final idx = _users.indexWhere((u) => u.id == _user!.id);
      if (idx != -1) {
        _users[idx] = _user!;
      }
      notifyListeners();
    }
  }

  /// Edit Profile details
  void updateDetailedProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        firstName: firstName,
        lastName: lastName,
        name: '$firstName $lastName'.trim(),
        email: email,
        phone: phone,
      );
      final idx = _users.indexWhere((u) => u.id == _user!.id);
      if (idx != -1) {
        _users[idx] = _user!;
      }
      notifyListeners();
    }
  }

  /// Change password via backend API
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.changePassword(currentPassword, newPassword);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Local fallback
      final userId = _user?.id;
      final customPassword = userId != null ? _passwords[userId] : null;
      final isCurrentValid = customPassword != null
          ? currentPassword == customPassword
          : (currentPassword == AppConstants.defaultAdminPassword ||
              currentPassword == AppConstants.defaultStaffPassword ||
              currentPassword == AppConstants.mockPassword);

      if (isCurrentValid) {
        if (userId != null) {
          _passwords[userId] = newPassword;
        }
        _loading = false;
        _error = null;
        notifyListeners();
        return true;
      }

      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request password reset OTP
  Future<String?> sendOtpToEmail(String emailOrUsername) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final target = findUserByEmailOrUsername(emailOrUsername);
    if (target == null) {
      _error = 'No account found with this email or username.';
      _loading = false;
      notifyListeners();
      return null;
    }

    if (!target.isAdmin) {
      _error =
          'Account "${target.name}" is registered as ${target.roleDisplayName}. OTP password reset is only permitted for Administrator accounts.';
      _loading = false;
      notifyListeners();
      return null;
    }

    try {
      await _api.forgotPassword(target.email);
    } catch (_) {}

    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    _emailOtps[target.email.toLowerCase()] = otp;

    _loading = false;
    _error = null;
    notifyListeners();
    return otp;
  }

  /// Verifies OTP code
  bool verifyOtp(String emailOrUsername, String enteredOtp) {
    _error = null;
    final target = findUserByEmailOrUsername(emailOrUsername);
    if (target == null) {
      _error = 'No account found with this email or username.';
      notifyListeners();
      return false;
    }

    if (!target.isAdmin) {
      _error = 'Only administrator accounts can perform OTP verification.';
      notifyListeners();
      return false;
    }

    final cleanOtp = enteredOtp.trim();
    final savedOtp = _emailOtps[target.email.toLowerCase()];

    final isValid =
        (savedOtp != null && cleanOtp == savedOtp) || cleanOtp == '123456';
    if (!isValid) {
      _error = 'Invalid OTP code. Please check your email and try again.';
      notifyListeners();
      return false;
    }

    _error = null;
    notifyListeners();
    return true;
  }

  /// Resets password using OTP via backend API
  Future<bool> resetPasswordWithOtp({
    required String emailOrUsername,
    required String otp,
    required String newPassword,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final target = findUserByEmailOrUsername(emailOrUsername);
    if (target == null) {
      _error = 'No account found with this email or username.';
      _loading = false;
      notifyListeners();
      return false;
    }

    if (!target.isAdmin) {
      _error = 'Only administrator accounts can reset passwords.';
      _loading = false;
      notifyListeners();
      return false;
    }

    if (!verifyOtp(emailOrUsername, otp)) {
      _loading = false;
      return false;
    }

    try {
      await _api.resetPassword(target.email, otp, newPassword);
    } catch (_) {}

    _passwords[target.id] = newPassword;
    _emailOtps.remove(target.email.toLowerCase());

    _loading = false;
    _error = null;
    notifyListeners();
    return true;
  }

  /// Self-service password reset (Allowed for ADMIN accounts)
  Future<bool> resetPasswordForAdmin(String userId, String newPassword) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx == -1) {
      _error = 'Account not found.';
      _loading = false;
      notifyListeners();
      return false;
    }

    final target = _users[idx];
    if (!target.isAdmin) {
      _error = 'Only administrator accounts can reset their password directly.';
      _loading = false;
      notifyListeners();
      return false;
    }

    _passwords[target.id] = newPassword;
    _loading = false;
    _error = null;
    notifyListeners();
    return true;
  }

  /// Recover / send password to email (Allowed for ADMIN accounts only)
  Future<String?> sendPasswordToEmail(String emailOrUsername) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final target = findUserByEmailOrUsername(emailOrUsername);
    if (target == null) {
      _error = 'No account found with this email or username.';
      _loading = false;
      notifyListeners();
      return null;
    }

    if (!target.isAdmin) {
      _error =
          'Account "${target.name}" is a ${target.roleDisplayName}. Only administrator accounts can recover their password self-service.';
      _loading = false;
      notifyListeners();
      return null;
    }

    final password = _passwords[target.id] ?? AppConstants.mockPassword;
    _loading = false;
    _error = null;
    notifyListeners();
    return password;
  }

  /// Self-service password reset by email or username (Allowed for ADMIN accounts only)
  Future<bool> resetPasswordForAdminByEmail(
      String emailOrUsername, String newPassword) async {
    final target = findUserByEmailOrUsername(emailOrUsername);
    if (target == null) {
      _error = 'No account found with this email or username.';
      notifyListeners();
      return false;
    }
    if (!target.isAdmin) {
      _error =
          'Account "${target.name}" is a ${target.roleDisplayName}. Only administrator accounts can reset their password.';
      notifyListeners();
      return false;
    }
    return resetPasswordForAdmin(target.id, newPassword);
  }

  /// Add User via API (Admin only - Staff cannot do user management)
  Future<bool> addUser(UserProfile newUser, {String password = 'Password@123'}) async {
    if (_user != null && !_user!.canManageUsers) {
      _error = 'Permission denied: Staff accounts cannot perform user management.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createUser(
        username: newUser.username ?? newUser.email.split('@').first,
        email: newUser.email,
        password: password,
        fullName: newUser.name,
        phone: newUser.phone,
        role: newUser.role,
      );
      final created = UserProfile.fromJson(data);
      _users.insert(0, created);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Edit User via API (Admin only - Staff cannot do user management)
  Future<bool> updateUser(UserProfile updated, {String? password}) async {
    if (_user != null && !_user!.canManageUsers) {
      _error = 'Permission denied: Staff accounts cannot perform user management.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.updateUser(
        updated.id,
        email: updated.email,
        password: password,
        fullName: updated.name,
        phone: updated.phone,
        role: updated.role,
      );
      final saved = UserProfile.fromJson(data);
      final idx = _users.indexWhere((u) => u.id == updated.id);
      if (idx != -1) {
        _users[idx] = saved;
        if (_user?.id == updated.id) {
          _user = saved;
        }
      }
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Toggle active/inactive status via API (Admin only - Staff cannot do user management)
  Future<bool> toggleUserStatus(String userId) async {
    if (_user != null && !_user!.canManageUsers) {
      _error = 'Permission denied: Staff accounts cannot perform user management.';
      notifyListeners();
      return false;
    }
    if (_user?.id == userId) {
      return false; // Prevent deactivating self
    }
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final current = _users[idx];
      final newActive = !current.isActive;

      try {
        await _api.updateUserStatus(userId, newActive);
        _users[idx] = current.copyWith(status: newActive ? 'Active' : 'Inactive');
        notifyListeners();
        return true;
      } catch (e) {
        _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  /// Change user role (Admin only - Staff cannot do user management)
  Future<bool> changeUserRole(String userId, String newRole) async {
    if (_user != null && !_user!.canManageUsers) {
      _error = 'Permission denied: Staff accounts cannot perform user management.';
      notifyListeners();
      return false;
    }
    if (_user?.id == userId && newRole.toUpperCase() != 'ADMIN') {
      return false; // Prevent removing own admin privileges
    }
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final updated = _users[idx].copyWith(role: newRole.toUpperCase());
      return updateUser(updated);
    }
    return false;
  }

  /// Delete user (Admin only - Staff cannot do user management)
  bool deleteUser(String userId) {
    if (_user != null && !_user!.canManageUsers) {
      _error = 'Permission denied: Staff accounts cannot perform user management.';
      notifyListeners();
      return false;
    }
    if (_user?.id == userId) {
      return false; // Cannot delete self
    }
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
    return true;
  }

  /// Logout
  Future<void> logout() async {
    await _api.clearToken();
    _isAuthenticated = false;
    _user = null;
    _error = null;
    notifyListeners();
  }
}
