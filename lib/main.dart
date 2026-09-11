import 'package:flutter/material.dart';
import 'package:drift/drift.dart';

import 'database/database.dart';
import 'screens/daily_closing_screen.dart';

void main() {
  runApp(const SenangApp());
}

class SenangApp extends StatelessWidget {
  const SenangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppStartupScreen(),
    );
  }
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  late final AppDatabase database;

  bool isLoading = true;
  String? error;

  int? boothId;
  int? userId;

  @override
  void initState() {
    super.initState();
    _setupDemoData();
  }

  Future<void> _setupDemoData() async {
    database = AppDatabase();

    try {
      final now = DateTime.now();

      final accountId = await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Demo Account',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final createdUser = await database
          .into(database.users)
          .insertReturning(
            UsersCompanion.insert(
              accountId: accountId,
              name: 'Demo User',
              role: 'owner',
              email: const Value(null),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final createdBooth = await database
          .into(database.booths)
          .insertReturning(
            BoothsCompanion.insert(
              accountId: accountId,
              name: 'Main Booth',
              description: const Value('Demo booth'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      if (!mounted) return;

      setState(() {
        userId = createdUser.id;
        boothId = createdBooth.id;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Senang')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to start Senang:\n\n$error'),
          ),
        ),
      );
    }

    return DailyClosingScreen(
      database: database,
      boothId: boothId!,
      userId: userId!,
    );
  }
}
