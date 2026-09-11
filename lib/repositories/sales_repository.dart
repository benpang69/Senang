import 'package:drift/drift.dart';

import '../database/database.dart';

class SalesRepository {
  final AppDatabase database;

  SalesRepository(this.database);

  Future<List<Sale>> getSalesByBooth(int boothId) {
    return (database.select(database.sales)
          ..where((tbl) => tbl.boothId.equals(boothId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<Sale> getSale({required int boothId, required int saleId}) {
    return (database.select(database.sales)
          ..where((tbl) => tbl.id.equals(saleId))
          ..where((tbl) => tbl.boothId.equals(boothId)))
        .getSingle();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) {
    return (database.select(
      database.saleItems,
    )..where((tbl) => tbl.saleId.equals(saleId))).get();
  }

  Future<List<Sale>> getSalesByDate({
    required int boothId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (database.select(database.sales)
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

  Future<int> getDailySalesTotal({
    required int boothId,
    required DateTime date,
  }) async {
    final sales = await getSalesByDate(boothId: boothId, date: date);

    var total = 0;

    for (final sale in sales) {
      total += sale.total;
    }

    return total;
  }

  Future<int> getDailySalesCount({
    required int boothId,
    required DateTime date,
  }) async {
    final sales = await getSalesByDate(boothId: boothId, date: date);

    return sales.length;
  }
}
