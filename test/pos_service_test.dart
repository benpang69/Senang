import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/database/database.dart';
import 'package:senang_aa/models/cart_item.dart';
import 'package:senang_aa/services/pos_services.dart';

void main() {
  late AppDatabase database;
  late PosService posService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    posService = PosService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates a multi-item sale and updates stock', () async {
    final now = DateTime.now();

    // Create account
    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Test Business',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Create booth
    final boothId = await database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Main Booth',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Create Iced Coffee
    final coffeeId = await database
        .into(database.products)
        .insert(
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

    // Create Burger
    final burgerId = await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Chicken Burger',
            price: 1200,
            costPrice: const Value(500),
            stockQuantity: const Value(15),
            lowStockThreshold: const Value(5),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Create Coke
    final cokeId = await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Coke',
            price: 300,
            costPrice: const Value(100),
            stockQuantity: const Value(30),
            lowStockThreshold: const Value(5),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Checkout:
    // Iced Coffee × 2 = RM17.00
    // Chicken Burger × 1 = RM12.00
    // Coke × 2 = RM6.00
    // Subtotal = RM35.00
    final saleId = await posService.createSale(
      boothId: boothId,
      items: [
        CartItem(productId: coffeeId, quantity: 2),
        CartItem(productId: burgerId, quantity: 1),
        CartItem(productId: cokeId, quantity: 2),
      ],
      paymentMethod: 'cash',
    );

    // Check sale
    final sale = await (database.select(
      database.sales,
    )..where((tbl) => tbl.id.equals(saleId))).getSingle();

    expect(sale.subtotal, 3500);
    expect(sale.discount, 0);
    expect(sale.total, 3500);
    expect(sale.paymentMethod, 'cash');
    expect(sale.status, 'completed');

    // Check coffee stock: 20 -> 18
    final coffee = await (database.select(
      database.products,
    )..where((tbl) => tbl.id.equals(coffeeId))).getSingle();

    expect(coffee.stockQuantity, 18);

    // Check burger stock: 15 -> 14
    final burger = await (database.select(
      database.products,
    )..where((tbl) => tbl.id.equals(burgerId))).getSingle();

    expect(burger.stockQuantity, 14);

    // Check Coke stock: 30 -> 28
    final coke = await (database.select(
      database.products,
    )..where((tbl) => tbl.id.equals(cokeId))).getSingle();

    expect(coke.stockQuantity, 28);

    // Check sale items
    final saleItems = await (database.select(
      database.saleItems,
    )..where((tbl) => tbl.saleId.equals(saleId))).get();

    expect(saleItems.length, 3);

    expect(
      saleItems.any(
        (item) =>
            item.productId == coffeeId &&
            item.quantity == 2 &&
            item.subtotal == 1700,
      ),
      true,
    );

    expect(
      saleItems.any(
        (item) =>
            item.productId == burgerId &&
            item.quantity == 1 &&
            item.subtotal == 1200,
      ),
      true,
    );

    expect(
      saleItems.any(
        (item) =>
            item.productId == cokeId &&
            item.quantity == 2 &&
            item.subtotal == 600,
      ),
      true,
    );

    // Check stock movements
    final movements = await (database.select(
      database.stockMovements,
    )..where((tbl) => tbl.referenceId.equals(saleId))).get();

    expect(movements.length, 3);

    expect(
      movements.any(
        (movement) => movement.productId == coffeeId && movement.quantity == -2,
      ),
      true,
    );

    expect(
      movements.any(
        (movement) => movement.productId == burgerId && movement.quantity == -1,
      ),
      true,
    );

    expect(
      movements.any(
        (movement) => movement.productId == cokeId && movement.quantity == -2,
      ),
      true,
    );
  });

  test('rejects sale when there is not enough stock', () async {
    final now = DateTime.now();

    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Stock Test Business',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final boothId = await database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Main Booth',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final productId = await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Limited Stock Item',
            price: 1000,
            stockQuantity: const Value(2),
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(
      () => posService.createSale(
        boothId: boothId,
        items: [CartItem(productId: productId, quantity: 5)],
        paymentMethod: 'cash',
      ),
      throwsException,
    );

    // Make sure no sale was created.
    final sales = await database.select(database.sales).get();

    expect(sales, isEmpty);

    // Make sure stock was not changed.
    final product = await (database.select(
      database.products,
    )..where((tbl) => tbl.id.equals(productId))).getSingle();

    expect(product.stockQuantity, 2);
  });
  test('creates a sale with a discount', () async {
    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final boothId = await database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Test Booth',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final coffeeId = await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Iced Coffee',
            price: 850,
            stockQuantity: const Value(20),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final burgerId = await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Chicken Burger',
            price: 1200,
            stockQuantity: const Value(15),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final cokeId = await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Coke',
            price: 300,
            stockQuantity: const Value(30),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final service = PosService(database);

    final saleId = await service.createSale(
      boothId: boothId,
      items: [
        CartItem(productId: coffeeId, quantity: 2),
        CartItem(productId: burgerId, quantity: 1),
        CartItem(productId: cokeId, quantity: 2),
      ],
      paymentMethod: 'cash',
      discount: 500,
    );

    final sale = await (database.select(
      database.sales,
    )..where((tbl) => tbl.id.equals(saleId))).getSingle();

    expect(sale.subtotal, 3500);
    expect(sale.discount, 500);
    expect(sale.total, 3000);
  });
  test('rejects a negative discount', () async {
    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final boothId = await database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Test Booth',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final productId = await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Iced Coffee',
            price: 850,
            stockQuantity: const Value(20),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final service = PosService(database);

    expect(
      () => service.createSale(
        boothId: boothId,
        items: [CartItem(productId: productId, quantity: 1)],
        paymentMethod: 'cash',
        discount: -100,
      ),
      throwsArgumentError,
    );
  });

  test('rejects a discount greater than the subtotal', () async {
    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final boothId = await database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Test Booth',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final productId = await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: 'Iced Coffee',
            price: 850,
            stockQuantity: const Value(20),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final service = PosService(database);

    expect(
      () => service.createSale(
        boothId: boothId,
        items: [CartItem(productId: productId, quantity: 1)],
        paymentMethod: 'cash',
        discount: 1000,
      ),
      throwsArgumentError,
    );
  });
}
