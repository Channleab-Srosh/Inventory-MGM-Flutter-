import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// Fixed white bar with 4 evenly spaced outline icons matching the mobile UI mockup:
/// - Tab 1: Home (Icons.home_outlined)
/// - Tab 2: Inventory / Hierarchy (Icons.account_tree_outlined)
/// - Tab 3: Stock Flow / Analytics (Icons.bar_chart_outlined)
/// - Tab 4: Settings / More (Icons.settings_outlined)
/// Active tab is highlighted inside a rounded-square light lavender container (44px).
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      path: '/dashboard',
    ),
    _TabItem(
      icon: Icons.account_tree_outlined,
      activeIcon: Icons.account_tree_rounded,
      label: 'Inventory',
      path: '/products',
    ),
    _TabItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Stock',
      path: '/stock',
    ),
    _TabItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      path: '/more',
    ),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/stock')) return 2;
    if (location.startsWith('/more') ||
        location.startsWith('/reports') ||
        location.startsWith('/profile') ||
        location.startsWith('/history')) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        height: 66 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x061A1A1A),
              blurRadius: 16,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            final isSelected = index == currentIndex;

            return Semantics(
              button: true,
              label: tab.label,
              selected: isSelected,
              child: InkWell(
                onTap: () => context.go(tab.path),
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryActive : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          color: isSelected ? AppColors.primaryDark : AppColors.secondaryText,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
