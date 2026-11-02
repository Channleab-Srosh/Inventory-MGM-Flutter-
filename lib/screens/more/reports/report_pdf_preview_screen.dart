import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/services/report_pdf_service.dart';
import '../../../core/theme/app_theme.dart';

class ReportPdfPreviewScreen extends StatelessWidget {
  final String title;
  final int reportIndex;
  final DateTimeRange range;

  const ReportPdfPreviewScreen({
    super.key,
    required this.title,
    required this.reportIndex,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
      ),
      body: PdfPreview(
        build: (PdfPageFormat format) async {
          return await ReportPdfService.getPdfBytes(
            reportIndex: reportIndex,
            range: range,
          );
        },
        pdfFileName: '${title.replaceAll(' ', '_')}.pdf',
        canChangeOrientation: false,
        allowPrinting: false,
        canChangePageFormat: false,
        canDebug: false,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF preview...'),
            ],
          ),
        ),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to load PDF preview:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.outOfStockText),
            ),
          ),
        ),
      ),
    );
  }
}
