import 'package:drift/drift.dart';

import 'booths.dart';

class CustomFields extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get boothId =>
      integer().references(Booths, #id)();

  TextColumn get name => text()();

  TextColumn get fieldType => text()();

  BoolColumn get isRequired =>
      boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}