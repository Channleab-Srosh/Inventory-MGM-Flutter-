import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/providers/auth_provider.dart';

/// Quick action shortcuts for the Dashboard (Stock In, Stock Out, Add Product, Reports).
/// Staff accounts cannot stock out, so Stock Out is hidden for staff.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canStockOut = auth.user?.canStockOut ?? true;
    final canManageProducts = auth.user?.canManageProducts ?? true;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.arrow_downward,
            label: 'Stock In',
            color: AppColors.chartIn,
            onTap: () => context.go('/stock?tab=in'),
          ),
          const SizedBox(width: 8),
          if (canStockOut) ...[
            _ActionButton(
              icon: Icons.arrow_upward,
              label: 'Stock Out',
              color: AppColors.chartOut,
              onTap: () => context.go('/stock?tab=out'),
            ),
            const SizedBox(width: 8),
          ],
          if (canManageProducts) ...[
            _ActionButton(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              color: AppColors.primary,
              onTap: () => context.push('/products/add'),
            ),
            const SizedBox(width: 8),
          ],
          _ActionButton(
            icon: Icons.bar_chart_outlined,
            label: 'Reports',
            color: const Color(0xFF10B981),
            onTap: () => context.go('/reports'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
