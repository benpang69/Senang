import 'package:flutter/material.dart';

import '../models/daily_report_data.dart';
import '../services/daily_report_pdf_service.dart';
import '../services/daily_report_share_service.dart';

class DailyReportScreen extends StatelessWidget {
  final DailyReportData report;

  const DailyReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final pdfService = DailyReportPdfService();
    final shareService = DailyReportShareService();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              report.boothName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(
              _formatDate(report.reportDate),
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            _summaryRow('Total Sales', _money(report.totalSales)),

            _summaryRow('Total Expenses', _money(report.totalExpenses)),

            _summaryRow('Expected Cash', _money(report.expectedCash)),

            _summaryRow('Actual Cash', _money(report.actualCash)),

            _summaryRow('Cash Difference', _money(report.cashDifference)),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: () async {
                final pdfBytes = await pdfService.generate(report);

                await shareService.preview(pdfBytes);
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Preview PDF'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () async {
                final pdfBytes = await pdfService.generate(report);

                await shareService.share(pdfBytes);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _money(int cents) {
    return 'RM ${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
