import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/dhwani_theme.dart';
import 'app_update_service.dart';

enum _UpdateStep { idle, downloading, downloaded, permissionRequired, error }

class AppUpdateSheet extends StatefulWidget {
  const AppUpdateSheet({
    super.key,
    required this.release,
    required this.updateService,
  });

  final AppReleaseInfo release;
  final AppUpdateService updateService;

  static Future<void> show(
    BuildContext context, {
    required AppReleaseInfo release,
    required AppUpdateService updateService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppUpdateSheet(
        release: release,
        updateService: updateService,
      ),
    );
  }

  @override
  State<AppUpdateSheet> createState() => _AppUpdateSheetState();
}

class _AppUpdateSheetState extends State<AppUpdateSheet>
    with WidgetsBindingObserver {
  _UpdateStep _step = _UpdateStep.idle;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  String? _downloadedPath;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _step == _UpdateStep.permissionRequired &&
        _downloadedPath != null) {
      _checkPermissionAndInstall();
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _step = _UpdateStep.downloading;
      _progress = 0.0;
      _errorMessage = null;
    });

    _cancelToken = CancelToken();

    try {
      final file = await widget.updateService.downloadApk(
        widget.release,
        cancelToken: _cancelToken,
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _receivedBytes = received;
              _totalBytes = total;
            });
          }
        },
      );

      if (!mounted) return;

      _downloadedPath = file.path;
      await _checkPermissionAndInstall();
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _UpdateStep.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _checkPermissionAndInstall() async {
    final hasPermission =
        await widget.updateService.canRequestPackageInstalls();

    if (!mounted) return;

    if (!hasPermission) {
      setState(() {
        _step = _UpdateStep.permissionRequired;
      });
      return;
    }

    setState(() {
      _step = _UpdateStep.downloaded;
    });

    if (_downloadedPath != null) {
      await widget.updateService.installApk(_downloadedPath!);
    }
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? DhwaniColors.darkSurface : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: .25),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Version Badge Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: DhwaniColors.signal.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: DhwaniColors.signal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Update Available',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DhwaniColors.signal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.release.tagName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (widget.release.formattedSize.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                widget.release.formattedSize,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: .6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Release Notes / Changelog
              Text(
                'What’s New',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: .7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: .2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      widget.release.notes.trim().isNotEmpty
                          ? widget.release.notes
                          : widget.release.title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: .9),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Progress or Status Section
              if (_step == _UpdateStep.downloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Downloading update…',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: DhwaniColors.signal,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: .08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          DhwaniColors.signal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_totalBytes > 0)
                      Text(
                        '${_formatBytes(_receivedBytes)} of ${_formatBytes(_totalBytes)}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: .55),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (_step == _UpdateStep.permissionRequired) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: .3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Please allow "Install unknown apps" for Dhwani in Android Settings to complete the update.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_step == _UpdateStep.error) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DhwaniColors.signal.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DhwaniColors.signal.withValues(alpha: .3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: DhwaniColors.signal,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage ?? 'Failed to download update.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              if (_step == _UpdateStep.idle || _step == _UpdateStep.error) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Later'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: DhwaniColors.signal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text(
                          'Download & Install',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          _startDownload();
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (_step == _UpdateStep.permissionRequired) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: DhwaniColors.signal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.settings_rounded, size: 20),
                    label: const Text(
                      'Open Settings & Allow',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () async {
                      await widget.updateService
                          .openInstallPermissionSettings();
                    },
                  ),
                ),
              ] else if (_step == _UpdateStep.downloaded) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: DhwaniColors.signal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.install_mobile_rounded, size: 20),
                    label: const Text(
                      'Install Update',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () {
                      if (_downloadedPath != null) {
                        widget.updateService.installApk(_downloadedPath!);
                      }
                    },
                  ),
                ),
              ] else if (_step == _UpdateStep.downloading) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      _cancelToken?.cancel('User cancelled download');
                      setState(() {
                        _step = _UpdateStep.idle;
                      });
                    },
                    child: const Text('Cancel Download'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
