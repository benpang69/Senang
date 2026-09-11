import 'package:drift/drift.dart';

import 'booths.dart';
import 'users.dart';

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get boothId =>
      integer().references(Booths, #id)();

  IntColumn get userId =>
      integer().nullable().references(Users, #id)();

  TextColumn get category => text()();

  TextColumn get description => text()();

  IntColumn get amount => integer()();

  DateTimeColumn get createdAt => dateTime()();
}