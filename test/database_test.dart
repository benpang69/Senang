import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/database/database.dart';
void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('can complete a POS sale and update stock', () async {
    final now = DateTime.now();

    // Create account
    final accountId = await database.into(database.accounts).insert(
          AccountsCompanion.insert(
            name: 'Senang Test Business',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Create booth
    final boothId = await database.into(database.booths).insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Main Booth',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Create product
    final productId = await database.into(database.products).insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Iced Coffee',
            price: 850,
            costPrice: const Value(300),
            stockQuantity: const Value(20),
            lowStockThreshold: const Value(5),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Perform the entire sale inside one transaction.
    await database.transaction(() async {
      // Create sale
      final saleId = await database.into(database.sales).insert(
            SalesCompanion.insert(
              boothId: boothId,
              subtotal: 1700,
              total: 1700,
              paymentMethod: 'cash',
              status: 'completed',
              createdAt: now,
            ),
          );

      // Create sale item
      await database.into(database.saleItems).insert(
            SaleItemsCompanion.insert(
              saleId: saleId,
              productId: Value(productId),
              productName: 'Iced Coffee',
              quantity: 2,
              unitPrice: 850,
              costPrice: Value(300),
              subtotal: 1700,
            ),
          );

      // Reduce stock
      await (database.update(database.products)
            ..where((tbl) => tbl.id.equals(productId)))
          .write(
        ProductsCompanion(
          stockQuantity: const Value(18),
          updatedAt: Value(now),
        ),
      );

      // Record stock movement
      await database.into(database.stockMovements).insert(
            StockMovementsCompanion.insert(
              boothId: boothId,
              productId: productId,
              movementType: 'sale',
              quantity: -2,
              referenceType: const Value('sale'),
              referenceId: Value(saleId),
              createdAt: now,
            ),
          );
    });

    // Check product stock
    final product = await (database.select(database.products)
          ..where((tbl) => tbl.id.equals(productId)))
        .getSingle();

    expect(product.stockQuantity, 18);

    // Check sale
    final sales = await database.select(database.sales).get();

    expect(sales.length, 1);
    expect(sales.first.total, 1700);
    expect(sales.first.paymentMethod, 'cash');

    // Check sale item
    final saleItems = await database.select(database.saleItems).get();

    expect(saleItems.length, 1);
    expect(saleItems.first.quantity, 2);
    expect(saleItems.first.unitPrice, 850);
    expect(saleItems.first.subtotal, 1700);

    // Check stock movement
    final movements =
        await database.select(database.stockMovements).get();

    expect(movements.length, 1);
    expect(movements.first.quantity, -2);
    expect(movements.first.movementType, 'sale');
  });
}