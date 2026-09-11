import 'package:drift/drift.dart';

import 'booths.dart';
import 'users.dart';

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get boothId =>
      integer().references(Booths, #id)();

  IntColumn get userId =>
      integer().nullable().references(Users, #id)();

  IntColumn get subtotal => integer()();

  IntColumn get discount =>
      integer().withDefault(const Constant(0))();

  IntColumn get total => integer()();

  TextColumn get paymentMethod => text()();

  TextColumn get status => text()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}