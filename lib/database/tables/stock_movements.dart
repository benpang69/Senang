import 'package:drift/drift.dart';

import 'booths.dart';
import 'products.dart';

class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get boothId =>
      integer().references(Booths, #id)();

  IntColumn get productId =>
      integer().references(Products, #id)();

  TextColumn get movementType => text()();

  IntColumn get quantity => integer()();

  TextColumn get referenceType => text().nullable()();

  IntColumn get referenceId => integer().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}