class DailyReportData {
  final int boothId;
  final String boothName;
  final DateTime reportDate;

  final int totalSales;
  final int totalExpenses;
  final int salesCount;
  final int expenseCount;

  final int openingCash;
  final int cashSales;
  final int cashExpenses;
  final int expectedCash;
  final int actualCash;
  final int cashDifference;

  final String? notes;

  DailyReportData({
    required this.boothId,
    required this.boothName,
    required this.reportDate,
    required this.totalSales,
    required this.totalExpenses,
    required this.salesCount,
    required this.expenseCount,
    required this.openingCash,
    required this.cashSales,
    required this.cashExpenses,
    required this.expectedCash,
    required this.actualCash,
    required this.cashDifference,
    this.notes,
  });
}
