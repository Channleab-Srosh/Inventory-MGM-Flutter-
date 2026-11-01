/// Inventory report response model matching backend InventoryReportResponse.java
class InventoryReportItem {
  final String id;
  final String sku;
  final String name;
  final String? categoryName;
  final String? supplierName;
  final String unitOfMeasure;
  final double unitPrice;
  final int stockQuantity;
  final int minimumStock;
  final double totalValue;
  final bool lowStock;
  final bool active;
  final DateTime updatedAt;

  InventoryReportItem({
    required this.id,
    required this.sku,
    required this.name,
    this.categoryName,
    this.supplierName,
    this.unitOfMeasure = 'PCS',
    required this.unitPrice,
    required this.stockQuantity,
    required this.minimumStock,
    required this.totalValue,
    required this.lowStock,
    required this.active,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  int get quantity => stockQuantity;
  int get minStockLevel => minimumStock;
  bool get isLowStock => lowStock;
  bool get isOutOfStock => stockQuantity <= 0;

  factory InventoryReportItem.fromJson(Map<String, dynamic> json) {
    return InventoryReportItem(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryName: json['categoryName']?.toString(),
      supplierName: json['supplierName']?.toString(),
      unitOfMeasure: json['unitOfMeasure']?.toString() ?? 'PCS',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      minimumStock: (json['minimumStock'] as num?)?.toInt() ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
      lowStock: (json['lowStock'] as bool?) ?? false,
      active: (json['active'] as bool?) ?? true,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'categoryName': categoryName,
      'supplierName': supplierName,
      'unitOfMeasure': unitOfMeasure,
      'unitPrice': unitPrice,
      'stockQuantity': stockQuantity,
      'minimumStock': minimumStock,
      'totalValue': totalValue,
      'lowStock': lowStock,
      'active': active,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}


int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;
double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

/// One row of the category breakdown (backend CategoryStockBreakdown)
class CategoryStockBreakdown {
  final String? categoryId;
  final String categoryName;
  final int totalItems;
  final int totalUnits;
  final double totalValuation;

  const CategoryStockBreakdown({
    this.categoryId,
    required this.categoryName,
    required this.totalItems,
    required this.totalUnits,
    required this.totalValuation,
  });

  factory CategoryStockBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryStockBreakdown(
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString() ?? 'Uncategorized',
      totalItems: _toInt(json['totalItems']),
      totalUnits: _toInt(json['totalUnits']),
      totalValuation: _toDouble(json['totalValuation']),
    );
  }
}

/// Stock summary report matching backend InventorySummaryReportResponse
/// (GET /reports/inventory/summary)
class InventorySummaryReport {
  final int totalItems;
  final int totalUnits;
  final double totalInventoryValuation;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final List<CategoryStockBreakdown> categoryBreakdown;

  const InventorySummaryReport({
    required this.totalItems,
    required this.totalUnits,
    required this.totalInventoryValuation,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.categoryBreakdown,
  });

  factory InventorySummaryReport.fromJson(Map<String, dynamic> json) {
    // The API sends the totals both at the top level and inside `stockSummary`
    final nested = json['stockSummary'] is Map<String, dynamic>
        ? json['stockSummary'] as Map<String, dynamic>
        : const <String, dynamic>{};

    dynamic pick(String key) => json[key] ?? nested[key];

    final rawCategories = json['categoryBreakdown'];
    return InventorySummaryReport(
      totalItems: _toInt(pick('totalItems')),
      totalUnits: _toInt(pick('totalUnits')),
      totalInventoryValuation: _toDouble(pick('totalInventoryValuation')),
      inStockCount: _toInt(pick('inStockCount')),
      lowStockCount: _toInt(pick('lowStockCount')),
      outOfStockCount: _toInt(pick('outOfStockCount')),
      categoryBreakdown: rawCategories is List
          ? rawCategories
              .whereType<Map<String, dynamic>>()
              .map(CategoryStockBreakdown.fromJson)
              .toList()
          : const [],
    );
  }
}