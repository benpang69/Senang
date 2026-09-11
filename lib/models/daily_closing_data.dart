class DailyClosingData {
  final int boothId;
  final int closedByUserId;
  final DateTime closingDate;
  final int openingCash;
  final int cashSales;
  final int cashExpenses;
  final int totalSales;
  final int totalExpenses;
  final int expectedCash;
  final int actualCash;
  final int cashDifference;
  final String? notes;

  DailyClosingData({
    required this.boothId,
    required this.closedByUserId,
    required this.closingDate,
    required this.openingCash,
    required this.cashSales,
    required this.cashExpenses,
    required this.totalSales,
    required this.totalExpenses,
    required this.expectedCash,
    required this.actualCash,
    required this.cashDifference,
    this.notes,
  });
}
