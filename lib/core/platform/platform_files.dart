import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class PlatformFiles {
  static const _channel = MethodChannel('com.prashant.dhwani/files');

  static Future<bool> export(String path, String name, String mimeType) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod<bool>('exportFile', {
            'path': path,
            'name': name,
            'mimeType': mimeType,
          }) ??
          false;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType, name: name)],
      ),
    );
    return true;
  }

  static Future<void> share(String path, String name, String mimeType) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: mimeType, name: name)],
          text: 'Recorded with Dhwani',
        ),
      );
}
