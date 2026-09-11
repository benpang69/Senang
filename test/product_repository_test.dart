import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:senang_aa/database/database.dart';
import 'package:senang_aa/repositories/product_repository.dart';

void main() {
  late AppDatabase database;
  late ProductRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ProductRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and retrieves a product', () async {
    final accountId = await database.into(database.accounts).insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final boothId = await database.into(database.booths).insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Test Booth',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final productId = await repository.createProduct(
      boothId: boothId,
      name: 'Iced Coffee',
      price: 850,
      stockQuantity: 20,
    );

    final product = await repository.getProduct(
      boothId: boothId,
      productId: productId,
    );

    expect(product.name, 'Iced Coffee');
    expect(product.price, 850);
    expect(product.stockQuantity, 20);
  });

  test('updates product stock', () async {
    final accountId = await database.into(database.accounts).insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final boothId = await database.into(database.booths).insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Test Booth',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final productId = await repository.createProduct(
      boothId: boothId,
      name: 'Burger',
      price: 1200,
      stockQuantity: 10,
    );

    final rowsUpdated = await repository.updateStock(
      productId: productId,
      newStockQuantity: 7,
    );

    expect(rowsUpdated, 1);

    final product = await repository.getProduct(
      boothId: boothId,
      productId: productId,
    );

    expect(product.stockQuantity, 7);
  });

  test('deactivates a product', () async {
    final accountId = await database.into(database.accounts).insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final boothId = await database.into(database.booths).insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Test Booth',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final productId = await repository.createProduct(
      boothId: boothId,
      name: 'Coke',
      price: 300,
      stockQuantity: 30,
    );

    await repository.deactivateProduct(productId);

    final products = await repository.getProductsByBooth(boothId);

    expect(products, isEmpty);
  });
}