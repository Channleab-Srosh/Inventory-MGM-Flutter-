import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/stock_movement.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';

/// Reusable Transaction / Movement Tile
/// Used in Dashboard, History, and Reports screens to represent stock movements.
class TransactionTile extends StatelessWidget {
  final StockMovement movement;
  final VoidCallback? onTap;
  final bool showReference;

  const TransactionTile({
    super.key,
    required this.movement,
    this.onTap,
    this.showReference = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = movement.type == MovementType.stockIn;
    final color = isIn ? AppColors.success : AppColors.danger;
    final icon = isIn ? Icons.south_west : Icons.north_east;
    final sign = isIn ? '+' : '-';
    final typeLabel = isIn ? 'STOCK IN' : 'STOCK OUT';

    final now = DateTime.now();
    final isToday = movement.date.year == now.year &&
        movement.date.month == now.month &&
        movement.date.day == now.day;
    final dateStr = isToday
        ? 'Today, ${AppUtils.formatTime(movement.date)}'
        : DateFormat('MMM d, HH:mm').format(movement.date);

    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                movement.productName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '$dateStr · ${movement.userName}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
            if (movement.stockBefore != null && movement.stockAfter != null)
              Text(
                'Stock: ${movement.stockBefore} → ${movement.stockAfter} ${movement.unit ?? "pcs"}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
            if (showReference && movement.reference != null && movement.reference!.isNotEmpty)
              Text(
                'Ref: ${movement.reference}',
                style: const TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: AppColors.secondaryText,
                ),
              ),
          ],
        ),
        trailing: Text(
          '$sign${movement.quantity} ${movement.unit ?? "pcs"}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );

    return card;
  }
}
