import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/core/widgets/transaction_tile.dart';
import 'package:inventory_management/models/stock_movement.dart';
import '../widgets/report_header_banner.dart';

/// Transaction History Report Tab
/// Displays warehouse transaction audit metrics (in, out, net change) and audit log tiles.
class TransactionHistoryReportTab extends StatelessWidget {
  final DateTimeRange dateRange;
  final String periodLabel;

  const TransactionHistoryReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();

    final periodMovements = stock.getMovementsBetween(
      dateRange.start,
      dateRange.end,
    );

    final totalIn = periodMovements
        .where((m) => m.type == MovementType.stockIn)
        .fold<int>(0, (s, m) => s + m.quantity);
    final totalOut = periodMovements
        .where((m) => m.type == MovementType.stockOut)
        .fold<int>(0, (s, m) => s + m.quantity);
    final netChange = totalIn - totalOut;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportHeaderBanner(
          title: 'Transaction Audit Report',
          period: periodLabel,
          subtitle: 'Comprehensive audit trail of all warehouse stock movements',
        ),
        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final cardIn = SummaryCard(
              title: 'Total In',
              value: '+$totalIn',
              icon: Icons.arrow_downward,
              color: AppColors.chartIn,
            );
            final cardOut = SummaryCard(
              title: 'Total Out',
              value: '-$totalOut',
              icon: Icons.arrow_upward,
              color: AppColors.chartOut,
            );
            final cardNet = SummaryCard(
              title: 'Net Change',
              value: '${netChange >= 0 ? "+" : ""}$netChange',
              icon: Icons.swap_vert,
              color: netChange >= 0 ? AppColors.inStock : AppColors.danger,
            );

            if (constraints.maxWidth < 440) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: cardIn),
                      const SizedBox(width: 8),
                      Expanded(child: cardOut),
                    ],
                  ),
                  const SizedBox(height: 8),
                  cardNet,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: cardIn),
                const SizedBox(width: 8),
                Expanded(child: cardOut),
                const SizedBox(width: 8),
                Expanded(child: cardNet),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        SectionHeader(title: 'Transaction Log (${periodMovements.length})'),
        const SizedBox(height: 8),
        if (periodMovements.isEmpty)
          const EmptyState(
            message: 'No transactions in selected period',
            subtitle: 'Choose a broader date range to review history records',
            icon: Icons.history,
          )
        else
          ...periodMovements.map(
            (m) => TransactionTile(movement: m, showReference: true),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}
