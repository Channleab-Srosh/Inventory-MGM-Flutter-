import 'package:flutter/material.dart' show DateTimeRange;

import 'package:inventory_management/data/api_service.dart';
import 'package:inventory_management/models/inventory_report.dart';

/// Loads report data from the API. The date filter is applied by the server
/// (products are filtered by their last update, see GET /reports/inventory).
class ReportDataService {
  ReportDataService._();

  static const int pageSize = 100;
  static const int maxPages = 50; // safety cap: 50 x 100 = 5,000 rows

  /// Inventory rows from GET /reports/inventory (all pages) for [range].
  /// Throws if the request fails.
  static Future<List<InventoryReportItem>> fetchInventory({
    required DateTimeRange range,
    bool? lowStockOnly,
    String? stockStatus,
  }) async {
    final api = ApiService();
    final all = <InventoryReportItem>[];
    for (var page = 0; page < maxPages; page++) {
      final chunk = await api.getInventoryReport(
        lowStockOnly: lowStockOnly,
        stockStatus: stockStatus,
        fromDate: range.start,
        toDate: range.end,
        page: page,
        size: pageSize,
      );
      all.addAll(chunk
          .map((e) => InventoryReportItem.fromJson(e as Map<String, dynamic>)));
      if (chunk.length < pageSize) break;
    }
    return all;
  }

  /// Stock summary and category breakdown from GET /reports/inventory/summary.
  /// Throws if the request fails.
  static Future<InventorySummaryReport> fetchInventorySummary(
    DateTimeRange range,
  ) async {
    final json = await ApiService().getInventorySummaryReport(
      fromDate: range.start,
      toDate: range.end,
    );
    return InventorySummaryReport.fromJson(json);
  }
}