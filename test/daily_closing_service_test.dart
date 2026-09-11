import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/database/database.dart';
import 'package:senang_aa/services/daily_closing_service.dart';

void main() {
  late AppDatabase database;
  late DailyClosingService closingService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    closingService = DailyClosingService(database);
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

  Future<int> createTestUser(int accountId) {
    return database
        .into(database.users)
        .insert(
          UsersCompanion.insert(
            accountId: accountId,
            name: 'Test User',
            role: 'admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<int> createTestProduct({
    required int boothId,
    required String name,
    required int price,
    int stockQuantity = 100,
  }) {
    return database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            boothId: boothId,
            name: name,
            price: price,
            stockQuantity: Value(stockQuantity),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  test('calculateClosing calculates cash and totals correctly', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    final productId = await createTestProduct(
      boothId: boothId,
      name: 'Coffee',
      price: 1000,
    );

    await database
        .into(database.sales)
        .insert(
          SalesCompanion.insert(
            boothId: boothId,
            subtotal: 3000,
            total: 3000,
            paymentMethod: 'cash',
            status: 'completed',
            createdAt: DateTime.now(),
          ),
        );

    await database
        .into(database.sales)
        .insert(
          SalesCompanion.insert(
            boothId: boothId,
            subtotal: 5000,
            total: 5000,
            paymentMethod: 'card',
            status: 'completed',
            createdAt: DateTime.now(),
          ),
        );

    await database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            boothId: boothId,
            category: 'Supplies',
            description: 'Packaging',
            amount: 1000,
            createdAt: DateTime.now(),
          ),
        );

    final closing = await closingService.calculateClosing(
      boothId: boothId,
      userId: userId,
      date: DateTime.now(),
      openingCash: 5000,
      actualCash: 7000,
    );

    expect(closing.boothId, boothId);
    expect(closing.closedByUserId, userId);

    expect(closing.totalSales, 8000);
    expect(closing.cashSales, 3000);

    expect(closing.totalExpenses, 1000);
    expect(closing.cashExpenses, 1000);

    expect(closing.expectedCash, 7000);
    expect(closing.actualCash, 7000);
    expect(closing.cashDifference, 0);

    expect(productId, greaterThan(0));
  });

  test('calculateClosing excludes non-cash sales from expected cash', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    await database
        .into(database.sales)
        .insert(
          SalesCompanion.insert(
            boothId: boothId,
            subtotal: 10000,
            total: 10000,
            paymentMethod: 'card',
            status: 'completed',
            createdAt: DateTime.now(),
          ),
        );

    final closing = await closingService.calculateClosing(
      boothId: boothId,
      userId: userId,
      date: DateTime.now(),
      openingCash: 5000,
      actualCash: 5000,
    );

    expect(closing.totalSales, 10000);
    expect(closing.cashSales, 0);
    expect(closing.expectedCash, 5000);
    expect(closing.cashDifference, 0);
  });

  test('calculateClosing calculates cash shortage correctly', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    final closing = await closingService.calculateClosing(
      boothId: boothId,
      userId: userId,
      date: DateTime.now(),
      openingCash: 5000,
      actualCash: 4500,
    );

    expect(closing.expectedCash, 5000);
    expect(closing.actualCash, 4500);
    expect(closing.cashDifference, -500);
  });

  test('calculateClosing calculates cash surplus correctly', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    final closing = await closingService.calculateClosing(
      boothId: boothId,
      userId: userId,
      date: DateTime.now(),
      openingCash: 5000,
      actualCash: 5500,
    );

    expect(closing.expectedCash, 5000);
    expect(closing.actualCash, 5500);
    expect(closing.cashDifference, 500);
  });

  test('calculateClosing rejects negative opening cash', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    expect(
      () => closingService.calculateClosing(
        boothId: boothId,
        userId: userId,
        date: DateTime.now(),
        openingCash: -100,
        actualCash: 5000,
      ),
      throwsArgumentError,
    );
  });

  test('calculateClosing rejects negative actual cash', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    expect(
      () => closingService.calculateClosing(
        boothId: boothId,
        userId: userId,
        date: DateTime.now(),
        openingCash: 5000,
        actualCash: -100,
      ),
      throwsArgumentError,
    );
  });

  test('closeDay creates a daily closing', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    final closingId = await closingService.closeDay(
      boothId: boothId,
      userId: userId,
      date: DateTime.now(),
      openingCash: 5000,
      actualCash: 5000,
    );

    final closing = await database.select(database.dailyClosings).getSingle();

    expect(closingId, closing.id);
    expect(closing.boothId, boothId);
    expect(closing.closedByUserId, userId);
    expect(closing.expectedCash, 5000);
    expect(closing.actualCash, 5000);
    expect(closing.cashDifference, 0);
  });

  test('closeDay rejects duplicate closing', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    final date = DateTime(2026, 9, 11);

    await closingService.closeDay(
      boothId: boothId,
      userId: userId,
      date: date,
      openingCash: 5000,
      actualCash: 5000,
    );

    expect(
      () => closingService.closeDay(
        boothId: boothId,
        userId: userId,
        date: date,
        openingCash: 5000,
        actualCash: 5000,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
