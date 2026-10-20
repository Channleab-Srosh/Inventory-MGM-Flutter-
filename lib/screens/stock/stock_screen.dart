import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'widgets/stock_in_form.dart';
import 'widgets/stock_out_form.dart';

/// Stock In / Stock Out screen with minimalist pill segmented control
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

    if (!canStockOut && _selectedTab == 1) {
      _selectedTab = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Bold title left + History pill button right
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  const Text(
                    'Stock',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/history'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded, size: 16, color: AppColors.secondaryText),
                          SizedBox(width: 6),
                          Text(
                            'History',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pill segmented control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    // Stock In tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? AppColors.inStockBg
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: _selectedTab == 0
                                      ? AppColors.inStockText
                                      : AppColors.secondaryText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Stock In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTab == 0
                                        ? AppColors.inStockText
                                        : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Stock Out tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!canStockOut) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Staff accounts are not permitted to perform Stock Out movements.',
                                ),
                                backgroundColor: AppColors.outOfStockText,
                              ),
                            );
                            return;
                          }
                          setState(() => _selectedTab = 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? AppColors.outOfStockBg
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  canStockOut
                                      ? Icons.arrow_upward_rounded
                                      : Icons.lock_outline_rounded,
                                  size: 16,
                                  color: _selectedTab == 1
                                      ? AppColors.outOfStockText
                                      : AppColors.secondaryText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  canStockOut ? 'Stock Out' : 'Stock Out (Locked)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTab == 1
                                        ? AppColors.outOfStockText
                                        : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Informative banner for staff role
            if (!canStockOut)
              Container(
                margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 10),
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
      ),
    );
  }

  Widget _buildRestrictedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.outOfStockBg,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppColors.outOfStockText,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Stock Out Restricted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Staff accounts cannot record stock out operations. Please contact a warehouse manager or system administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.inStockBg,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: AppColors.inStockText.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.inStockText),
                    SizedBox(width: 8),
                    Text(
                      'Go to Stock In',
                      style: TextStyle(
                        color: AppColors.inStockText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
