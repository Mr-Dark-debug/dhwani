import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/dhwani_log.dart';

class AppReleaseInfo {
  const AppReleaseInfo({
    required this.version,
    required this.tagName,
    required this.title,
    required this.notes,
    required this.downloadUrl,
    required this.apkFileName,
    this.apkSizeBytes = 0,
    this.publishedAt,
  });

  final String version;
  final String tagName;
  final String title;
  final String notes;
  final String downloadUrl;
  final String apkFileName;
  final int apkSizeBytes;
  final DateTime? publishedAt;

  String get formattedSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class AppUpdateService {
  AppUpdateService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'Dhwani-App-Updater',
                },
              ),
            );

  static const String currentAppVersion = '1.1.0';
  static const int currentBuildNumber = 3;
  static const String githubRepo = 'Mr-Dark-debug/dhwani';
  static const MethodChannel _installerChannel =
      MethodChannel('com.prashant.dhwani/installer');

  final Dio _dio;

  static bool isNewerVersion(String remoteTag, String localVersion) {
    final cleanRemote = remoteTag.replaceAll(RegExp(r'^[vV]'), '').trim();
    final cleanLocal = localVersion.replaceAll(RegExp(r'^[vV]'), '').trim();

    final remoteParts = cleanRemote
        .split(RegExp(r'[.+–-]'))
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final localParts = cleanLocal
        .split(RegExp(r'[.+–-]'))
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    final maxLength = remoteParts.length > localParts.length
        ? remoteParts.length
        : localParts.length;

    for (var i = 0; i < maxLength; i++) {
      final remoteVal = i < remoteParts.length ? remoteParts[i] : 0;
      final localVal = i < localParts.length ? localParts[i] : 0;
      if (remoteVal > localVal) return true;
      if (remoteVal < localVal) return false;
    }
    return false;
  }

  Future<AppReleaseInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$githubRepo/releases/latest',
      );
      final data = response.data;
      if (data == null) return null;

      final tagName = data['tag_name'] as String? ?? '';
      final title = data['name'] as String? ?? tagName;
      final notes = data['body'] as String? ?? 'Bug fixes and improvements.';
      final publishedStr = data['published_at'] as String?;
      final publishedAt =
          publishedStr != null ? DateTime.tryParse(publishedStr) : null;

      final assets = (data['assets'] as List<dynamic>?) ?? [];
      String? downloadUrl;
      String apkName = 'dhwani-update.apk';
      int apkSize = 0;

      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String?;
            apkName = name;
            apkSize = (asset['size'] as num?)?.toInt() ?? 0;
            break;
          }
        }
      }

      if (downloadUrl == null) return null;

      if (isNewerVersion(tagName, currentAppVersion)) {
        return AppReleaseInfo(
          version: tagName.replaceAll(RegExp(r'^[vV]'), ''),
          tagName: tagName,
          title: title,
          notes: notes,
          downloadUrl: downloadUrl,
          apkFileName: apkName,
          apkSizeBytes: apkSize,
          publishedAt: publishedAt,
        );
      }
    } catch (e, stack) {
      DhwaniLog.api('Failed to check for updates', e, stack);
    }
    return null;
  }

  Future<File> downloadApk(
    AppReleaseInfo release, {
    required void Function(double progress, int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/${release.apkFileName}';
    final targetFile = File(savePath);

    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await _dio.download(
      release.downloadUrl,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = (received / total).clamp(0.0, 1.0);
          onProgress(progress, received, total);
        } else {
          onProgress(0.5, received, total);
        }
      },
    );

    return targetFile;
  }

  Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return false;
    try {
      final allowed = await _installerChannel
          .invokeMethod<bool>('canRequestPackageInstalls');
      return allowed ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _installerChannel.invokeMethod('openInstallPermissionSettings');
    } catch (e, stack) {
      DhwaniLog.player('Could not open install permission settings', e, stack);
    }
  }

  Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) return false;
    try {
      final success = await _installerChannel.invokeMethod<bool>(
        'installApk',
        {'path': filePath},
      );
      return success ?? true;
    } catch (e, stack) {
      DhwaniLog.player('Failed to launch APK installer', e, stack);
      return false;
    }
  }
}
