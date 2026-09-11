import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/models/daily_report_data.dart';
import 'package:senang_aa/services/daily_report_pdf_service.dart';

void main() {
  late DailyReportPdfService pdfService;

  setUp(() {
    pdfService = DailyReportPdfService();
  });

  test('generate creates PDF bytes', () async {
    final report = DailyReportData(
      boothId: 1,
      boothName: 'Main Booth',
      reportDate: DateTime(2026, 9, 11),
      totalSales: 15000,
      totalExpenses: 3000,
      salesCount: 10,
      expenseCount: 3,
      openingCash: 5000,
      cashSales: 12000,
      cashExpenses: 2000,
      expectedCash: 15000,
      actualCash: 14800,
      cashDifference: -200,
      notes: 'RM2 shortage',
    );

    final pdfBytes = await pdfService.generate(report);

    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(100));
  });

  test('generate creates PDF without notes', () async {
    final report = DailyReportData(
      boothId: 1,
      boothName: 'Main Booth',
      reportDate: DateTime(2026, 9, 11),
      totalSales: 10000,
      totalExpenses: 1000,
      salesCount: 5,
      expenseCount: 1,
      openingCash: 5000,
      cashSales: 10000,
      cashExpenses: 1000,
      expectedCash: 14000,
      actualCash: 14000,
      cashDifference: 0,
    );

    final pdfBytes = await pdfService.generate(report);

    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(100));
  });
}