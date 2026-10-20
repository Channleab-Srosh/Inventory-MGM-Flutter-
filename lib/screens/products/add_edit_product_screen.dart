import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';

/// Full-screen Add/Edit Product form
class AddEditProductScreen extends StatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _descCtrl;

  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String _status = 'Active';
  late String _unit;
  bool _saving = false;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    final product = _isEditing
        ? context.read<ProductProvider>().findById(widget.productId!)
        : null;

    _nameCtrl = TextEditingController(text: product?.name ?? '');
    _skuCtrl = TextEditingController(text: product?.sku ?? '');
    _priceCtrl = TextEditingController(
        text: product != null ? product.price.toStringAsFixed(2) : '');
    _qtyCtrl = TextEditingController(
        text: product != null ? product.quantity.toString() : '0');
    _minStockCtrl = TextEditingController(
        text: product != null ? product.minStockLevel.toString() : '10');
    _descCtrl = TextEditingController(text: product?.description ?? '');

    final initialUnit = product?.unit.toLowerCase() ?? 'pcs';
    if (Product.commonUnits.contains(initialUnit)) {
      _unit = initialUnit;
    } else {
      _unit = 'pcs';
    }

    _selectedCategoryId = product?.categoryId;
    _selectedSupplierId = product?.supplierId;
    _status = product?.status ?? 'Active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _minStockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canManageProducts != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff accounts have view-only access to products.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier')));
      return;
    }

    // Capture provider BEFORE await to avoid BuildContext across async gap
    final products = context.read<ProductProvider>();

    setState(() => _saving = true);

    final effectiveUnit = _unit;

    bool success = false;
    if (_isEditing) {
      final existing = products.findById(widget.productId!);
      if (existing != null) {
        success = await products.updateProduct(existing.copyWith(
          name: _nameCtrl.text.trim(),
          sku: _skuCtrl.text.trim(),
          price: double.parse(_priceCtrl.text),
          quantity: int.parse(_qtyCtrl.text),
          minStockLevel: int.parse(_minStockCtrl.text),
          unit: effectiveUnit,
          categoryId: _selectedCategoryId,
          supplierId: _selectedSupplierId,
          status: _status,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        ));
      }
    } else {
      final created = await products.addProduct(Product(
        id: products.generateId(),
        name: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        quantity: int.parse(_qtyCtrl.text),
        minStockLevel: int.parse(_minStockCtrl.text),
        unit: effectiveUnit,
        categoryId: _selectedCategoryId!,
        supplierId: _selectedSupplierId!,
        status: _status,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ));
      success = created != null;
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEditing ? 'Product updated!' : 'Product added!')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(products.error ?? 'Failed to save product'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user?.canManageProducts != true) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Access Restricted', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Staff accounts have view-only access to products. Adding and editing products is restricted to administrators and warehouse managers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categories = context.watch<CategoryProvider>().categories;
    final suppliers = context.watch<SupplierProvider>().allSuppliers;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker placeholder
            Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          color: AppColors.primary, size: 32),
                      SizedBox(height: 4),
                      Text('Add Photo',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel(theme, 'Basic Information'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),

            // SKU with scan button
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skuCtrl,
                    decoration: const InputDecoration(labelText: 'SKU *'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'SKU is required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Barcode scanner coming soon')));
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: categories.any((c) => c.id == _selectedCategoryId)
                  ? _selectedCategoryId
                  : null,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
              validator: (v) => v == null ? 'Category is required' : null,
            ),
            const SizedBox(height: 12),

            // Supplier dropdown
            DropdownButtonFormField<String>(
              initialValue: suppliers.any((s) => s.id == _selectedSupplierId)
                  ? _selectedSupplierId
                  : null,
              decoration: const InputDecoration(labelText: 'Supplier *'),
              items: suppliers
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSupplierId = v),
              validator: (v) => v == null ? 'Supplier is required' : null,
            ),
            const SizedBox(height: 12),

            // Status dropdown
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status *'),
              items: const [
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 20),

            _sectionLabel(theme, 'Pricing & Stock'),
            const SizedBox(height: 8),

            // Price
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price *',
                prefixText: '\$ ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Price is required';
                final n = double.tryParse(v);
                if (n == null || n < 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Unit of Measure selector
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(
                labelText: 'Unit of Measure *',
                prefixIcon: Icon(Icons.straighten_outlined, size: 20),
              ),
              items: Product.commonUnits
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text('${u.toUpperCase()} (${_unitDescription(u)})'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _unit = v);
                }
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Initial Qty *',
                      suffixText: _unit,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null) return 'Invalid number';
                      if (n < 0) return 'Stock quantity cannot be negative';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minStockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Stock *',
                      suffixText: _unit,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null) return 'Invalid number';
                      if (n < 0) return 'Min stock cannot be negative';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionLabel(theme, 'Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Update Product' : 'Add Product'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Text(label,
        style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary));
  }

  String _unitDescription(String unit) {
    switch (unit) {
      case 'pcs':
        return 'Pieces';
      case 'can':
        return 'Cans / Tins';
      case 'kg':
        return 'Kilograms';
      case 'g':
        return 'Grams';
      case 'box':
        return 'Boxes';
      case 'bottle':
        return 'Bottles';
      case 'pack':
        return 'Packs';
      case 'liter':
        return 'Liters';
      case 'carton':
        return 'Cartons';
      case 'bag':
        return 'Bags';
      case 'set':
        return 'Sets';
      case 'unit':
        return 'Units';
      default:
        return unit;
    }
  }
}
