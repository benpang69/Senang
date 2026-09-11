import 'package:drift/drift.dart';

import 'booths.dart';
import 'categories.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get boothId =>
      integer().references(Booths, #id)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  TextColumn get name => text()();

  TextColumn get sku => text().nullable()();

  TextColumn get description => text().nullable()();

  IntColumn get price => integer()();

  IntColumn get costPrice => integer().nullable()();

  IntColumn get stockQuantity =>
      integer().withDefault(const Constant(0))();

  IntColumn get lowStockThreshold =>
      integer().withDefault(const Constant(0))();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}