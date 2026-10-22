import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/models/stock_movement.dart';

/// Filter bottom sheet matching Notion requirements:
/// Product, Transaction Type, Date From, Date To, User
class HistoryFilterSheet extends StatefulWidget {
  final MovementType? currentType;
  final DateTime? currentStart;
  final DateTime? currentEnd;
  final String? currentProduct;
  final String? currentUser;
  final List<dynamic> products;
  final List<dynamic> users;
  final Function(MovementType?, DateTime?, DateTime?, String?, String?) onApply;
  final VoidCallback onClear;

  const HistoryFilterSheet({
    super.key,
    this.currentType,
    this.currentStart,
    this.currentEnd,
    this.currentProduct,
    this.currentUser,
    required this.products,
    required this.users,
    required this.onApply,
    required this.onClear,
  });

  static Future<void> show({
    required BuildContext context,
    required MovementType? currentType,
    required DateTime? currentStart,
    required DateTime? currentEnd,
    required String? currentProduct,
    required String? currentUser,
    required List<dynamic> products,
    required List<dynamic> users,
    required Function(MovementType?, DateTime?, DateTime?, String?, String?)
        onApply,
    required VoidCallback onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HistoryFilterSheet(
        currentType: currentType,
        currentStart: currentStart,
        currentEnd: currentEnd,
        currentProduct: currentProduct,
        currentUser: currentUser,
        products: products,
        users: users,
        onApply: onApply,
        onClear: onClear,
      ),
    );
  }

  @override
  State<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<HistoryFilterSheet> {
  MovementType? _type;
  DateTime? _start;
  DateTime? _end;
  String? _selectedProductId;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _type = widget.currentType;
    _start = widget.currentStart;
    _end = widget.currentEnd;
    _selectedProductId = widget.currentProduct;
    _selectedUserId = widget.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filter Stock History',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 1. Transaction Type
                const Text(
                  'Transaction Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TypeChip(
                      label: 'All',
                      selected: _type == null,
                      onSelected: () => setState(() => _type = null),
                    ),
                    _TypeChip(
                      label: 'Stock In',
                      selected: _type == MovementType.stockIn,
                      color: AppColors.chartIn,
                      onSelected: () => setState(() => _type = MovementType.stockIn),
                    ),
                    _TypeChip(
                      label: 'Stock Out',
                      selected: _type == MovementType.stockOut,
                      color: AppColors.chartOut,
                      onSelected: () => setState(() => _type = MovementType.stockOut),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

            // 2. Product filter dropdown
            const Text(
              'Product',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: _selectedProductId,
              decoration: const InputDecoration(
                hintText: 'All Products',
                prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Products')),
                ...widget.products.map((p) => DropdownMenuItem(
                      value: p.id as String,
                      child: Text(
                        '${p.name} (${p.sku})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedProductId = v),
            ),
            const SizedBox(height: 16),

            // 3. User filter dropdown
            const Text(
              'Performed By User',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: _selectedUserId,
              decoration: const InputDecoration(
                hintText: 'All Users',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Users')),
                ...widget.users.map((u) => DropdownMenuItem(
                      value: u.id as String,
                      child: Text(
                        '${u.name} (${u.roleDisplayName})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedUserId = v),
            ),
            const SizedBox(height: 16),

            // 4. Date Range
            const Text(
              'Date Range',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _start == null
                            ? 'From Date'
                            : DateFormat('dd/MM/yy').format(_start!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _start ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _start = picked);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _end == null
                            ? 'To Date'
                            : DateFormat('dd/MM/yy').format(_end!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _end ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _end = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClear,
                    child: const Text('Reset Filters'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(
                      _type,
                      _start,
                      _end,
                      _selectedProductId,
                      _selectedUserId,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _TypeChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: c.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? c : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
