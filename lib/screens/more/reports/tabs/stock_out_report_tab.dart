import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/stock_movement.dart';
import '../widgets/report_header_banner.dart';

/// Stock Out Report Tab
/// Displays dispatched goods, sales fulfillment, damaged items, and reasons breakdown.
class StockOutReportTab extends StatelessWidget {
  final DateTimeRange dateRange;
  final String periodLabel;

  const StockOutReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();

    final outMovements = stock.getMovementsBetween(
      dateRange.start,
      dateRange.end,
      type: MovementType.stockOut,
    );

    final totalQuantity = outMovements.fold<int>(0, (s, m) => s + m.quantity);
    final totalSales = outMovements
        .where((m) => m.reason == StockOutReason.sale)
        .fold<int>(0, (s, m) => s + m.quantity);
    final totalDamaged = outMovements
        .where((m) => m.reason == StockOutReason.damaged)
        .fold<int>(0, (s, m) => s + m.quantity);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportHeaderBanner(
          title: 'Stock Out Report',
          period: periodLabel,
          subtitle: 'Dispatched goods, sales fulfillment, and damaged stock write-offs',
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Dispatched',
                value: '-$totalQuantity units',
                icon: Icons.arrow_upward,
                color: AppColors.chartOut,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Orders / Events',
                value: '${outMovements.length}',
                icon: Icons.shopping_bag_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Sales Out',
                value: '$totalSales units',
                icon: Icons.point_of_sale,
                color: AppColors.inStock,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Damaged / Other',
                value: '$totalDamaged units',
                icon: Icons.delete_sweep_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SectionHeader(title: 'Dispatched Transactions (${outMovements.length})'),
        const SizedBox(height: 8),
        if (outMovements.isEmpty)
          const EmptyState(
            message: 'No Stock Out records in this period',
            subtitle: 'Try changing the date filter at the top',
            icon: Icons.arrow_upward,
          )
        else
          ...outMovements.map((m) {
            final reasonText = m.reason == StockOutReason.sale
                ? 'SALE'
                : m.reason == StockOutReason.damaged
                    ? 'DAMAGED'
                    : 'OTHER';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.chartOut.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_upward,
                              color: AppColors.chartOut, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${DateFormat("MMM d, yyyy").format(m.date)} · by ${m.userName}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '-${m.quantity} ${m.unit ?? "pcs"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.chartOut,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stock: ${m.stockBefore ?? "-"} → ${m.stockAfter ?? "-"} units',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.chartOut.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              reasonText,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.chartOut),
                            ),
                          ),
                          if (m.reference != null)
                            Text(
                              'Ref: ${m.reference}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.secondaryText),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }
}
