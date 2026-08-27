import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/dhwani_log.dart';

class AppIdentity {
  const AppIdentity({
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  final String packageName;
  final String version;
  final int buildNumber;
}

class AppReleaseInfo {
  const AppReleaseInfo({
    required this.version,
    required this.buildNumber,
    required this.tagName,
    required this.title,
    required this.notes,
    required this.downloadUrl,
    this.checksumUrl = '',
    this.expectedSha256,
    required this.apkFileName,
    this.apkSizeBytes = 0,
    this.publishedAt,
  });

  final String version;
  final int buildNumber;
  final String tagName;
  final String title;
  final String notes;
  final String downloadUrl;
  final String checksumUrl;
  final String? expectedSha256;
  final String apkFileName;
  final int apkSizeBytes;
  final DateTime? publishedAt;

  String get formattedSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

sealed class UpdateCheckResult {
  const UpdateCheckResult();
}

class UpdateAvailable extends UpdateCheckResult {
  const UpdateAvailable(this.release);
  final AppReleaseInfo release;
}

class UpdateUpToDate extends UpdateCheckResult {
  const UpdateUpToDate();
}

class UpdateCheckSkipped extends UpdateCheckResult {
  const UpdateCheckSkipped(this.message);
  final String message;
}

class UpdateCheckFailed extends UpdateCheckResult {
  const UpdateCheckFailed(this.message);
  final String message;
}

typedef AppIdentityLoader = Future<AppIdentity> Function();
typedef TemporaryDirectoryLoader = Future<Directory> Function();

class AppUpdateService {
  AppUpdateService({
    Dio? dio,
    AppIdentityLoader? identityLoader,
    TemporaryDirectoryLoader? temporaryDirectoryLoader,
    MethodChannel? installerChannel,
    this.expectedSigningCertificateSha256 =
        'F11E976967911C8E585DD88817D6587076A802840699EEBF7E3C8304BEDBE3B5',
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 45),
               sendTimeout: const Duration(seconds: 10),
               headers: const {
                 'Accept': 'application/vnd.github+json',
                 'X-GitHub-Api-Version': '2022-11-28',
                 'User-Agent': 'Dhwani-App-Updater',
               },
             ),
           ),
       _identityLoader = identityLoader ?? _platformIdentity,
       _temporaryDirectoryLoader =
           temporaryDirectoryLoader ?? getTemporaryDirectory,
       _installerChannel =
           installerChannel ??
           const MethodChannel('com.prashant.dhwani/installer');

  static const String githubRepo = 'Mr-Dark-debug/dhwani';
  static const String _lastAutomaticCheckKey = 'updateLastAutomaticCheck';
  static const Duration automaticCheckCooldown = Duration(hours: 12);

  final Dio _dio;
  final AppIdentityLoader _identityLoader;
  final TemporaryDirectoryLoader _temporaryDirectoryLoader;
  final MethodChannel _installerChannel;
  final String expectedSigningCertificateSha256;

  static bool isNewerVersion(String remoteTag, String localVersion) {
    final remote = _semanticParts(remoteTag);
    final local = _semanticParts(localVersion);
    for (var index = 0; index < 3; index++) {
      if (remote[index] > local[index]) return true;
      if (remote[index] < local[index]) return false;
    }
    return false;
  }

  Future<UpdateCheckResult> checkForUpdate({bool manual = true}) async {
    if (!manual) {
      final preferences = await SharedPreferences.getInstance();
      final previous = DateTime.tryParse(
        preferences.getString(_lastAutomaticCheckKey) ?? '',
      );
      if (previous != null &&
          DateTime.now().difference(previous) < automaticCheckCooldown) {
        return const UpdateCheckSkipped(
          'Automatic update check is in its cooldown period.',
        );
      }
      await preferences.setString(
        _lastAutomaticCheckKey,
        DateTime.now().toIso8601String(),
      );
    }

    try {
      final identity = await _identityLoader();
      final response = await _dio.get<Map<String, Object?>>(
        'https://api.github.com/repos/$githubRepo/releases/latest',
      );
      final data = response.data;
      if (data == null) {
        return const UpdateCheckFailed('GitHub returned an empty response.');
      }
      if (data['draft'] == true || data['prerelease'] == true) {
        return const UpdateUpToDate();
      }
      final tagName = data['tag_name']?.toString().trim() ?? '';
      final version = tagName.replaceFirst(RegExp(r'^[vV]'), '');
      if (!_isStableVersion(version)) {
        return const UpdateCheckFailed(
          'The newest release does not use a stable semantic version.',
        );
      }

      final assets = (data['assets'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map((asset) => asset.cast<String, Object?>())
          .toList();

      // Find all Android APK assets in the release
      final apkAssets = assets.where((asset) {
        final name = asset['name']?.toString().toLowerCase() ?? '';
        final contentType =
            asset['content_type']?.toString().toLowerCase() ?? '';
        return name.endsWith('.apk') ||
            contentType == 'application/vnd.android.package-archive';
      }).toList();

      if (apkAssets.isEmpty) {
        return const UpdateCheckFailed(
          'The release does not contain an Android APK file.',
        );
      }

      // Prioritize standard release names if multiple APKs are present
      final apk = apkAssets.firstWhere((asset) {
        final name = asset['name']?.toString() ?? '';
        return name.startsWith('Dhwani-v') ||
            name == 'app-release.apk' ||
            name.toLowerCase().startsWith('dhwani');
      }, orElse: () => apkAssets.first);

      final apkName = apk['name']!.toString();
      final downloadUrl = apk['browser_download_url']?.toString() ?? '';
      if (!_isGitHubAssetUrl(downloadUrl)) {
        return const UpdateCheckFailed(
          'The release asset URL is not a trusted GitHub download.',
        );
      }

      // Extract build number if present in filename or tag
      final apkBuildMatch =
          RegExp(r'(?:build|\+)(\d+)').firstMatch(apkName) ??
          RegExp(r'(?:build|\+)(\d+)').firstMatch(tagName);
      final buildNumber = apkBuildMatch != null
          ? int.tryParse(apkBuildMatch.group(1)!) ?? 0
          : 0;

      // Determine if remote version is newer than current app version
      final newer =
          isNewerVersion(version, identity.version) ||
          (version == identity.version &&
              buildNumber > 0 &&
              buildNumber > identity.buildNumber);

      if (!newer) return const UpdateUpToDate();

      // Extract checksum from GitHub asset digest (SHA-256) or explicit .sha256 file
      String? expectedSha256;
      final digest = apk['digest']?.toString();
      if (digest != null && digest.toLowerCase().startsWith('sha256:')) {
        expectedSha256 = digest.substring(7).trim().toUpperCase();
      }

      final checksumName = '$apkName.sha256';
      final checksumAsset = assets.where((asset) {
        final name = asset['name']?.toString() ?? '';
        return name == checksumName ||
            name.toLowerCase().endsWith('.sha256') ||
            name == 'checksums.txt' ||
            name == 'sha256.txt';
      }).firstOrNull;

      final checksumUrl =
          checksumAsset?['browser_download_url']?.toString() ?? '';

      return UpdateAvailable(
        AppReleaseInfo(
          version: version,
          buildNumber: buildNumber,
          tagName: tagName,
          title: data['name']?.toString() ?? tagName,
          notes: data['body']?.toString() ?? 'Bug fixes and improvements.',
          downloadUrl: downloadUrl,
          checksumUrl: checksumUrl,
          expectedSha256: expectedSha256,
          apkFileName: apkName,
          apkSizeBytes: (apk['size'] as num?)?.toInt() ?? 0,
          publishedAt: DateTime.tryParse(
            data['published_at']?.toString() ?? '',
          ),
        ),
      );
    } on DioException catch (error, stack) {
      DhwaniLog.api('Failed to check for updates', error, stack);
      final rateLimited =
          error.response?.statusCode == 403 ||
          error.response?.statusCode == 429;
      return UpdateCheckFailed(
        rateLimited
            ? 'GitHub rate-limited the update check. Try again later.'
            : 'Could not reach GitHub Releases. Check the connection and retry.',
      );
    } catch (error, stack) {
      DhwaniLog.api('Failed to check for updates', error, stack);
      return const UpdateCheckFailed(
        'The update response could not be verified.',
      );
    }
  }

  Future<File> downloadApk(
    AppReleaseInfo release, {
    required void Function(double progress, int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final identity = await _identityLoader();
    final directory = await _temporaryDirectoryLoader();
    final finalFile = File(
      '${directory.path}${Platform.pathSeparator}${release.apkFileName}',
    );
    final partialFile = File('${finalFile.path}.part');
    await _deleteIfPresent(partialFile);
    await _deleteIfPresent(finalFile);

    try {
      String? expectedHash = release.expectedSha256;
      if (expectedHash == null && release.checksumUrl.isNotEmpty) {
        try {
          final checksumResponse = await _dio.get<String>(
            release.checksumUrl,
            cancelToken: cancelToken,
            options: Options(responseType: ResponseType.plain),
          );
          expectedHash = RegExp(
            r'\b[a-fA-F0-9]{64}\b',
          ).firstMatch(checksumResponse.data ?? '')?.group(0)?.toUpperCase();
        } catch (e) {
          DhwaniLog.api('Could not download checksum file', e);
        }
      }

      await _dio.download(
        release.downloadUrl,
        partialFile.path,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          onProgress(
            total > 0 ? (received / total).clamp(0.0, 1.0) : 0,
            received,
            total,
          );
        },
      );

      final length = await partialFile.length();
      if (length <= 0 ||
          (release.apkSizeBytes > 0 && length != release.apkSizeBytes)) {
        throw const UpdateVerificationException(
          'The downloaded APK size does not match the release metadata.',
        );
      }

      if (expectedHash != null && expectedHash.isNotEmpty) {
        final actualHash = (await sha256.bind(partialFile.openRead()).first)
            .toString()
            .toUpperCase();
        if (actualHash != expectedHash) {
          throw const UpdateVerificationException(
            'The downloaded APK checksum does not match.',
          );
        }
      }

      final inspection = await _installerChannel
          .invokeMapMethod<String, Object?>('inspectApk', {
            'path': partialFile.path,
          });

      if (inspection != null) {
        if (inspection['archiveValid'] != true) {
          throw const UpdateVerificationException(
            'Android could not verify the downloaded APK archive.',
          );
        }

        final packageName = inspection['packageName']?.toString();
        final versionCode = (inspection['versionCode'] as num?)?.toInt() ?? -1;
        final signatureMatches = inspection['signatureMatchesCurrent'] == true;
        final signerHashes =
            (inspection['signerSha256'] as List<Object?>? ?? const [])
                .map((value) => value.toString().toUpperCase())
                .toSet();

        if (packageName != null &&
            packageName != identity.packageName &&
            packageName != 'com.prashant.dhwani') {
          throw const UpdateVerificationException(
            'The downloaded APK belongs to a different application.',
          );
        }

        if (versionCode > 0 &&
            versionCode < identity.buildNumber &&
            !isNewerVersion(release.version, identity.version)) {
          throw const UpdateVerificationException(
            'The downloaded APK build identity is not a newer build.',
          );
        }

        if (!signatureMatches &&
            !signerHashes.contains(expectedSigningCertificateSha256)) {
          throw const UpdateVerificationException(
            'The downloaded APK signing certificate does not match Dhwani.',
          );
        }
      }

      return partialFile.rename(finalFile.path);
    } catch (_) {
      await _deleteIfPresent(partialFile);
      rethrow;
    }
  }

  Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _installerChannel.invokeMethod<bool>(
            'canRequestPackageInstalls',
          ) ??
          false;
    } catch (error, stack) {
      DhwaniLog.player('Could not inspect install permission', error, stack);
      return false;
    }
  }

  Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _installerChannel.invokeMethod<bool>(
            'openInstallPermissionSettings',
          ) ??
          false;
    } catch (error, stack) {
      DhwaniLog.player(
        'Could not open install permission settings',
        error,
        stack,
      );
      return false;
    }
  }

  /// Returns true only when Android accepted the installer intent.
  /// Installation success is confirmed by Android after this app is replaced.
  Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _installerChannel.invokeMethod<bool>('installApk', {
            'path': filePath,
          }) ??
          false;
    } catch (error, stack) {
      DhwaniLog.player('Failed to launch APK installer', error, stack);
      return false;
    }
  }

  static Future<AppIdentity> _platformIdentity() async {
    final info = await PackageInfo.fromPlatform();
    return AppIdentity(
      packageName: info.packageName,
      version: info.version,
      buildNumber: int.tryParse(info.buildNumber) ?? 0,
    );
  }

  static List<int> _semanticParts(String value) {
    final clean = value.replaceFirst(RegExp(r'^[vV]'), '').trim();
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(clean);
    if (match == null) return const [0, 0, 0];
    return [
      for (var index = 1; index <= 3; index++) int.parse(match.group(index)!),
    ];
  }

  static bool _isStableVersion(String value) =>
      RegExp(r'^\d+\.\d+\.\d+').hasMatch(value);

  static bool _isGitHubAssetUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        (uri.host == 'github.com' ||
            uri.host == 'objects.githubusercontent.com' ||
            uri.host == 'api.github.com' ||
            uri.host.endsWith('.githubusercontent.com'));
  }

  static Future<void> _deleteIfPresent(File file) async {
    if (await file.exists()) await file.delete();
  }
}

class UpdateVerificationException implements Exception {
  const UpdateVerificationException(this.message);
  final String message;

  @override
  String toString() => message;
}
