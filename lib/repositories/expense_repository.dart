import 'package:drift/drift.dart';

import '../database/database.dart';

class ExpenseRepository {
  final AppDatabase database;

  ExpenseRepository(this.database);

  Future<List<Expense>> getExpensesByBooth(int boothId) {
    return (database.select(database.expenses)
          ..where((tbl) => tbl.boothId.equals(boothId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<Expense> getExpense({required int boothId, required int expenseId}) {
    return (database.select(database.expenses)
          ..where((tbl) => tbl.id.equals(expenseId))
          ..where((tbl) => tbl.boothId.equals(boothId)))
        .getSingle();
  }

  Future<List<Expense>> getExpensesByDate({
    required int boothId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (database.select(database.expenses)
          ..where((tbl) => tbl.boothId.equals(boothId))
          ..where(
            (tbl) =>
                tbl.createdAt.isBiggerOrEqualValue(startOfDay) &
                tbl.createdAt.isSmallerThanValue(endOfDay),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<int> getDailyExpenseTotal({
    required int boothId,
    required DateTime date,
  }) async {
    final expenses = await getExpensesByDate(boothId: boothId, date: date);

    var total = 0;

    for (final expense in expenses) {
      total += expense.amount;
    }

    return total;
  }

  Future<int> createExpense({
    required int boothId,
    required String category,
    required String description,
    required int amount,
    int? userId,
  }) {
    if (amount <= 0) {
      throw ArgumentError('Expense amount must be greater than 0.');
    }

    return database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            boothId: boothId,
            userId: Value<int?>(userId),
            category: category,
            description: description,
            amount: amount,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<int> deleteExpense({required int boothId, required int expenseId}) {
    return (database.delete(database.expenses)
          ..where((tbl) => tbl.id.equals(expenseId))
          ..where((tbl) => tbl.boothId.equals(boothId)))
        .go();
  }
}
