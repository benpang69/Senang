import 'dart:typed_data';

import 'package:printing/printing.dart';

class DailyReportShareService {
  Future<void> preview(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  Future<void> share(Uint8List pdfBytes) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'senang_daily_report.pdf',
    );
  }
}
