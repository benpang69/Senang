import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/database/database.dart';
import 'package:senang_aa/repositories/product_repository.dart';
import 'package:senang_aa/services/inventory_service.dart';

void main() {
  late AppDatabase database;
  late ProductRepository productRepository;
  late InventoryService inventoryService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    productRepository = ProductRepository(database);
    inventoryService = InventoryService(
      database,
      productRepository: productRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createTestBooth() async {
    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    return database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Test Booth',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  test('addStock increases product stock', () async {
    final boothId = await createTestBooth();

    final productId = await productRepository.createProduct(
      boothId: boothId,
      name: 'Coffee',
      price: 500,
      stockQuantity: 10,
    );

    final result = await inventoryService.addStock(
      boothId: boothId,
      productId: productId,
      quantity: 5,
    );

    expect(result, 15);

    final product = await productRepository.getProduct(
      boothId: boothId,
      productId: productId,
    );

    expect(product.stockQuantity, 15);
  });

  test('addStock creates restock movement', () async {
    final boothId = await createTestBooth();

    final productId = await productRepository.createProduct(
      boothId: boothId,
      name: 'Coffee',
      price: 500,
      stockQuantity: 10,
    );

    await inventoryService.addStock(
      boothId: boothId,
      productId: productId,
      quantity: 5,
      note: 'New stock',
    );

    final movements = await database.select(database.stockMovements).get();

    expect(movements.length, 1);
    expect(movements.first.movementType, 'restock');
    expect(movements.first.quantity, 5);
    expect(movements.first.note, 'New stock');
  });

  test('removeStock decreases product stock', () async {
    final boothId = await createTestBooth();

    final productId = await productRepository.createProduct(
      boothId: boothId,
      name: 'Shirt',
      price: 3000,
      stockQuantity: 10,
    );

    final result = await inventoryService.removeStock(
      boothId: boothId,
      productId: productId,
      quantity: 3,
    );

    expect(result, 7);

    final product = await productRepository.getProduct(
      boothId: boothId,
      productId: productId,
    );

    expect(product.stockQuantity, 7);
  });

  test('removeStock creates adjustment movement', () async {
    final boothId = await createTestBooth();

    final productId = await productRepository.createProduct(
      boothId: boothId,
      name: 'Shirt',
      price: 3000,
      stockQuantity: 10,
    );

    await inventoryService.removeStock(
      boothId: boothId,
      productId: productId,
      quantity: 3,
      note: 'Damaged item',
    );

    final movements = await database.select(database.stockMovements).get();

    expect(movements.length, 1);
    expect(movements.first.movementType, 'adjustment');
    expect(movements.first.quantity, -3);
    expect(movements.first.note, 'Damaged item');
  });

  test('removeStock rejects insufficient stock', () async {
    final boothId = await createTestBooth();

    final productId = await productRepository.createProduct(
      boothId: boothId,
      name: 'Phone Case',
      price: 1500,
      stockQuantity: 5,
    );

    expect(
      () => inventoryService.removeStock(
        boothId: boothId,
        productId: productId,
        quantity: 10,
      ),
      throwsException,
    );

    final product = await productRepository.getProduct(
      boothId: boothId,
      productId: productId,
    );

    expect(product.stockQuantity, 5);

    final movements = await database.select(database.stockMovements).get();

    expect(movements, isEmpty);
  });

  test('addStock rejects zero quantity', () async {
    expect(
      () => inventoryService.addStock(boothId: 1, productId: 1, quantity: 0),
      throwsArgumentError,
    );
  });

  test('addStock rejects negative quantity', () async {
    expect(
      () => inventoryService.addStock(boothId: 1, productId: 1, quantity: -1),
      throwsArgumentError,
    );
  });

  test('removeStock rejects zero quantity', () async {
    expect(
      () => inventoryService.removeStock(boothId: 1, productId: 1, quantity: 0),
      throwsArgumentError,
    );
  });

  test('removeStock rejects negative quantity', () async {
    expect(
      () =>
          inventoryService.removeStock(boothId: 1, productId: 1, quantity: -1),
      throwsArgumentError,
    );
  });

  test('getLowStockProducts returns low stock products', () async {
    final boothId = await createTestBooth();

    await productRepository.createProduct(
      boothId: boothId,
      name: 'Low Stock',
      price: 1000,
      stockQuantity: 2,
      lowStockThreshold: 5,
    );

    await productRepository.createProduct(
      boothId: boothId,
      name: 'Normal Stock',
      price: 2000,
      stockQuantity: 20,
      lowStockThreshold: 5,
    );

    final products = await inventoryService.getLowStockProducts(boothId);

    expect(products.length, 1);
    expect(products.first.name, 'Low Stock');
  });

  test('getLowStockProducts includes products at threshold', () async {
    final boothId = await createTestBooth();

    await productRepository.createProduct(
      boothId: boothId,
      name: 'Threshold Product',
      price: 1000,
      stockQuantity: 5,
      lowStockThreshold: 5,
    );

    final products = await inventoryService.getLowStockProducts(boothId);

    expect(products.length, 1);
    expect(products.first.name, 'Threshold Product');
  });

  test('getLowStockProducts excludes inactive products', () async {
    final boothId = await createTestBooth();

    final productId = await productRepository.createProduct(
      boothId: boothId,
      name: 'Inactive Product',
      price: 1000,
      stockQuantity: 1,
      lowStockThreshold: 5,
    );

    await productRepository.deactivateProduct(productId);

    final products = await inventoryService.getLowStockProducts(boothId);

    expect(products, isEmpty);
  });
}
