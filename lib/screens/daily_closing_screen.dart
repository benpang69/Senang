import 'package:flutter/material.dart';

import '../database/database.dart';
import '../services/daily_closing_service.dart';
import '../services/daily_report_service.dart';
import 'daily_report_screen.dart';

class DailyClosingScreen extends StatefulWidget {
  final AppDatabase database;
  final int boothId;
  final int userId;

  const DailyClosingScreen({
    super.key,
    required this.database,
    required this.boothId,
    required this.userId,
  });

  @override
  State<DailyClosingScreen> createState() => _DailyClosingScreenState();
}

class _DailyClosingScreenState extends State<DailyClosingScreen> {
  final openingCashController = TextEditingController();
  final actualCashController = TextEditingController();

  late final DailyClosingService closingService;
  late final DailyReportService reportService;

  bool isLoading = false;

  int totalSales = 0;
  int totalExpenses = 0;
  int cashSales = 0;
  int cashExpenses = 0;
  int expectedCash = 0;

  @override
  void initState() {
    super.initState();

    closingService = DailyClosingService(widget.database);

    reportService = DailyReportService(widget.database);

    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      isLoading = true;
    });

    try {
      final report = await reportService.generateDailyReport(
        boothId: widget.boothId,
        date: DateTime.now(),
      );

      if (!mounted) return;

      setState(() {
        totalSales = report.totalSales;
        totalExpenses = report.totalExpenses;
        cashSales = report.cashSales;
        cashExpenses = report.cashExpenses;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _closeDay() async {
    final openingCash = _parseMoney(openingCashController.text);

    final actualCash = _parseMoney(actualCashController.text);

    if (openingCash == null || actualCash == null) {
      _showMessage('Please enter valid cash amounts.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await closingService.closeDay(
        boothId: widget.boothId,
        userId: widget.userId,
        date: DateTime.now(),
        openingCash: openingCash,
        actualCash: actualCash,
      );

      if (!mounted) return;

      _showMessage('Day closed successfully.');

      await _openReport();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openReport() async {
    final report = await reportService.generateDailyReport(
      boothId: widget.boothId,
      date: DateTime.now(),
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DailyReportScreen(report: report)),
    );
  }

  int? _parseMoney(String value) {
    final cleaned = value
        .trim()
        .replaceAll('RM', '')
        .replaceAll(',', '')
        .trim();

    final amount = double.tryParse(cleaned);

    if (amount == null) {
      return null;
    }

    if (amount < 0) {
      return null;
    }

    return (amount * 100).round();
  }

  String _money(int cents) {
    return 'RM ${(cents / 100).toStringAsFixed(2)}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    openingCashController.dispose();
    actualCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Closing')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Today\'s Summary',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 16),

                  _summaryRow('Total Sales', _money(totalSales)),

                  _summaryRow('Total Expenses', _money(totalExpenses)),

                  _summaryRow('Cash Sales', _money(cashSales)),

                  _summaryRow('Cash Expenses', _money(cashExpenses)),

                  const SizedBox(height: 24),

                  TextField(
                    controller: openingCashController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Opening Cash',
                      prefixText: 'RM ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      _updateExpectedCash();
                    },
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: actualCashController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Actual Cash',
                      prefixText: 'RM ',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _summaryRow('Expected Cash', _money(expectedCash)),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _closeDay,
                    child: const Text('Close Day'),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: _openReport,
                    child: const Text('View Report'),
                  ),
                ],
              ),
            ),
    );
  }

  void _updateExpectedCash() {
    final openingCash = _parseMoney(openingCashController.text);

    if (openingCash == null) {
      setState(() {
        expectedCash = 0;
      });
      return;
    }

    setState(() {
      expectedCash = openingCash + cashSales - cashExpenses;
    });
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
