import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveReceiptPdf(Uint8List bytes, String filename) async {
  final documents = await getApplicationDocumentsDirectory();
  final directory = Directory(
    '${documents.path}${Platform.pathSeparator}Qisti'
    '${Platform.pathSeparator}Receipts',
  );
  await directory.create(recursive: true);
  final safeName = filename.replaceAll(RegExp(r'[^\w.-]'), '_');
  final file = File('${directory.path}${Platform.pathSeparator}$safeName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
