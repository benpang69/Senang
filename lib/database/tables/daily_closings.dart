import 'package:drift/drift.dart';

import 'booths.dart';
import 'users.dart';

class DailyClosings extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get boothId =>
      integer().references(Booths, #id)();

  IntColumn get closedByUserId =>
      integer().references(Users, #id)();

  DateTimeColumn get closingDate => dateTime()();

  IntColumn get openingCash => integer()();

  IntColumn get cashSales => integer()();

  IntColumn get cashExpenses => integer()();

  IntColumn get totalSales => integer()();

  IntColumn get totalExpenses => integer()();

  IntColumn get expectedCash => integer()();

  IntColumn get actualCash => integer()();

  IntColumn get cashDifference => integer()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get closedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {boothId, closingDate},
      ];
}