import 'dart:typed_data';

import 'backup_file_io.dart'
    if (dart.library.html) 'backup_file_web.dart'
    as platform;

Future<String?> saveBackupFile(Uint8List bytes, String filename) =>
    platform.saveBackupFile(bytes, filename);
