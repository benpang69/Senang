import '../database/database.dart';
import '../models/daily_closing_data.dart';
import '../repositories/daily_closing_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/sales_repository.dart';

class DailyClosingService {
  final AppDatabase database;
  final DailyClosingRepository closingRepository;
  final SalesRepository salesRepository;
  final ExpenseRepository expenseRepository;

  DailyClosingService(
    this.database, {
    DailyClosingRepository? closingRepository,
    SalesRepository? salesRepository,
    ExpenseRepository? expenseRepository,
  }) : closingRepository =
           closingRepository ?? DailyClosingRepository(database),
       salesRepository = salesRepository ?? SalesRepository(database),
       expenseRepository = expenseRepository ?? ExpenseRepository(database);

  Future<DailyClosingData> calculateClosing({
    required int boothId,
    required int userId,
    required DateTime date,
    required int openingCash,
    required int actualCash,
    String? notes,
  }) async {
    if (openingCash < 0) {
      throw ArgumentError('Opening cash cannot be negative.');
    }

    if (actualCash < 0) {
      throw ArgumentError('Actual cash cannot be negative.');
    }

    final sales = await salesRepository.getSalesByDate(
      boothId: boothId,
      date: date,
    );

    final expenses = await expenseRepository.getExpensesByDate(
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

    final cashExpenses = totalExpenses;

    final expectedCash = openingCash + cashSales - cashExpenses;

    final cashDifference = actualCash - expectedCash;

    return DailyClosingData(
      boothId: boothId,
      closedByUserId: userId,
      closingDate: DateTime(date.year, date.month, date.day),
      openingCash: openingCash,
      cashSales: cashSales,
      cashExpenses: cashExpenses,
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      expectedCash: expectedCash,
      actualCash: actualCash,
      cashDifference: cashDifference,
      notes: notes,
    );
  }

  Future<int> closeDay({
    required int boothId,
    required int userId,
    required DateTime date,
    required int openingCash,
    required int actualCash,
    String? notes,
  }) async {
    final existingClosing = await closingRepository.getClosing(
      boothId: boothId,
      date: date,
    );

    if (existingClosing != null) {
      throw StateError('This booth has already been closed for this date.');
    }

    final closing = await calculateClosing(
      boothId: boothId,
      userId: userId,
      date: date,
      openingCash: openingCash,
      actualCash: actualCash,
      notes: notes,
    );

    return closingRepository.createClosing(closing);
  }
}
