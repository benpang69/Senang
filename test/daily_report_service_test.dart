import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/database/database.dart';
import 'package:senang_aa/services/daily_report_service.dart';

void main() {
  late AppDatabase database;
  late DailyReportService reportService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    reportService = DailyReportService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createTestAccount() {
    return database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Test Account',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<int> createTestBooth(int accountId) {
    return database
        .into(database.booths)
        .insert(
          BoothsCompanion.insert(
            accountId: accountId,
            name: 'Main Booth',
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

  test(
    'generateDailyReport combines sales, expenses and closing data',
    () async {
      final accountId = await createTestAccount();
      final boothId = await createTestBooth(accountId);
      final userId = await createTestUser(accountId);

      final date = DateTime(2026, 9, 11);

      await database
          .into(database.sales)
          .insert(
            SalesCompanion.insert(
              boothId: boothId,
              userId: Value(userId),
              subtotal: 10000,
              total: 10000,
              paymentMethod: 'cash',
              status: 'completed',
              createdAt: DateTime(2026, 9, 11, 10, 0),
            ),
          );

      await database
          .into(database.sales)
          .insert(
            SalesCompanion.insert(
              boothId: boothId,
              userId: Value(userId),
              subtotal: 5000,
              total: 5000,
              paymentMethod: 'card',
              status: 'completed',
              createdAt: DateTime(2026, 9, 11, 12, 0),
            ),
          );

      await database
          .into(database.expenses)
          .insert(
            ExpensesCompanion.insert(
              boothId: boothId,
              userId: Value(userId),
              category: 'Supplies',
              description: 'Packaging',
              amount: 2000,
              createdAt: DateTime(2026, 9, 11, 13, 0),
            ),
          );

      await database
          .into(database.dailyClosings)
          .insert(
            DailyClosingsCompanion.insert(
              boothId: boothId,
              closedByUserId: userId,
              closingDate: date,
              openingCash: 5000,
              cashSales: 10000,
              cashExpenses: 2000,
              totalSales: 15000,
              totalExpenses: 2000,
              expectedCash: 13000,
              actualCash: 12800,
              cashDifference: -200,
              notes: const Value('RM2 shortage'),
              closedAt: DateTime(2026, 9, 11, 20, 0),
            ),
          );

      final report = await reportService.generateDailyReport(
        boothId: boothId,
        date: date,
      );

      expect(report.boothId, boothId);
      expect(report.boothName, 'Main Booth');
      expect(report.reportDate, date);

      expect(report.totalSales, 15000);
      expect(report.salesCount, 2);

      expect(report.totalExpenses, 2000);
      expect(report.expenseCount, 1);

      expect(report.openingCash, 5000);
      expect(report.cashSales, 10000);
      expect(report.cashExpenses, 2000);
      expect(report.expectedCash, 13000);
      expect(report.actualCash, 12800);
      expect(report.cashDifference, -200);

      expect(report.notes, 'RM2 shortage');
    },
  );

  test('generateDailyReport handles a day with no closing', () async {
    final accountId = await createTestAccount();
    final boothId = await createTestBooth(accountId);

    final date = DateTime(2026, 9, 11);

    await database
        .into(database.sales)
        .insert(
          SalesCompanion.insert(
            boothId: boothId,
            subtotal: 5000,
            total: 5000,
            paymentMethod: 'cash',
            status: 'completed',
            createdAt: DateTime(2026, 9, 11, 10, 0),
          ),
        );

    await database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            boothId: boothId,
            category: 'Transport',
            description: 'Delivery',
            amount: 1000,
            createdAt: DateTime(2026, 9, 11, 12, 0),
          ),
        );

    final report = await reportService.generateDailyReport(
      boothId: boothId,
      date: date,
    );

    expect(report.totalSales, 5000);
    expect(report.salesCount, 1);

    expect(report.totalExpenses, 1000);
    expect(report.expenseCount, 1);

    expect(report.openingCash, 0);
    expect(report.cashSales, 5000);
    expect(report.cashExpenses, 1000);

    expect(report.expectedCash, 4000);
    expect(report.actualCash, 0);
    expect(report.cashDifference, -4000);

    expect(report.notes, isNull);
  });

  test('generateDailyReport excludes sales from another date', () async {
    final accountId = await createTestAccount();
    final boothId = await createTestBooth(accountId);

    await database
        .into(database.sales)
        .insert(
          SalesCompanion.insert(
            boothId: boothId,
            subtotal: 5000,
            total: 5000,
            paymentMethod: 'cash',
            status: 'completed',
            createdAt: DateTime(2026, 9, 10, 23, 59),
          ),
        );

    await database
        .into(database.sales)
        .insert(
          SalesCompanion.insert(
            boothId: boothId,
            subtotal: 7000,
            total: 7000,
            paymentMethod: 'cash',
            status: 'completed',
            createdAt: DateTime(2026, 9, 11, 10, 0),
          ),
        );

    final report = await reportService.generateDailyReport(
      boothId: boothId,
      date: DateTime(2026, 9, 11),
    );

    expect(report.totalSales, 7000);
    expect(report.salesCount, 1);
  });

  test('generateDailyReport excludes expenses from another date', () async {
    final accountId = await createTestAccount();
    final boothId = await createTestBooth(accountId);

    await database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            boothId: boothId,
            category: 'Supplies',
            description: 'Previous day',
            amount: 5000,
            createdAt: DateTime(2026, 9, 10, 23, 59),
          ),
        );

    await database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            boothId: boothId,
            category: 'Supplies',
            description: 'Current day',
            amount: 2000,
            createdAt: DateTime(2026, 9, 11, 10, 0),
          ),
        );

    final report = await reportService.generateDailyReport(
      boothId: boothId,
      date: DateTime(2026, 9, 11),
    );

    expect(report.totalExpenses, 2000);
    expect(report.expenseCount, 1);
  });

  test(
    'generateDailyReport keeps cash sales separate from card sales',
    () async {
      final accountId = await createTestAccount();
      final boothId = await createTestBooth(accountId);

      await database
          .into(database.sales)
          .insert(
            SalesCompanion.insert(
              boothId: boothId,
              subtotal: 3000,
              total: 3000,
              paymentMethod: 'cash',
              status: 'completed',
              createdAt: DateTime(2026, 9, 11, 10, 0),
            ),
          );

      await database
          .into(database.sales)
          .insert(
            SalesCompanion.insert(
              boothId: boothId,
              subtotal: 7000,
              total: 7000,
              paymentMethod: 'card',
              status: 'completed',
              createdAt: DateTime(2026, 9, 11, 11, 0),
            ),
          );

      final report = await reportService.generateDailyReport(
        boothId: boothId,
        date: DateTime(2026, 9, 11),
      );

      expect(report.totalSales, 10000);
      expect(report.cashSales, 3000);
    },
  );
}
