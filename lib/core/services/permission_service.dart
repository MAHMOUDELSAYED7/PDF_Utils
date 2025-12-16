import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      
      if (androidInfo >= 33) {
        // Android 13+ doesn't need storage permission for app-specific directories
        return true;
      } else if (androidInfo >= 30) {
        // Android 11-12
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        // Android 10 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      return true; // iOS handles storage differently
    }
    return false;
  }

  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'(\d+)').firstMatch(version);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }
    return 0;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
