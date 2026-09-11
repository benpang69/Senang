import 'package:drift/drift.dart';

import 'accounts.dart';

class Booths extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get accountId =>
      integer().references(Accounts, #id)();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}