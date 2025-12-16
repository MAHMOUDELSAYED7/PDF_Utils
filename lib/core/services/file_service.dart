import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'dart:developer';

class FileService {
  Future<Directory> getDownloadDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } catch (e) {
        log('Error accessing Download directory: $e');
        directory = await getExternalStorageDirectory();
        directory ??= await getApplicationDocumentsDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    return directory;
  }

  String generateFileName({String prefix = 'document', String extension = 'pdf'}) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  Future<bool> fileExists(String path) async {
    final file = File(path);
    return await file.exists();
  }

  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
