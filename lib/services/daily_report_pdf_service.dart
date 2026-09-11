import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/daily_report_data.dart';

class DailyReportPdfService {
  Future<Uint8List> generate(DailyReportData report) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Senang Daily Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            'Booth: ${report.boothName}',
          ),

          pw.Text(
            'Date: ${_formatDate(report.reportDate)}',
          ),

          pw.SizedBox(height: 20),

          pw.Text(
            'Sales Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          _summaryTable([
            ['Total Sales', _money(report.totalSales)],
            ['Number of Sales', report.salesCount.toString()],
          ]),

          pw.SizedBox(height: 20),

          pw.Text(
            'Expense Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          _summaryTable([
            ['Total Expenses', _money(report.totalExpenses)],
            ['Number of Expenses', report.expenseCount.toString()],
          ]),

          pw.SizedBox(height: 20),

          pw.Text(
            'Cash Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          _summaryTable([
            ['Opening Cash', _money(report.openingCash)],
            ['Cash Sales', _money(report.cashSales)],
            ['Cash Expenses', _money(report.cashExpenses)],
            ['Expected Cash', _money(report.expectedCash)],
            ['Actual Cash', _money(report.actualCash)],
            ['Cash Difference', _money(report.cashDifference)],
          ]),

          if (report.notes != null && report.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 20),

            pw.Text(
              'Notes',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Text(report.notes!),
          ],
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _summaryTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey,
      ),
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(row[0]),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(row[1]),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _money(int cents) {
    final amount = cents / 100;
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}