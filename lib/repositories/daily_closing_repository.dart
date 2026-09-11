import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/daily_closing_data.dart';

class DailyClosingRepository {
  final AppDatabase database;

  DailyClosingRepository(this.database);

  Future<int> createClosing(DailyClosingData data) {
    return database
        .into(database.dailyClosings)
        .insert(
          DailyClosingsCompanion.insert(
            boothId: data.boothId,
            closedByUserId: data.closedByUserId,
            closingDate: data.closingDate,
            openingCash: data.openingCash,
            cashSales: data.cashSales,
            cashExpenses: data.cashExpenses,
            totalSales: data.totalSales,
            totalExpenses: data.totalExpenses,
            expectedCash: data.expectedCash,
            actualCash: data.actualCash,
            cashDifference: data.cashDifference,
            notes: Value<String?>(data.notes),
            closedAt: DateTime.now(),
          ),
        );
  }

  Future<DailyClosing?> getClosing({
    required int boothId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (database.select(database.dailyClosings)
          ..where((tbl) => tbl.boothId.equals(boothId))
          ..where(
            (tbl) =>
                tbl.closingDate.isBiggerOrEqualValue(startOfDay) &
                tbl.closingDate.isSmallerThanValue(endOfDay),
          ))
        .getSingleOrNull();
  }

  Future<List<DailyClosing>> getClosingsByBooth(int boothId) {
    return (database.select(database.dailyClosings)
          ..where((tbl) => tbl.boothId.equals(boothId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.closingDate,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }
}
