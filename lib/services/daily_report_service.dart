import '../database/database.dart';
import '../models/daily_report_data.dart';
import '../repositories/daily_closing_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/sales_repository.dart';

class DailyReportService {
  final AppDatabase database;
  final DailyClosingRepository closingRepository;
  final SalesRepository salesRepository;
  final ExpenseRepository expenseRepository;

  DailyReportService(
    this.database, {
    DailyClosingRepository? closingRepository,
    SalesRepository? salesRepository,
    ExpenseRepository? expenseRepository,
  }) : closingRepository =
           closingRepository ?? DailyClosingRepository(database),
       salesRepository = salesRepository ?? SalesRepository(database),
       expenseRepository = expenseRepository ?? ExpenseRepository(database);

  Future<DailyReportData> generateDailyReport({
    required int boothId,
    required DateTime date,
  }) async {
    final booth = await (database.select(
      database.booths,
    )..where((tbl) => tbl.id.equals(boothId))).getSingle();

    final sales = await salesRepository.getSalesByDate(
      boothId: boothId,
      date: date,
    );

    final expenses = await expenseRepository.getExpensesByDate(
      boothId: boothId,
      date: date,
    );

    final closing = await closingRepository.getClosing(
      boothId: boothId,
      date: date,
    );

    var totalSales = 0;
    var cashSales = 0;

    for (final sale in sales) {
      totalSales += sale.total;

      if (sale.paymentMethod.toLowerCase() == 'cash') {
        cashSales += sale.total;
      }
    }

    var totalExpenses = 0;

    for (final expense in expenses) {
      totalExpenses += expense.amount;
    }

    final openingCash = closing?.openingCash ?? 0;
    final cashExpenses = closing?.cashExpenses ?? totalExpenses;
    final expectedCash =
        closing?.expectedCash ?? (openingCash + cashSales - cashExpenses);
    final actualCash = closing?.actualCash ?? 0;
    final cashDifference =
        closing?.cashDifference ?? (actualCash - expectedCash);

    return DailyReportData(
      boothId: boothId,
      boothName: booth.name,
      reportDate: DateTime(date.year, date.month, date.day),
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      salesCount: sales.length,
      expenseCount: expenses.length,
      openingCash: openingCash,
      cashSales: cashSales,
      cashExpenses: cashExpenses,
      expectedCash: expectedCash,
      actualCash: actualCash,
      cashDifference: cashDifference,
      notes: closing?.notes,
    );
  }
}
