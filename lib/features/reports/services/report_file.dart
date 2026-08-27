import 'dart:typed_data';

import 'report_file_io.dart'
    if (dart.library.html) 'report_file_web.dart'
    as platform;

Future<String?> saveReportFile(Uint8List bytes, String filename) =>
    platform.saveReportFile(bytes, filename);
