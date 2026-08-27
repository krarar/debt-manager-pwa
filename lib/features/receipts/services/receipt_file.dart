import 'dart:typed_data';

import 'receipt_file_web.dart'
    if (dart.library.io) 'receipt_file_io.dart'
    as platform;

Future<String?> saveReceiptPdf(Uint8List bytes, String filename) =>
    platform.saveReceiptPdf(bytes, filename);
