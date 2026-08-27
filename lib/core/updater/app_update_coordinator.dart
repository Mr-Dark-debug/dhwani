import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/dhwani_log.dart';
import 'app_update_service.dart';

enum UpdateTrigger { coldStart, resume, manual }

class AppUpdateState {
  const AppUpdateState({
    this.checking = false,
    this.available,
    this.lastResult,
  });

  final bool checking;
  final AppReleaseInfo? available;
  final UpdateCheckResult? lastResult;

  AppUpdateState copyWith({
    bool? checking,
    AppReleaseInfo? available,
    bool clearAvailable = false,
    UpdateCheckResult? lastResult,
  }) => AppUpdateState(
    checking: checking ?? this.checking,
    available: clearAvailable ? null : available ?? this.available,
    lastResult: lastResult ?? this.lastResult,
  );
}

class AppUpdateCoordinator extends ChangeNotifier {
  AppUpdateCoordinator({
    required AppUpdateService service,
    required SharedPreferences preferences,
    DateTime Function()? now,
  }) : _service = service,
       _preferences = preferences,
       _now = now ?? DateTime.now;

  static const lastSuccessfulCheckKey = 'lastSuccessfulUpdateCheck';
  static const lastFailedCheckKey = 'lastFailedUpdateCheck';
  static const successfulCheckCooldown = Duration(hours: 1);
  static const failedCheckCooldown = Duration(minutes: 10);

  Future<UpdateCheckResult>? _inFlight;
  final Set<String> _presentedTags = <String>{};
  final AppUpdateService _service;
  final SharedPreferences _preferences;
  final DateTime Function() _now;
  AppUpdateState _state = const AppUpdateState();

  AppUpdateState get state => _state;

  Future<UpdateCheckResult> checkAutomatically(UpdateTrigger trigger) async {
    assert(trigger != UpdateTrigger.manual);
    final active = _inFlight;
    if (active != null) return active;
    final now = _now();
    final successful = _readTimestamp(_preferences, lastSuccessfulCheckKey);
    if (successful != null &&
        now.difference(successful) < successfulCheckCooldown) {
      DhwaniLog.api('Automatic update check skipped: success cooldown');
      return const UpdateCheckSkipped(
        'Automatic update check is in its successful-check cooldown.',
      );
    }
    final failed = _readTimestamp(_preferences, lastFailedCheckKey);
    if (failed != null && now.difference(failed) < failedCheckCooldown) {
      DhwaniLog.api('Automatic update check skipped: failure retry cooldown');
      return const UpdateCheckSkipped(
        'Automatic update check is waiting for its short failure retry.',
      );
    }
    return _start(trigger);
  }

  Future<UpdateCheckResult> checkManually() {
    final active = _inFlight;
    if (active != null) return active;
    return _start(UpdateTrigger.manual);
  }

  bool takePresentation(String tagName) => _presentedTags.add(tagName);

  Future<UpdateCheckResult> _start(UpdateTrigger trigger) {
    final completer = Completer<UpdateCheckResult>();
    _inFlight = completer.future;
    unawaited(_perform(trigger, completer));
    return completer.future;
  }

  Future<void> _perform(
    UpdateTrigger trigger,
    Completer<UpdateCheckResult> completer,
  ) async {
    _setState(state.copyWith(checking: true));
    DhwaniLog.api('Update check started: ${trigger.name}');
    UpdateCheckResult result;
    try {
      result = await _service.checkForUpdate();
    } catch (error, stack) {
      DhwaniLog.api('Update check failed safely', error, stack);
      result = const UpdateCheckFailed(
        'Could not reach GitHub Releases. Check the connection and retry.',
      );
    }

    final now = _now();
    try {
      if (result is UpdateAvailable || result is UpdateUpToDate) {
        await _preferences.setString(
          lastSuccessfulCheckKey,
          now.toIso8601String(),
        );
      } else if (result is UpdateCheckFailed) {
        await _preferences.setString(lastFailedCheckKey, now.toIso8601String());
      }
    } catch (error, stack) {
      DhwaniLog.database(
        'Could not persist update-check cooldown timestamp',
        error,
        stack,
      );
    }

    _setState(switch (result) {
      UpdateAvailable(:final release) => state.copyWith(
        checking: false,
        available: release,
        lastResult: result,
      ),
      UpdateUpToDate() => state.copyWith(
        checking: false,
        clearAvailable: true,
        lastResult: result,
      ),
      _ => state.copyWith(checking: false, lastResult: result),
    });
    _inFlight = null;
    if (!completer.isCompleted) completer.complete(result);
  }

  static DateTime? _readTimestamp(SharedPreferences preferences, String key) =>
      DateTime.tryParse(preferences.getString(key) ?? '');

  void _setState(AppUpdateState next) {
    _state = next;
    notifyListeners();
  }
}
