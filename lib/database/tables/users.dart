import 'package:drift/drift.dart';

import 'accounts.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get accountId =>
      integer().references(Accounts, #id)();

  TextColumn get name => text()();

  TextColumn get email => text().nullable()();

  TextColumn get role => text()();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}