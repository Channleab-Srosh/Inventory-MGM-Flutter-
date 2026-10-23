import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/models/product.dart';
import 'package:inventory_management/models/category.dart';
import 'package:inventory_management/models/supplier.dart';
import 'package:inventory_management/models/stock_movement.dart';
import 'package:inventory_management/models/user_profile.dart';
import 'package:inventory_management/providers/auth_provider.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/providers/product_provider.dart';
import 'package:inventory_management/providers/supplier_provider.dart';
import 'package:inventory_management/providers/category_provider.dart';
import 'package:inventory_management/screens/dashboard/widgets/dashboard_quick_actions.dart';
import 'package:inventory_management/screens/stock/stock_screen.dart';
import 'package:inventory_management/screens/more/more_screen.dart';
import 'package:inventory_management/screens/more/suppliers_screen.dart';
import 'package:inventory_management/screens/products/products_screen.dart';

final _testUsers = [
  UserProfile(
    id: 'u1',
    name: 'System Administrator',
    email: 'admin@inventory.com',
    role: UserProfile.roleAdmin,
    username: 'admin',
    status: 'Active',
  ),
  UserProfile(
    id: 'u2',
    name: 'Bona Keo',
    email: 'warehouse@inventory.com',
    role: UserProfile.roleWarehouseManager,
    username: 'warehouse',
    status: 'Active',
  ),
  UserProfile(
    id: 'u3',
    name: 'Inventory Staff',
    email: 'staff@inventory.com',
    role: UserProfile.roleStaff,
    username: 'staff',
    status: 'Active',
  ),
];

void main() {
  group('Warehouse Manager Role Tests', () {
    test('Warehouse manager profile getters and formatting', () {
      final manager = UserProfile(
        id: 'u_mgr',
        name: 'Bona Keo',
        email: 'warehouse@inventory.com',
        role: UserProfile.roleWarehouseManager,
      );

      expect(manager.isAdmin, isFalse);
      expect(manager.isWarehouseManager, isTrue);
      expect(manager.isStaff, isFalse);
      expect(manager.roleDisplayName, equals('Warehouse Manager'));
      expect(manager.roleBadgeLabel, equals('WAREHOUSE MANAGER'));
    });

    test('Test data includes warehouse manager user', () {
      final warehouseMgr = _testUsers.firstWhere((u) => u.isWarehouseManager);
      expect(warehouseMgr.email, equals('warehouse@inventory.com'));
      expect(warehouseMgr.role, equals('WAREHOUSE_MANAGER'));
    });
  });

  group('Product Measurement Unit Tests', () {
    test('Product supports custom and common units', () {
      final canProduct = Product(
        id: 'p_can',
        name: 'Coca Cola',
        sku: 'CC-CAN',
        categoryId: 'cat_drinks',
        supplierId: 'sup0',
        price: 0.75,
        quantity: 55,
        minStockLevel: 20,
        unit: 'can',
      );

      final kgProduct = Product(
        id: 'p_kg',
        name: 'Coffee Beans',
        sku: 'COFFEE-KG',
        categoryId: 'cat_food',
        supplierId: 'sup1',
        price: 25.0,
        quantity: 12,
        minStockLevel: 5,
        unit: 'kg',
      );

      expect(canProduct.quantityWithUnit, equals('55 can'));
      expect(canProduct.minStockWithUnit, equals('20 can'));
      expect(kgProduct.quantityWithUnit, equals('12 kg'));
      expect(kgProduct.minStockWithUnit, equals('5 kg'));
      expect(Product.commonUnits.contains('can'), isTrue);
      expect(Product.commonUnits.contains('kg'), isTrue);
    });

    test('StockMovement includes unit', () {
      final movement = StockMovement(
        id: 'm_test',
        productId: 'p_can',
        productName: 'Coca Cola',
        type: MovementType.stockIn,
        quantity: 24,
        unit: 'can',
        userId: 'u1',
        userName: 'Dara',
        date: DateTime.now(),
      );

      expect(movement.unit, equals('can'));
      expect(movement.formattedQuantity, equals('24 can'));
    });
  });

  group('Admin Forgot & Reset Password Tests', () {
    AuthProvider createTestAuth() => AuthProvider(initialUsers: _testUsers);

    test('findUserByEmailOrUsername correctly identifies users and roles', () {
      final auth = createTestAuth();

      // Admin user lookup by email (with mixed case / whitespace)
      final adminByEmail = auth.findUserByEmailOrUsername('  ADMIN@INVENTORY.COM ');
      expect(adminByEmail, isNotNull);
      expect(adminByEmail!.isAdmin, isTrue);
      expect(adminByEmail.email, equals('admin@inventory.com'));

      // Admin user lookup by username
      final adminByUsername = auth.findUserByEmailOrUsername('admin');
      expect(adminByUsername, isNotNull);
      expect(adminByUsername!.isAdmin, isTrue);

      // Warehouse Manager lookup
      final warehouseMgr = auth.findUserByEmailOrUsername('warehouse@inventory.com');
      expect(warehouseMgr, isNotNull);
      expect(warehouseMgr!.isWarehouseManager, isTrue);
      expect(warehouseMgr.isAdmin, isFalse);

      // Staff lookup
      final staffUser = auth.findUserByEmailOrUsername('staff@inventory.com');
      expect(staffUser, isNotNull);
      expect(staffUser!.isStaff, isTrue);
      expect(staffUser.isAdmin, isFalse);

      // Non-existent user
      final unknown = auth.findUserByEmailOrUsername('unknown@random.com');
      expect(unknown, isNull);

      final empty = auth.findUserByEmailOrUsername('   ');
      expect(empty, isNull);
    });

    test('Admin self-service password reset succeeds and updates credentials', () async {
      final auth = createTestAuth();
      final admin = auth.findUserByEmailOrUsername('admin@inventory.com')!;
      expect(admin.isAdmin, isTrue);

      // Reset password for Admin
      final success = await auth.resetPasswordForAdmin(admin.id, 'NewAdminSecret999!');
      expect(success, isTrue);
      expect(auth.error, isNull);

      // Attempt login with wrong/old password
      final failLogin = await auth.login('admin@inventory.com', 'wrongpassword');
      expect(failLogin, isFalse);
      expect(auth.isAuthenticated, isFalse);

      // Attempt login with newly reset password
      final successLogin = await auth.login('admin@inventory.com', 'NewAdminSecret999!');
      expect(successLogin, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.email, equals('admin@inventory.com'));
    });

    test('Non-admin users are blocked from admin password reset', () async {
      final auth = createTestAuth();

      // Warehouse Manager
      final warehouseUser = auth.findUserByEmailOrUsername('warehouse@inventory.com')!;
      expect(warehouseUser.isWarehouseManager, isTrue);
      final wmResult = await auth.resetPasswordForAdmin(warehouseUser.id, 'NewPass123!');
      expect(wmResult, isFalse);
      expect(auth.error, contains('Only administrator accounts can reset their password directly'));

      // Staff
      final staffUser = auth.findUserByEmailOrUsername('staff@inventory.com')!;
      expect(staffUser.isStaff, isTrue);
      final staffResult = await auth.resetPasswordForAdmin(staffUser.id, 'NewPass123!');
      expect(staffResult, isFalse);
      expect(auth.error, contains('Only administrator accounts can reset their password directly'));
    });

    test('Reset password fails gracefully for non-existent user id', () async {
      final auth = createTestAuth();
      final result = await auth.resetPasswordForAdmin('non_existent_id', 'NewPass123!');
      expect(result, isFalse);
      expect(auth.error, equals('Account not found.'));
    });

    test('sendPasswordToEmail dispatches password for Admin only', () async {
      final auth = createTestAuth();

      // Admin email
      final adminPassword = await auth.sendPasswordToEmail('admin@inventory.com');
      expect(adminPassword, isNotNull);
      expect(adminPassword, equals('password123'));
      expect(auth.error, isNull);

      // Non-admin email (Warehouse Manager)
      final wmPassword = await auth.sendPasswordToEmail('warehouse@inventory.com');
      expect(wmPassword, isNull);
      expect(auth.error, contains('Only administrator accounts can recover their password'));

      // Non-admin email (Staff)
      final staffPassword = await auth.sendPasswordToEmail('staff@inventory.com');
      expect(staffPassword, isNull);
      expect(auth.error, contains('Only administrator accounts can recover their password'));

      // Non-existent email
      final unknownPassword = await auth.sendPasswordToEmail('unknown@inventory.com');
      expect(unknownPassword, isNull);
      expect(auth.error, equals('No account found with this email or username.'));
    });

    test('resetPasswordForAdminByEmail allows admin reset and blocks non-admin', () async {
      final auth = createTestAuth();

      // Non-admin email blocked
      final blocked = await auth.resetPasswordForAdminByEmail('staff@inventory.com', 'NewPass123!');
      expect(blocked, isFalse);
      expect(auth.error, contains('Only administrator accounts can reset their password'));

      // Admin email succeeds
      final ok = await auth.resetPasswordForAdminByEmail('admin@inventory.com', 'FreshAdminPass777');
      expect(ok, isTrue);
      expect(auth.error, isNull);

      // sendPasswordToEmail now returns the newly reset password
      final fetchedPassword = await auth.sendPasswordToEmail('admin@inventory.com');
      expect(fetchedPassword, equals('FreshAdminPass777'));

      // Login succeeds with the new password
      final canLogin = await auth.login('admin@inventory.com', 'FreshAdminPass777');
      expect(canLogin, isTrue);
    });

    test('Real OTP Flow: sendOtpToEmail and resetPasswordWithOtp delegate to ApiService', () async {
      final auth = createTestAuth();

      // sendOtpToEmail returns bool
      final result = await auth.sendOtpToEmail('user@inventory.com');
      expect(result, isA<bool>());

      // resetPasswordWithOtp returns bool
      final resetResult = await auth.resetPasswordWithOtp(
        email: 'user@inventory.com',
        otp: '123456',
        newPassword: 'BrandNewSecurePass1!',
      );
      expect(resetResult, isA<bool>());
    });
  });

  group('Staff Role Permission Tests', () {
    test('Staff profile getters, role flags, and permission checks', () {
      final staff = UserProfile(
        id: 'u_staff',
        name: 'John Staff',
        email: 'staff@inventory.com',
        role: UserProfile.roleStaff,
      );

      expect(staff.isStaff, isTrue);
      expect(staff.isAdmin, isFalse);
      expect(staff.isWarehouseManager, isFalse);
      expect(staff.roleDisplayName, equals('Staff'));
      expect(staff.roleBadgeLabel, equals('STAFF'));

      // Core requirements:
      // Staff CANNOT do user management
      expect(staff.canManageUsers, isFalse);
      // Staff CAN stock out
      expect(staff.canStockOut, isTrue);
      // Staff CAN stock in
      expect(staff.canStockIn, isTrue);

      // Staff CANNOT add/edit/delete supplier (view only)
      expect(staff.canManageSuppliers, isFalse);
      expect(staff.canViewSuppliers, isTrue);

      // Staff CAN see categories (read-only) but CANNOT add/edit/delete category
      expect(staff.canViewCategories, isTrue);
      expect(staff.canManageCategories, isFalse);

      // Staff CANNOT add/edit/delete product (view only)
      expect(staff.canManageProducts, isFalse);
      expect(staff.canViewProducts, isTrue);
    });

    test('Admin and Warehouse Manager comparison with Staff permissions', () {
      final admin = UserProfile(
        id: 'u_admin',
        name: 'Admin User',
        email: 'admin@inventory.com',
        role: UserProfile.roleAdmin,
      );
      final manager = UserProfile(
        id: 'u_manager',
        name: 'Manager User',
        email: 'manager@inventory.com',
        role: UserProfile.roleWarehouseManager,
      );

      // Admin has full access
      expect(admin.canManageUsers, isTrue);
      expect(admin.canStockOut, isTrue);
      expect(admin.canStockIn, isTrue);
      expect(admin.canManageSuppliers, isTrue);
      expect(admin.canViewCategories, isTrue);
      expect(admin.canManageCategories, isTrue);
      expect(admin.canManageProducts, isTrue);

      // Warehouse manager can stock in/out, manage suppliers, categories, and products, but cannot manage users
      expect(manager.canManageUsers, isFalse);
      expect(manager.canStockOut, isTrue);
      expect(manager.canStockIn, isTrue);
      expect(manager.canManageSuppliers, isTrue);
      expect(manager.canViewCategories, isTrue);
      expect(manager.canManageCategories, isTrue);
      expect(manager.canManageProducts, isTrue);
    });
  });

  group('Staff User Management Restrictions in AuthProvider', () {
    test('Staff user cannot add, update, change role, or toggle user status', () async {
      final auth = AuthProvider(initialUsers: _testUsers, testMode: true);
      // Log in as staff
      final loginOk = await auth.login('staff@inventory.com', 'password123');
      expect(loginOk, isTrue);
      expect(auth.user?.isStaff, isTrue);
      expect(auth.user?.canManageUsers, isFalse);

      final dummyUser = UserProfile(
        id: 'u_new',
        name: 'Test New User',
        email: 'testnew@inventory.com',
        role: 'STAFF',
      );

      // 1. Staff cannot add user
      final addOk = await auth.addUser(dummyUser);
      expect(addOk, isFalse);
      expect(auth.error, contains('Staff accounts cannot perform user management'));

      // 2. Staff cannot update user
      final updateOk = await auth.updateUser(dummyUser);
      expect(updateOk, isFalse);
      expect(auth.error, contains('Staff accounts cannot perform user management'));

      // 3. Staff cannot change user role
      final changeRoleOk = await auth.changeUserRole('u1', 'STAFF');
      expect(changeRoleOk, isFalse);
      expect(auth.error, contains('Staff accounts cannot perform user management'));

      // 4. Staff cannot toggle user status
      final toggleStatusOk = await auth.toggleUserStatus('u2');
      expect(toggleStatusOk, isFalse);
      expect(auth.error, contains('Staff accounts cannot perform user management'));

      // 5. Staff cannot delete user
      final deleteOk = await auth.deleteUser('u2');
      expect(deleteOk, isFalse);
      expect(auth.error, contains('Staff accounts cannot perform user management'));
    });
  });

  group('Staff Stock In & Stock Out Permissions in StockProvider', () {
    test('Staff user can record Stock In and Stock Out', () async {
      final staffUser = _testUsers.firstWhere((u) => u.isStaff);
      final stockProvider = StockProvider(currentUser: staffUser);

      expect(stockProvider.currentUser?.canStockOut, isTrue);
      expect(stockProvider.currentUser?.canStockIn, isTrue);
    });
  });

  group('Staff Role UI Guard Widget Tests', () {
    testWidgets('DashboardQuickActions shows Stock Out and hides Add Product when user is Staff', (tester) async {
      final auth = AuthProvider(initialUsers: _testUsers, testMode: true);
      await auth.login('staff@inventory.com', 'password123');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const Scaffold(
              body: DashboardQuickActions(),
            ),
          ),
        ),
      );

      // Stock In should be visible
      expect(find.text('Stock In'), findsOneWidget);
      // Stock Out should be visible for staff
      expect(find.text('Stock Out'), findsOneWidget);
      // Add Product should NOT be visible for staff (view only)
      expect(find.text('Add Product'), findsNothing);
      // Reports remain available
      expect(find.text('Reports'), findsOneWidget);
    });

    testWidgets('DashboardQuickActions shows Stock Out and Add Product when user is Admin', (tester) async {
      final auth = AuthProvider(initialUsers: _testUsers, testMode: true);
      await auth.login('admin@inventory.com', 'password123');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const Scaffold(
              body: DashboardQuickActions(),
            ),
          ),
        ),
      );

      // Both Stock In and Stock Out should be visible for admin
      expect(find.text('Stock In'), findsOneWidget);
      expect(find.text('Stock Out'), findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);
    });

    testWidgets('StockScreen enables both Stock In and Stock Out for Staff', (tester) async {
      final auth = AuthProvider(initialUsers: _testUsers, testMode: true);
      await auth.login('staff@inventory.com', 'password123');

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider()),
              ChangeNotifierProvider<SupplierProvider>(create: (_) => SupplierProvider()),
              ChangeNotifierProvider<StockProvider>(create: (_) => StockProvider(currentUser: auth.user)),
            ],
            child: const StockScreen(),
          ),
        ),
      );

      // Both segments should be visible and active for staff
      expect(find.text('Stock Out'), findsOneWidget);
      expect(find.text('Stock In'), findsOneWidget);
    });



    testWidgets('MoreScreen shows Categories and Suppliers (view only) and hides User Management for Staff', (tester) async {
      final auth = AuthProvider(initialUsers: _testUsers, testMode: true);
      await auth.login('staff@inventory.com', 'password123');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const MoreScreen(),
          ),
        ),
      );

      // Categories should be visible (view only)
      expect(find.text('Categories'), findsOneWidget);
      // Suppliers should be visible (view only)
      expect(find.text('Suppliers'), findsOneWidget);
      // User Management should NOT be visible
      expect(find.text('User Management'), findsNothing);
    });

    testWidgets('SuppliersScreen hides Add Supplier FAB for Staff', (tester) async {
      final auth = AuthProvider(initialUsers: _testUsers, testMode: true);
      await auth.login('staff@inventory.com', 'password123');

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<SupplierProvider>(create: (_) => SupplierProvider(currentUser: auth.user)),
            ],
            child: const SuppliersScreen(),
          ),
        ),
      );

      // Add Supplier FAB should NOT be visible
      expect(find.text('Add Supplier'), findsNothing);
    });

    testWidgets('ProductsScreen hides Add Product FAB for Staff', (tester) async {
      final auth = AuthProvider(initialUsers: _testUsers, testMode: true);
      await auth.login('staff@inventory.com', 'password123');

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider(currentUser: auth.user)),
              ChangeNotifierProvider<CategoryProvider>(create: (_) => CategoryProvider(currentUser: auth.user)),
              ChangeNotifierProvider<SupplierProvider>(create: (_) => SupplierProvider(currentUser: auth.user)),
            ],
            child: const ProductsScreen(),
          ),
        ),
      );

      // Add Product FAB should NOT be visible
      expect(find.text('Add Product'), findsNothing);
    });
  });

  group('Staff Supplier Restrictions in SupplierProvider', () {
    test('Staff user cannot add, update, delete, or toggle supplier status', () async {
      final staffUser = _testUsers.firstWhere((u) => u.isStaff);
      final supplierProv = SupplierProvider(currentUser: staffUser);

      final dummySupplier = Supplier(
        id: 's_new',
        name: 'New Vendor',
        phone: '012345678',
        email: 'vendor@abc.com',
      );

      // 1. Staff cannot add supplier
      final added = await supplierProv.addSupplier(dummySupplier);
      expect(added, isNull);
      expect(supplierProv.error, contains('Staff accounts cannot add, edit, or delete suppliers'));

      // 2. Staff cannot update supplier
      final updated = await supplierProv.updateSupplier(dummySupplier);
      expect(updated, isFalse);
      expect(supplierProv.error, contains('Staff accounts cannot add, edit, or delete suppliers'));

      // 3. Staff cannot delete supplier
      final deleted = await supplierProv.deleteSupplier('s1');
      expect(deleted, isFalse);
      expect(supplierProv.error, contains('Staff accounts cannot add, edit, or delete suppliers'));

      // 4. Staff cannot toggle supplier status
      supplierProv.toggleSupplierStatus('s1');
      expect(supplierProv.error, contains('Staff accounts cannot add, edit, or delete suppliers'));
    });
  });

  group('Staff Category Restrictions in CategoryProvider', () {
    test('Staff user cannot add, update, delete, deactivate, or toggle category', () async {
      final staffUser = _testUsers.firstWhere((u) => u.isStaff);
      final catProv = CategoryProvider(currentUser: staffUser);

      final dummyCategory = Category(
        id: 'c_new',
        name: 'Beverages',
        description: 'Drinks and liquids',
      );

      // 1. Staff cannot add category
      final added = await catProv.addCategory(dummyCategory);
      expect(added, isNull);
      expect(catProv.error, contains('Staff accounts cannot add, edit, or delete categories'));

      // 2. Staff cannot update category
      final updated = await catProv.updateCategory(dummyCategory);
      expect(updated, isFalse);
      expect(catProv.error, contains('Staff accounts cannot add, edit, or delete categories'));

      // 3. Staff cannot delete category
      final deleted = await catProv.deleteCategory('c1');
      expect(deleted, isFalse);
      expect(catProv.error, contains('Staff accounts cannot add, edit, or delete categories'));

      // 4. Staff cannot deactivate category
      catProv.deactivateCategory('c1');
      expect(catProv.error, contains('Staff accounts cannot add, edit, or delete categories'));

      // 5. Staff cannot toggle category status
      catProv.toggleCategoryStatus('c1');
      expect(catProv.error, contains('Staff accounts cannot add, edit, or delete categories'));
    });
  });

  group('Staff Product Restrictions in ProductProvider', () {
    test('Staff user cannot add, update, delete, or toggle product status (view only)', () async {
      final staffUser = _testUsers.firstWhere((u) => u.isStaff);
      final prodProv = ProductProvider(currentUser: staffUser);

      final dummyProduct = Product(
        id: 'p_new',
        name: 'New Product',
        sku: 'NEW-001',
        categoryId: 'c1',
        supplierId: 's1',
        price: 10.0,
        quantity: 5,
        minStockLevel: 2,
        unit: 'pcs',
      );

      // 1. Staff cannot add product
      final added = await prodProv.addProduct(dummyProduct);
      expect(added, isNull);
      expect(prodProv.error, contains('Staff accounts have view-only access to products'));

      // 2. Staff cannot update product
      final updated = await prodProv.updateProduct(dummyProduct);
      expect(updated, isFalse);
      expect(prodProv.error, contains('Staff accounts have view-only access to products'));

      // 3. Staff cannot delete product
      final deleted = await prodProv.deleteProduct('p1');
      expect(deleted, isFalse);
      expect(prodProv.error, contains('Staff accounts have view-only access to products'));

      // 4. Staff cannot toggle product status
      final toggled = await prodProv.toggleProductStatus('p1');
      expect(toggled, isFalse);
      expect(prodProv.error, contains('Staff accounts have view-only access to products'));
    });
  });
}

