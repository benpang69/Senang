import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senang_aa/database/database.dart';
import 'package:senang_aa/repositories/expense_repository.dart';

void main() {
  late AppDatabase database;
  late ExpenseRepository expenseRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    expenseRepository = ExpenseRepository(database);
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

  test('createExpense creates an expense', () async {
    final boothId = await createTestBooth();

    final expenseId = await expenseRepository.createExpense(
      boothId: boothId,
      category: 'Supplies',
      description: 'Bought packaging',
      amount: 1500,
    );

    final expense = await expenseRepository.getExpense(
      boothId: boothId,
      expenseId: expenseId,
    );

    expect(expense.id, expenseId);
    expect(expense.category, 'Supplies');
    expect(expense.description, 'Bought packaging');
    expect(expense.amount, 1500);
  });

  test('createExpense supports userId', () async {
    final boothId = await createTestBooth();

    final account = await database.select(database.accounts).getSingle();

    final userId = await database
        .into(database.users)
        .insert(
          UsersCompanion.insert(
            accountId: account.id,
            name: 'Test User',
            role: 'staff',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final expenseId = await expenseRepository.createExpense(
      boothId: boothId,
      category: 'Transport',
      description: 'Delivery cost',
      amount: 1000,
      userId: userId,
    );

    final expense = await expenseRepository.getExpense(
      boothId: boothId,
      expenseId: expenseId,
    );

    expect(expense.userId, userId);
  });

  test('createExpense rejects zero amount', () {
    expect(
      () => expenseRepository.createExpense(
        boothId: 1,
        category: 'Supplies',
        description: 'Invalid expense',
        amount: 0,
      ),
      throwsArgumentError,
    );
  });

  test('createExpense rejects negative amount', () {
    expect(
      () => expenseRepository.createExpense(
        boothId: 1,
        category: 'Supplies',
        description: 'Invalid expense',
        amount: -500,
      ),
      throwsArgumentError,
    );
  });

  test('getExpensesByBooth returns booth expenses', () async {
    final boothId = await createTestBooth();

    await expenseRepository.createExpense(
      boothId: boothId,
      category: 'Supplies',
      description: 'Packaging',
      amount: 1000,
    );

    await expenseRepository.createExpense(
      boothId: boothId,
      category: 'Transport',
      description: 'Delivery',
      amount: 2000,
    );

    final expenses = await expenseRepository.getExpensesByBooth(boothId);

    expect(expenses.length, 2);
    expect(
      expenses.map((expense) => expense.amount),
      containsAll(<int>[1000, 2000]),
    );
  });

  test('getExpensesByDate returns expenses from the requested date', () async {
    final boothId = await createTestBooth();

    await expenseRepository.createExpense(
      boothId: boothId,
      category: 'Supplies',
      description: 'Packaging',
      amount: 1500,
    );

    final expenses = await expenseRepository.getExpensesByDate(
      boothId: boothId,
      date: DateTime.now(),
    );

    expect(expenses.length, 1);
    expect(expenses.first.amount, 1500);
  });

  test('getDailyExpenseTotal returns total expenses for the day', () async {
    final boothId = await createTestBooth();

    await expenseRepository.createExpense(
      boothId: boothId,
      category: 'Supplies',
      description: 'Packaging',
      amount: 1000,
    );

    await expenseRepository.createExpense(
      boothId: boothId,
      category: 'Transport',
      description: 'Delivery',
      amount: 2500,
    );

    final total = await expenseRepository.getDailyExpenseTotal(
      boothId: boothId,
      date: DateTime.now(),
    );

    expect(total, 3500);
  });

  test(
    'getExpensesByBooth returns empty list when there are no expenses',
    () async {
      final boothId = await createTestBooth();

      final expenses = await expenseRepository.getExpensesByBooth(boothId);

      expect(expenses, isEmpty);
    },
  );

  test('deleteExpense removes the expense', () async {
    final boothId = await createTestBooth();

    final expenseId = await expenseRepository.createExpense(
      boothId: boothId,
      category: 'Supplies',
      description: 'Packaging',
      amount: 1500,
    );

    final deleted = await expenseRepository.deleteExpense(
      boothId: boothId,
      expenseId: expenseId,
    );

    expect(deleted, 1);

    final expenses = await expenseRepository.getExpensesByBooth(boothId);

    expect(expenses, isEmpty);
  });

  test('deleteExpense does not delete an expense from another booth', () async {
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

    final expenseId = await expenseRepository.createExpense(
      boothId: booth1,
      category: 'Supplies',
      description: 'Booth 1 expense',
      amount: 1000,
    );

    final deleted = await expenseRepository.deleteExpense(
      boothId: booth2,
      expenseId: expenseId,
    );

    expect(deleted, 0);

    final expense = await expenseRepository.getExpense(
      boothId: booth1,
      expenseId: expenseId,
    );

    expect(expense.amount, 1000);
  });
}
