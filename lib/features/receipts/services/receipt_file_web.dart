import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Browsers do not expose an application documents directory. The platform
/// share/download flow is the safe web equivalent of saving a local file.
Future<String?> saveReceiptPdf(Uint8List bytes, String filename) async {
  await Printing.sharePdf(bytes: bytes, filename: filename);
  return null;
}
