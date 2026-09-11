import 'package:drift/drift.dart';

import 'sales.dart';
import 'products.dart';

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get saleId =>
      integer().references(Sales, #id)();

  IntColumn get productId =>
      integer().nullable().references(Products, #id)();

  TextColumn get productName => text()();

  IntColumn get quantity => integer()();

  IntColumn get unitPrice => integer()();

  IntColumn get costPrice => integer().nullable()();

  IntColumn get subtotal => integer()();
}