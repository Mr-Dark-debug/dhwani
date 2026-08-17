import 'package:dhwani/core/updater/app_update_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUpdateService version checks', () {
    test('correctly identifies newer semantic versions', () {
      expect(AppUpdateService.isNewerVersion('v1.1.0', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('v2.0.0', '1.0.0+2'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.1.0-beta', '1.0.0'), isTrue);
    });

    test('correctly identifies older or equal versions', () {
      expect(AppUpdateService.isNewerVersion('v1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.0.0', '1.0.0+2'), isFalse);
      expect(AppUpdateService.isNewerVersion('v0.9.9', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('0.8.0', '1.0.0'), isFalse);
    });

    test('formats release size properly', () {
      const release = AppReleaseInfo(
        version: '1.1.0',
        tagName: 'v1.1.0',
        title: 'New Release',
        notes: 'Changelog',
        downloadUrl: 'https://example.com/app.apk',
        apkFileName: 'app-release.apk',
        apkSizeBytes: 26214400, // 25 MB
      );
      expect(release.formattedSize, '25.0 MB');
    });
  });
}
