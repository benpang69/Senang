import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/database/database.dart';
import 'package:senang_aa/models/daily_closing_data.dart';
import 'package:senang_aa/repositories/daily_closing_repository.dart';

void main() {
  late AppDatabase database;
  late DailyClosingRepository closingRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    closingRepository = DailyClosingRepository(database);
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

  test('createClosing creates a daily closing', () async {
    final boothId = await createTestBooth();
    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    final closingDate = DateTime(2026, 9, 11);

    final closingId = await closingRepository.createClosing(
      DailyClosingData(
        boothId: boothId,
        closedByUserId: userId,
        closingDate: closingDate,
        openingCash: 5000,
        cashSales: 12000,
        cashExpenses: 2000,
        totalSales: 15000,
        totalExpenses: 3000,
        expectedCash: 15000,
        actualCash: 14800,
        cashDifference: -200,
        notes: 'Short by RM2',
      ),
    );

    final closing = await database.select(database.dailyClosings).getSingle();

    expect(closing.id, closingId);
    expect(closing.boothId, boothId);
    expect(closing.closedByUserId, userId);
    expect(closing.openingCash, 5000);
    expect(closing.cashSales, 12000);
    expect(closing.cashExpenses, 2000);
    expect(closing.totalSales, 15000);
    expect(closing.totalExpenses, 3000);
    expect(closing.expectedCash, 15000);
    expect(closing.actualCash, 14800);
    expect(closing.cashDifference, -200);
    expect(closing.notes, 'Short by RM2');
  });

  test('getClosing returns closing for requested date', () async {
    final boothId = await createTestBooth();
    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    final closingDate = DateTime(2026, 9, 11);

    await closingRepository.createClosing(
      DailyClosingData(
        boothId: boothId,
        closedByUserId: userId,
        closingDate: closingDate,
        openingCash: 5000,
        cashSales: 10000,
        cashExpenses: 1000,
        totalSales: 10000,
        totalExpenses: 1000,
        expectedCash: 14000,
        actualCash: 14000,
        cashDifference: 0,
      ),
    );

    final closing = await closingRepository.getClosing(
      boothId: boothId,
      date: DateTime(2026, 9, 11),
    );

    expect(closing, isNotNull);
    expect(closing!.boothId, boothId);
    expect(closing.closingDate, closingDate);
  });

  test('getClosing returns null when there is no closing', () async {
    final boothId = await createTestBooth();

    final closing = await closingRepository.getClosing(
      boothId: boothId,
      date: DateTime(2026, 9, 11),
    );

    expect(closing, isNull);
  });

  test('getClosing does not return closing from another booth', () async {
    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final booth1 = await database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Booth 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final booth2 = await database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Booth 2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final userId = await createTestUser(accountId);
    final closingDate = DateTime(2026, 9, 11);

    await closingRepository.createClosing(
      DailyClosingData(
        boothId: booth1,
        closedByUserId: userId,
        closingDate: closingDate,
        openingCash: 5000,
        cashSales: 10000,
        cashExpenses: 1000,
        totalSales: 10000,
        totalExpenses: 1000,
        expectedCash: 14000,
        actualCash: 14000,
        cashDifference: 0,
      ),
    );

    final closing = await closingRepository.getClosing(
      boothId: booth2,
      date: closingDate,
    );

    expect(closing, isNull);
  });

  test('getClosingsByBooth returns closings for the booth', () async {
    final boothId = await createTestBooth();
    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    await closingRepository.createClosing(
      DailyClosingData(
        boothId: boothId,
        closedByUserId: userId,
        closingDate: DateTime(2026, 9, 10),
        openingCash: 5000,
        cashSales: 10000,
        cashExpenses: 1000,
        totalSales: 10000,
        totalExpenses: 1000,
        expectedCash: 14000,
        actualCash: 14000,
        cashDifference: 0,
      ),
    );

    await closingRepository.createClosing(
      DailyClosingData(
        boothId: boothId,
        closedByUserId: userId,
        closingDate: DateTime(2026, 9, 11),
        openingCash: 5000,
        cashSales: 12000,
        cashExpenses: 2000,
        totalSales: 15000,
        totalExpenses: 3000,
        expectedCash: 15000,
        actualCash: 15000,
        cashDifference: 0,
      ),
    );

    final closings = await closingRepository.getClosingsByBooth(boothId);

    expect(closings.length, 2);
    expect(
      closings.map((closing) => closing.closingDate),
      containsAll(<DateTime>[DateTime(2026, 9, 10), DateTime(2026, 9, 11)]),
    );
  });

  test(
    'getClosingsByBooth returns empty list when there are no closings',
    () async {
      final boothId = await createTestBooth();

      final closings = await closingRepository.getClosingsByBooth(boothId);

      expect(closings, isEmpty);
    },
  );
  test(
    'createClosing rejects duplicate closing for the same booth and date',
    () async {
      final boothId = await createTestBooth();
      final account = await database.select(database.accounts).getSingle();
      final userId = await createTestUser(account.id);

      final closingDate = DateTime(2026, 9, 11);

      final data = DailyClosingData(
        boothId: boothId,
        closedByUserId: userId,
        closingDate: closingDate,
        openingCash: 5000,
        cashSales: 10000,
        cashExpenses: 1000,
        totalSales: 10000,
        totalExpenses: 1000,
        expectedCash: 14000,
        actualCash: 14000,
        cashDifference: 0,
      );

      await closingRepository.createClosing(data);

      expect(
        () => closingRepository.createClosing(data),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test('getClosing does not match the previous day', () async {
    final boothId = await createTestBooth();
    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    await closingRepository.createClosing(
      DailyClosingData(
        boothId: boothId,
        closedByUserId: userId,
        closingDate: DateTime(2026, 9, 11),
        openingCash: 5000,
        cashSales: 10000,
        cashExpenses: 1000,
        totalSales: 10000,
        totalExpenses: 1000,
        expectedCash: 14000,
        actualCash: 14000,
        cashDifference: 0,
      ),
    );

    final closing = await closingRepository.getClosing(
      boothId: boothId,
      date: DateTime(2026, 9, 10),
    );

    expect(closing, isNull);
  });

  test('getClosing does not match the next day', () async {
    final boothId = await createTestBooth();
    final account = await database.select(database.accounts).getSingle();
    final userId = await createTestUser(account.id);

    await closingRepository.createClosing(
      DailyClosingData(
        boothId: boothId,
        closedByUserId: userId,
        closingDate: DateTime(2026, 9, 11),
        openingCash: 5000,
        cashSales: 10000,
        cashExpenses: 1000,
        totalSales: 10000,
        totalExpenses: 1000,
        expectedCash: 14000,
        actualCash: 14000,
        cashDifference: 0,
      ),
    );

    final closing = await closingRepository.getClosing(
      boothId: boothId,
      date: DateTime(2026, 9, 12),
    );

    expect(closing, isNull);
  });
}
