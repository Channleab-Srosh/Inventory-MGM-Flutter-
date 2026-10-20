import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

/// "More" hub: role-based navigation matching Notion specification
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final isAdmin = user?.isAdmin == true;
    final canManageUsers = user?.canManageUsers == true;
    final isWarehouseManager = user?.isWarehouseManager == true;
    final roleColor = isAdmin
        ? AppColors.primary
        : (isWarehouseManager ? const Color(0xFFD97706) : const Color(0xFF0EA5E9));

    return Scaffold(
      appBar: AppBar(title: const Text('More Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User profile preview card
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: roleColor,
                      child: Text(
                        user?.initials ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? 'User',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user?.roleBadgeLabel ?? 'STAFF',
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'View & edit profile →',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.grey500),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Inventory Section
          _MenuSection(title: 'Inventory Operations', items: [
            if (user?.canViewCategories == true)
              _MenuItem(
                icon: Icons.category_outlined,
                label: 'Categories',
                subtitle: 'Organize catalog & categories',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push('/more/categories'),
              ),
            _MenuItem(
              icon: Icons.business_outlined,
              label: 'Suppliers',
              subtitle: 'Vendor contact & address records',
              color: const Color(0xFF0EA5E9),
              onTap: () => context.push('/more/suppliers'),
            ),
            _MenuItem(
              icon: Icons.history_outlined,
              label: 'Stock History',
              subtitle: 'Audit logs of in/out movements',
              color: const Color(0xFFF59E0B),
              onTap: () => context.push('/history'),
            ),
          ]),
          const SizedBox(height: 12),

          // Reports & Analytics
          _MenuSection(title: 'Reports & Analytics', items: [
            _MenuItem(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              subtitle: 'Summary, in/out reports, low stock',
              color: const Color(0xFF10B981),
              onTap: () => context.push('/reports'),
            ),
          ]),
          const SizedBox(height: 12),

          // Administration Section (Admin only - Staff cannot do user management)
          if (canManageUsers) ...[
            _MenuSection(title: 'Administration', items: [
              _MenuItem(
                icon: Icons.people_outline,
                label: 'User Management',
                subtitle: 'Manage accounts, roles, & access',
                color: AppColors.primary,
                onTap: () => context.push('/more/users'),
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'System Settings',
                subtitle: 'Currency, thresholds, & alerts',
                color: AppColors.grey500,
                onTap: () => context.push('/more/settings'),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          // Account Section
          _MenuSection(title: 'Account', items: [
            _MenuItem(
              icon: Icons.person_outline,
              label: 'My Profile',
              subtitle: 'Account details & change password',
              color: AppColors.primary,
              onTap: () => context.push('/profile'),
            ),
            _MenuItem(
              icon: Icons.logout,
              label: 'Logout',
              subtitle: 'Sign out of this session',
              color: AppColors.outOfStock,
              onTap: () => _confirmLogout(context, auth),
            ),
          ]),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'Inventory Manager v1.0.0 (Role: ${user?.roleDisplayName ?? "Staff"})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to sign out of your account?',
      confirmLabel: 'Logout',
      confirmColor: AppColors.outOfStock,
    );
    if (confirmed && context.mounted) {
      auth.logout();
      context.go('/login');
    }
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.grey500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodySmall)
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey500),
      onTap: onTap,
    );
  }
}
