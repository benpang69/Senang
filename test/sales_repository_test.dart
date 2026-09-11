import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/database/database.dart';
import 'package:senang_aa/models/cart_item.dart';
import 'package:senang_aa/repositories/product_repository.dart';
import 'package:senang_aa/repositories/sales_repository.dart';
import 'package:senang_aa/services/pos_services.dart';

void main() {
  late AppDatabase database;
  late ProductRepository productRepository;
  late SalesRepository salesRepository;
  late PosService posService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    productRepository = ProductRepository(database);
    salesRepository = SalesRepository(database);
    posService = PosService(database, productRepository: productRepository);
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

  Future<int> createTestProduct({
    required int boothId,
    required String name,
    required int price,
    int stock = 20,
  }) {
    return productRepository.createProduct(
      boothId: boothId,
      name: name,
      price: price,
      stockQuantity: stock,
    );
  }

  test('getSalesByBooth returns sales for the booth', () async {
    final boothId = await createTestBooth();

    final productId = await createTestProduct(
      boothId: boothId,
      name: 'Coffee',
      price: 500,
    );

    await posService.createSale(
      boothId: boothId,
      items: [CartItem(productId: productId, quantity: 2)],
      paymentMethod: 'cash',
    );

    final sales = await salesRepository.getSalesByBooth(boothId);

    expect(sales.length, 1);
    expect(sales.first.total, 1000);
    expect(sales.first.paymentMethod, 'cash');
  });

  test('getSale returns a specific sale', () async {
    final boothId = await createTestBooth();

    final productId = await createTestProduct(
      boothId: boothId,
      name: 'Shirt',
      price: 3000,
    );

    final saleId = await posService.createSale(
      boothId: boothId,
      items: [CartItem(productId: productId, quantity: 1)],
      paymentMethod: 'card',
    );

    final sale = await salesRepository.getSale(
      boothId: boothId,
      saleId: saleId,
    );

    expect(sale.id, saleId);
    expect(sale.total, 3000);
    expect(sale.paymentMethod, 'card');
  });

  test('getSaleItems returns items belonging to a sale', () async {
    final boothId = await createTestBooth();

    final coffeeId = await createTestProduct(
      boothId: boothId,
      name: 'Coffee',
      price: 500,
    );

    final cakeId = await createTestProduct(
      boothId: boothId,
      name: 'Cake',
      price: 1000,
    );

    final saleId = await posService.createSale(
      boothId: boothId,
      items: [
        CartItem(productId: coffeeId, quantity: 2),
        CartItem(productId: cakeId, quantity: 1),
      ],
      paymentMethod: 'cash',
    );

    final items = await salesRepository.getSaleItems(saleId);

    expect(items.length, 2);

    expect(
      items.any(
        (item) =>
            item.productName == 'Coffee' &&
            item.quantity == 2 &&
            item.subtotal == 1000,
      ),
      isTrue,
    );

    expect(
      items.any(
        (item) =>
            item.productName == 'Cake' &&
            item.quantity == 1 &&
            item.subtotal == 1000,
      ),
      isTrue,
    );
  });

  test('getSalesByDate returns sales from the requested date', () async {
    final boothId = await createTestBooth();

    final productId = await createTestProduct(
      boothId: boothId,
      name: 'Coffee',
      price: 500,
    );

    await posService.createSale(
      boothId: boothId,
      items: [CartItem(productId: productId, quantity: 2)],
      paymentMethod: 'cash',
    );

    final today = DateTime.now();

    final sales = await salesRepository.getSalesByDate(
      boothId: boothId,
      date: today,
    );

    expect(sales.length, 1);
    expect(sales.first.total, 1000);
  });

  test('getDailySalesTotal returns total sales for the day', () async {
    final boothId = await createTestBooth();

    final productId = await createTestProduct(
      boothId: boothId,
      name: 'Coffee',
      price: 500,
    );

    await posService.createSale(
      boothId: boothId,
      items: [CartItem(productId: productId, quantity: 2)],
      paymentMethod: 'cash',
    );

    await posService.createSale(
      boothId: boothId,
      items: [CartItem(productId: productId, quantity: 3)],
      paymentMethod: 'cash',
    );

    final total = await salesRepository.getDailySalesTotal(
      boothId: boothId,
      date: DateTime.now(),
    );

    expect(total, 2500);
  });

  test('getDailySalesCount returns number of sales for the day', () async {
    final boothId = await createTestBooth();

    final productId = await createTestProduct(
      boothId: boothId,
      name: 'Coffee',
      price: 500,
    );

    await posService.createSale(
      boothId: boothId,
      items: [CartItem(productId: productId, quantity: 1)],
      paymentMethod: 'cash',
    );

    await posService.createSale(
      boothId: boothId,
      items: [CartItem(productId: productId, quantity: 1)],
      paymentMethod: 'cash',
    );

    final count = await salesRepository.getDailySalesCount(
      boothId: boothId,
      date: DateTime.now(),
    );

    expect(count, 2);
  });

  test('getSalesByBooth returns empty list when there are no sales', () async {
    final boothId = await createTestBooth();

    final sales = await salesRepository.getSalesByBooth(boothId);

    expect(sales, isEmpty);
  });
}
