import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/providers/stock_provider.dart';
import 'package:inventory_management/providers/supplier_provider.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/core/widgets/common_widgets.dart';
import 'package:inventory_management/models/stock_movement.dart';
import '../widgets/report_header_banner.dart';

/// Stock In Report Tab
/// Displays incoming stock metrics, shipments count, and transaction cards.
class StockInReportTab extends StatelessWidget {
  final DateTimeRange dateRange;
  final String periodLabel;

  const StockInReportTab({
    super.key,
    required this.dateRange,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    final suppliers = context.watch<SupplierProvider>();

    final inMovements = stock.getMovementsBetween(
      dateRange.start,
      dateRange.end,
      type: MovementType.stockIn,
    );

    final totalQuantity = inMovements.fold<int>(0, (s, m) => s + m.quantity);
    final totalBatches = inMovements.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ReportHeaderBanner(
          title: 'Stock In Report',
          period: periodLabel,
          subtitle: 'Incoming inventory, supplier receipts, and restock records',
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Received',
                value: '+$totalQuantity units',
                icon: Icons.arrow_downward,
                color: AppColors.chartIn,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Shipments',
                value: '$totalBatches batch${totalBatches == 1 ? "" : "es"}',
                icon: Icons.local_shipping_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SectionHeader(title: 'Incoming Transactions ($totalBatches)'),
        const SizedBox(height: 8),
        if (inMovements.isEmpty)
          const EmptyState(
            message: 'No Stock In records in this period',
            subtitle: 'Change the date range filter above to view earlier records',
            icon: Icons.arrow_downward,
          )
        else
          ...inMovements.map((m) {
            final sup =
                m.supplierId != null ? suppliers.findById(m.supplierId!) : null;
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
                            color: AppColors.chartIn.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_downward,
                              color: AppColors.chartIn, size: 16),
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
                          '+${m.quantity} ${m.unit ?? "pcs"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.chartIn,
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
                          if (sup != null)
                            Text(
                              'Supplier: ${sup.name}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.secondaryText),
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
