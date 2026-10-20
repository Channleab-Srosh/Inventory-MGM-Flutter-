import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'widgets/stock_in_form.dart';
import 'widgets/stock_out_form.dart';

/// Stock In / Stock Out screen with segmented control
/// All operational roles (Staff, Warehouse Manager, Admin) can perform Stock In and Stock Out.
class StockScreen extends StatefulWidget {
  final int initialTab;
  const StockScreen({super.key, this.initialTab = 0});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant StockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canStockOut = auth.user?.canStockOut ?? true;

    // Safety guard: Staff cannot stock out, always revert to Stock In
    if (!canStockOut && _selectedTab == 1) {
      _selectedTab = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history_outlined, size: 18),
            label: const Text('History →'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<int>(
              segments: [
                const ButtonSegment(
                  value: 0,
                  label: Text('Stock In'),
                  icon: Icon(Icons.arrow_downward, size: 16),
                ),
                ButtonSegment(
                  value: 1,
                  enabled: canStockOut,
                  label: Text(canStockOut ? 'Stock Out' : 'Stock Out (Locked)'),
                  icon: Icon(
                    canStockOut ? Icons.arrow_upward : Icons.lock_outline,
                    size: 16,
                  ),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (s) {
                final chosen = s.first;
                if (chosen == 1 && !canStockOut) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Staff accounts are not permitted to perform Stock Out movements.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                setState(() => _selectedTab = chosen);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _selectedTab == 0
                        ? AppColors.chartIn
                        : AppColors.chartOut;
                  }
                  return null;
                }),
              ),
            ),
          ),

          // Informative banner for staff role
          if (!canStockOut)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0EA5E9)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Staff Role: Authorized for Stock In operations only. Stock Out is restricted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0369A1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),
          Expanded(
            child: _selectedTab == 0
                ? const StockInForm()
                : (canStockOut ? const StockOutForm() : _buildRestrictedView(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.chartOut),
            const SizedBox(height: 16),
            Text(
              'Stock Out Restricted',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Staff accounts cannot record stock out operations. Please contact a warehouse manager or system administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedTab = 0),
              icon: const Icon(Icons.arrow_downward),
              label: const Text('Go to Stock In'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.chartIn),
            ),
          ],
        ),
      ),
    );
  }
}
