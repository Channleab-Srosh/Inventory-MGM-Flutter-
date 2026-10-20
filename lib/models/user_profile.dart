/// User profile model for authentication and User Management
class UserProfile {
  final String id;
  String name;
  String email;
  String role;
  String? username;
  String? firstName;
  String? lastName;
  String? phone;
  String status;
  String? avatarUrl;
  DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.username,
    this.firstName,
    this.lastName,
    this.phone,
    this.status = 'Active',
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    if (username == null || username!.isEmpty) {
      username = email.contains('@') ? email.split('@').first : email;
    }
    if (firstName == null && lastName == null) {
      final parts = name.trim().split(' ');
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName']?.toString() ?? json['name']?.toString() ?? '';
    final active = json['active'] as bool?;
    String status = 'Active';
    if (active != null) {
      status = active ? 'Active' : 'Inactive';
    } else if (json['status'] != null) {
      status = json['status'].toString();
    }

    // Role handling (strip "ROLE_" if present)
    String role = json['role']?.toString().toUpperCase() ?? 'STAFF';
    if (role.startsWith('ROLE_')) {
      role = role.substring(5);
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: fullName,
      email: json['email']?.toString() ?? '',
      role: role,
      username: json['username']?.toString(),
      phone: json['phone']?.toString(),
      status: status,
      avatarUrl: json['avatarUrl']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
      'name': name,
      'email': email,
      'role': role,
      'username': username,
      'phone': phone,
      'active': status.toLowerCase() == 'active',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static const String roleAdmin = 'ADMIN';
  static const String roleWarehouseManager = 'WAREHOUSE_MANAGER';
  static const String roleStaff = 'STAFF';

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isWarehouseManager =>
      role.toUpperCase() == 'WAREHOUSE_MANAGER' ||
      role.toUpperCase() == 'WAREHOUSE MANAGER';
  bool get isStaff => role.toUpperCase() == 'STAFF';
  bool get isActive => status.toLowerCase() == 'active';

  /// Role-based permissions
  /// Staff cannot manage users.
  bool get canManageUsers => isAdmin && !isStaff;
  bool get canStockOut => true; // Staff, Warehouse Manager, and Admin can all perform stock out
  bool get canStockIn => true;

  /// Supplier permissions: Staff cannot add/edit/delete suppliers (view only)
  bool get canManageSuppliers => !isStaff && (isAdmin || isWarehouseManager);
  bool get canViewSuppliers => true;

  /// Category permissions: Staff cannot see/add/edit/delete categories
  bool get canViewCategories => !isStaff && (isAdmin || isWarehouseManager);
  bool get canManageCategories => !isStaff && (isAdmin || isWarehouseManager);

  /// Product permissions: Staff cannot add/edit/delete products (view only)
  bool get canManageProducts => !isStaff && (isAdmin || isWarehouseManager);
  bool get canViewProducts => true;

  /// Human-friendly display label for the role
  String get roleDisplayName {
    if (isAdmin) return 'Admin';
    if (isWarehouseManager) return 'Warehouse Manager';
    if (isStaff) return 'Staff';
    return role;
  }

  /// Uppercase badge title for the role
  String get roleBadgeLabel {
    if (isAdmin) return 'ADMIN';
    if (isWarehouseManager) return 'WAREHOUSE MANAGER';
    if (isStaff) return 'STAFF';
    return role.toUpperCase();
  }

  /// Avatar initials for display
  String get initials {
    if (firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? role,
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    String? status,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
