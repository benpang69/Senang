import 'package:drift/drift.dart';

import 'booths.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get boothId =>
      integer().references(Booths, #id)();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}