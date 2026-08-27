import 'dart:convert';
import 'dart:io';

import 'package:dhwani/core/updater/app_update_service.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateService version checks', () {
    test('correctly identifies newer semantic versions', () {
      expect(AppUpdateService.isNewerVersion('v1.1.0', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('v2.0.0', '1.0.0+2'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.1.0-beta', '1.0.0'), isFalse);
    });

    test('correctly identifies older or equal versions', () {
      expect(AppUpdateService.isNewerVersion('v1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.0.0', '1.0.0+2'), isFalse);
      expect(AppUpdateService.isNewerVersion('v0.9.9', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('0.8.0', '1.0.0'), isFalse);
    });

    test('requires semantic and Android build identities not to downgrade', () {
      expect(
        AppUpdateService.compareReleaseIdentity(
          remoteVersion: '1.4.3',
          remoteBuild: 9,
          installedVersion: '1.4.2',
          installedBuild: 8,
        ),
        greaterThan(0),
      );
      expect(
        AppUpdateService.compareReleaseIdentity(
          remoteVersion: '1.4.2',
          remoteBuild: 9,
          installedVersion: '1.4.2',
          installedBuild: 8,
        ),
        greaterThan(0),
      );
      expect(
        AppUpdateService.compareReleaseIdentity(
          remoteVersion: '1.4.3',
          remoteBuild: 9,
          installedVersion: '1.4.3',
          installedBuild: 9,
        ),
        0,
      );
      expect(
        AppUpdateService.compareReleaseIdentity(
          remoteVersion: '1.4.3',
          remoteBuild: 9,
          installedVersion: '1.4.3',
          installedBuild: 10,
        ),
        lessThan(0),
      );
      expect(
        AppUpdateService.compareReleaseIdentity(
          remoteVersion: '1.4.4',
          remoteBuild: 9,
          installedVersion: '1.4.3',
          installedBuild: 10,
        ),
        lessThan(0),
      );
    });

    test('formats release size properly', () {
      const release = AppReleaseInfo(
        version: '1.1.0',
        buildNumber: 3,
        tagName: 'v1.1.0',
        title: 'New Release',
        notes: 'Changelog',
        downloadUrl: 'https://example.com/app.apk',
        checksumUrl: 'https://example.com/app.apk.sha256',
        apkFileName: 'app-release.apk',
        apkSizeBytes: 26214400, // 25 MB
      );
      expect(release.formattedSize, '25.0 MB');
    });
  });

  group('verified update flow', () {
    const channel = MethodChannel('com.prashant.dhwani/test-installer');
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('dhwani-update-test-');
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test(
      'accepts one deterministic stable APK with checksum metadata',
      () async {
        final dio = Dio()..httpClientAdapter = _UpdateAdapter.releaseOnly();
        final service = AppUpdateService(
          dio: dio,
          identityLoader: _identity,
          installerChannel: channel,
        );

        final result = await service.checkForUpdate();

        expect(result, isA<UpdateAvailable>());
        final release = (result as UpdateAvailable).release;
        expect(release.version, '1.3.0');
        expect(release.buildNumber, 5);
        expect(release.apkFileName, 'Dhwani-v1.3.0-build5-android.apk');
      },
    );

    test(
      'accepts standard app-release.apk without external sha256 file',
      () async {
        final payload = {
          'tag_name': 'v1.4.0',
          'name': 'Dhwani v1.4.0',
          'body': 'Notes',
          'draft': false,
          'prerelease': false,
          'assets': [
            {
              'name': 'app-release.apk',
              'browser_download_url': 'https://github.com/app-release.apk',
              'size': 180000000,
              'digest':
                  'sha256:65c47074e70bd5ac3f757ed35d4b841497f32a12f80241a9364a885980ac8f4b',
            },
          ],
        };
        final service = AppUpdateService(
          dio: Dio()..httpClientAdapter = _UpdateAdapter.release(payload),
          identityLoader: _identity,
          installerChannel: channel,
        );

        final result = await service.checkForUpdate();
        expect(result, isA<UpdateAvailable>());
        final release = (result as UpdateAvailable).release;
        expect(release.version, '1.4.0');
        expect(release.apkFileName, 'app-release.apk');
        expect(
          release.expectedSha256,
          '65C47074E70BD5AC3F757ED35D4B841497F32A12F80241A9364A885980AC8F4B',
        );
      },
    );

    test('distinguishes up-to-date and same-version newer build', () async {
      final upToDate = AppUpdateService(
        dio: Dio()
          ..httpClientAdapter = _UpdateAdapter.release(
            _releasePayload(version: '1.2.0', build: 4),
          ),
        identityLoader: _identity,
        installerChannel: channel,
      );
      final newerBuild = AppUpdateService(
        dio: Dio()
          ..httpClientAdapter = _UpdateAdapter.release(
            _releasePayload(version: '1.2.0', build: 5),
          ),
        identityLoader: _identity,
        installerChannel: channel,
      );

      expect(await upToDate.checkForUpdate(), isA<UpdateUpToDate>());
      expect(await newerBuild.checkForUpdate(), isA<UpdateAvailable>());
    });

    test('stable channel ignores prereleases', () async {
      final payload = _releasePayload(version: '1.3.0', build: 5)
        ..['prerelease'] = true;
      final service = AppUpdateService(
        dio: Dio()..httpClientAdapter = _UpdateAdapter.release(payload),
        identityLoader: _identity,
        installerChannel: channel,
      );

      expect(await service.checkForUpdate(), isA<UpdateUpToDate>());
    });

    test('stable parser rejects semantic prerelease suffixes', () async {
      for (final version in ['1.4.3-beta', '1.4.3-rc1']) {
        final service = AppUpdateService(
          dio: Dio()
            ..httpClientAdapter = _UpdateAdapter.release(
              _releasePayload(version: version, build: 9),
            ),
          identityLoader: _identity,
          installerChannel: channel,
        );

        expect(await service.checkForUpdate(), isA<UpdateCheckFailed>());
      }
    });

    test('malformed version or missing apk fails explicitly', () async {
      final malformed = _releasePayload(version: 'not-semver', build: 5);
      final missing = _releasePayload(version: '1.3.0', build: 5)
        ..['assets'] = <Object?>[];

      for (final payload in [malformed, missing]) {
        final service = AppUpdateService(
          dio: Dio()..httpClientAdapter = _UpdateAdapter.release(payload),
          identityLoader: _identity,
          installerChannel: channel,
        );
        expect(await service.checkForUpdate(), isA<UpdateCheckFailed>());
      }
    });

    test('rejects an APK whose package identity is malicious', () async {
      final bytes = Uint8List.fromList(
        List.generate(4096, (index) => index % 251),
      );
      final dio = Dio()..httpClientAdapter = _UpdateAdapter.download(bytes);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {
              'archiveValid': true,
              'packageName': 'com.attacker.fake',
              'versionCode': 5,
              'signatureMatchesCurrent': true,
              'signerSha256': ['TESTCERT'],
            },
          );
      final service = AppUpdateService(
        dio: dio,
        identityLoader: _identity,
        temporaryDirectoryLoader: () async => directory,
        installerChannel: channel,
        expectedSigningCertificateSha256: 'TESTCERT',
      );

      await expectLater(
        service.downloadApk(_release(bytes.length), onProgress: (_, _, _) {}),
        throwsA(isA<UpdateVerificationException>()),
      );
      expect(directory.listSync(), isEmpty);
    });

    test('rejects an APK signed by a different certificate', () async {
      final bytes = Uint8List.fromList(List.filled(4096, 9));
      final dio = Dio()..httpClientAdapter = _UpdateAdapter.download(bytes);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {
              'archiveValid': true,
              'packageName': 'com.prashant.dhwani',
              'versionCode': 5,
              'signatureMatchesCurrent': false,
              'signerSha256': ['ATTACKERCERT'],
            },
          );
      final service = AppUpdateService(
        dio: dio,
        identityLoader: _identity,
        temporaryDirectoryLoader: () async => directory,
        installerChannel: channel,
        expectedSigningCertificateSha256: 'TESTCERT',
      );

      await expectLater(
        service.downloadApk(_release(bytes.length), onProgress: (_, _, _) {}),
        throwsA(isA<UpdateVerificationException>()),
      );
      expect(directory.listSync(), isEmpty);
    });

    test(
      'keeps only an atomically renamed APK after full verification',
      () async {
        final bytes = Uint8List.fromList(List.filled(4096, 42));
        final dio = Dio()..httpClientAdapter = _UpdateAdapter.download(bytes);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              channel,
              (_) async => {
                'archiveValid': true,
                'packageName': 'com.prashant.dhwani',
                'versionCode': 5,
                'signatureMatchesCurrent': true,
                'signerSha256': ['TESTCERT'],
              },
            );
        final service = AppUpdateService(
          dio: dio,
          identityLoader: _identity,
          temporaryDirectoryLoader: () async => directory,
          installerChannel: channel,
          expectedSigningCertificateSha256: 'TESTCERT',
        );

        final file = await service.downloadApk(
          _release(bytes.length),
          onProgress: (_, _, _) {},
        );

        expect(file.path, endsWith('.apk'));
        expect(await file.length(), bytes.length);
        expect(directory.listSync().whereType<File>(), hasLength(1));
        expect(
          directory.listSync().any((entry) => entry.path.endsWith('.part')),
          isFalse,
        );
      },
    );
  });
}

Future<AppIdentity> _identity() async => const AppIdentity(
  packageName: 'com.prashant.dhwani',
  version: '1.2.0',
  buildNumber: 4,
);

AppReleaseInfo _release(int size) => AppReleaseInfo(
  version: '1.3.0',
  buildNumber: 5,
  tagName: 'v1.3.0',
  title: 'Release',
  notes: 'Reliability',
  downloadUrl:
      'https://github.com/Mr-Dark-debug/dhwani/releases/download/v1.3.0/Dhwani-v1.3.0-build5-android.apk',
  checksumUrl:
      'https://github.com/Mr-Dark-debug/dhwani/releases/download/v1.3.0/Dhwani-v1.3.0-build5-android.apk.sha256',
  apkFileName: 'Dhwani-v1.3.0-build5-android.apk',
  apkSizeBytes: size,
);

class _UpdateAdapter implements HttpClientAdapter {
  _UpdateAdapter._({this.bytes, this.releaseResponse});

  factory _UpdateAdapter.releaseOnly() => _UpdateAdapter._(
    releaseResponse: _releasePayload(version: '1.3.0', build: 5),
  );

  factory _UpdateAdapter.release(Map<String, Object?> payload) =>
      _UpdateAdapter._(releaseResponse: payload);

  factory _UpdateAdapter.download(Uint8List bytes) =>
      _UpdateAdapter._(bytes: bytes);

  final Uint8List? bytes;
  final Map<String, Object?>? releaseResponse;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (releaseResponse != null) {
      return ResponseBody.fromString(
        jsonEncode(releaseResponse),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    final content = bytes!;
    if (options.uri.path.endsWith('.sha256')) {
      return ResponseBody.fromString(
        '${sha256.convert(content)}  app.apk\n',
        200,
      );
    }
    return ResponseBody.fromBytes(
      content,
      200,
      headers: {
        Headers.contentLengthHeader: ['${content.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _releasePayload({
  required String version,
  required int build,
}) {
  final apk = 'Dhwani-v$version-build$build-android.apk';
  return {
    'tag_name': 'v$version',
    'name': 'Dhwani $version',
    'body': 'Reliability',
    'draft': false,
    'prerelease': false,
    'published_at': '2026-08-24T12:00:00Z',
    'assets': [
      {
        'name': apk,
        'browser_download_url': 'https://github.com/$apk',
        'size': 4096,
      },
      {
        'name': '$apk.sha256',
        'browser_download_url': 'https://github.com/$apk.sha256',
        'size': 64,
      },
    ],
  };
}
