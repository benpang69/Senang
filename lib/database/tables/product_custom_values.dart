import 'package:drift/drift.dart';

import 'products.dart';
import 'custom_fields.dart';

class ProductCustomValues extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get productId =>
      integer().references(Products, #id)();

  IntColumn get customFieldId =>
      integer().references(CustomFields, #id)();

  TextColumn get value => text()();
}