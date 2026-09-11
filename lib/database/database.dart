import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';


import 'tables/accounts.dart';
import 'tables/users.dart';
import 'tables/booths.dart';
import 'tables/categories.dart';
import 'tables/products.dart';
import 'tables/custom_fields.dart';
import 'tables/product_custom_values.dart';
import 'tables/sales.dart';
import 'tables/sale_items.dart';
import 'tables/stock_movements.dart';
import 'tables/expenses.dart';
import 'tables/daily_closings.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Users,
    Booths,
    Categories,
    Products,
    CustomFields,
    ProductCustomValues,
    Sales,
    SaleItems,
    StockMovements,
    Expenses,
    DailyClosings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      p.join(directory.path, 'senang.sqlite'),
    );

    return NativeDatabase.createInBackground(file);
  });
}