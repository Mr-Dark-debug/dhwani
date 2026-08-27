import 'dart:async';

import 'package:dhwani/core/updater/app_update_coordinator.dart';
import 'package:dhwani/core/updater/app_update_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 8, 28, 6);
  });

  AppUpdateCoordinator coordinator(_FakeUpdateService service) =>
      AppUpdateCoordinator(
        service: service,
        preferences: preferences,
        now: () => now,
      );

  test('cold-start automatic check runs and retains the release', () async {
    final service = _FakeUpdateService([UpdateAvailable(_release)]);
    final subject = coordinator(service);
    addTearDown(subject.dispose);

    final result = await subject.checkAutomatically(UpdateTrigger.coldStart);

    expect(result, isA<UpdateAvailable>());
    expect(service.calls, 1);
    expect(subject.state.available?.tagName, 'v1.4.3');
  });

  test('app-resume automatic check runs when due', () async {
    final service = _FakeUpdateService([
      const UpdateUpToDate(),
      UpdateAvailable(_release),
    ]);
    final subject = coordinator(service);
    addTearDown(subject.dispose);

    await subject.checkAutomatically(UpdateTrigger.coldStart);
    now = now.add(AppUpdateCoordinator.successfulCheckCooldown);
    final result = await subject.checkAutomatically(UpdateTrigger.resume);

    expect(result, isA<UpdateAvailable>());
    expect(service.calls, 2);
  });

  test('successful check stores only the successful timestamp', () async {
    final subject = coordinator(_FakeUpdateService([const UpdateUpToDate()]));
    addTearDown(subject.dispose);

    await subject.checkAutomatically(UpdateTrigger.coldStart);

    expect(
      preferences.getString(AppUpdateCoordinator.lastSuccessfulCheckKey),
      now.toIso8601String(),
    );
    expect(
      preferences.getString(AppUpdateCoordinator.lastFailedCheckKey),
      isNull,
    );
  });

  test('failed request never stores the successful timestamp', () async {
    final subject = coordinator(
      _FakeUpdateService([const UpdateCheckFailed('temporary')]),
    );
    addTearDown(subject.dispose);

    await subject.checkAutomatically(UpdateTrigger.coldStart);

    expect(
      preferences.getString(AppUpdateCoordinator.lastSuccessfulCheckKey),
      isNull,
    );
    expect(
      preferences.getString(AppUpdateCoordinator.lastFailedCheckKey),
      now.toIso8601String(),
    );
  });

  test('failed request retries after the short failure cooldown', () async {
    final service = _FakeUpdateService([
      const UpdateCheckFailed('temporary'),
      const UpdateUpToDate(),
    ]);
    final subject = coordinator(service);
    addTearDown(subject.dispose);

    await subject.checkAutomatically(UpdateTrigger.coldStart);
    now = now.add(const Duration(minutes: 9));
    expect(
      await subject.checkAutomatically(UpdateTrigger.resume),
      isA<UpdateCheckSkipped>(),
    );
    expect(service.calls, 1);
    now = now.add(const Duration(minutes: 1));
    expect(
      await subject.checkAutomatically(UpdateTrigger.resume),
      isA<UpdateUpToDate>(),
    );
    expect(service.calls, 2);
  });

  test('successful request obeys the one-hour cooldown', () async {
    final service = _FakeUpdateService([
      const UpdateUpToDate(),
      const UpdateUpToDate(),
    ]);
    final subject = coordinator(service);
    addTearDown(subject.dispose);

    await subject.checkAutomatically(UpdateTrigger.coldStart);
    now = now.add(const Duration(minutes: 59));
    expect(
      await subject.checkAutomatically(UpdateTrigger.resume),
      isA<UpdateCheckSkipped>(),
    );
    expect(service.calls, 1);
    now = now.add(const Duration(minutes: 1));
    expect(
      await subject.checkAutomatically(UpdateTrigger.resume),
      isA<UpdateUpToDate>(),
    );
    expect(service.calls, 2);
  });

  test('manual check always bypasses automatic cooldown', () async {
    final service = _FakeUpdateService([
      const UpdateUpToDate(),
      UpdateAvailable(_release),
    ]);
    final subject = coordinator(service);
    addTearDown(subject.dispose);

    await subject.checkAutomatically(UpdateTrigger.coldStart);
    final result = await subject.checkManually();

    expect(result, isA<UpdateAvailable>());
    expect(service.calls, 2);
  });

  test('update sheet presentation is allowed once per release/session', () {
    final subject = coordinator(_FakeUpdateService(const []));
    addTearDown(subject.dispose);

    expect(subject.takePresentation('v1.4.3'), isTrue);
    expect(subject.takePresentation('v1.4.3'), isFalse);
    expect(subject.takePresentation('v1.4.4'), isTrue);
  });

  test('simultaneous cold-start and resume checks share one lookup', () async {
    final pending = Completer<UpdateCheckResult>();
    final service = _FakeUpdateService([pending.future]);
    final subject = coordinator(service);
    addTearDown(subject.dispose);

    final coldStart = subject.checkAutomatically(UpdateTrigger.coldStart);
    final resume = subject.checkAutomatically(UpdateTrigger.resume);
    expect(service.calls, 1);
    pending.complete(const UpdateUpToDate());

    expect(await coldStart, isA<UpdateUpToDate>());
    expect(await resume, isA<UpdateUpToDate>());
    expect(service.calls, 1);
  });

  test('403, 429, and timeout never escape automatic startup checks', () async {
    final service = _FakeUpdateService([
      DioException(
        requestOptions: RequestOptions(path: '/releases/latest'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/releases/latest'),
          statusCode: 403,
        ),
      ),
      DioException(
        requestOptions: RequestOptions(path: '/releases/latest'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/releases/latest'),
          statusCode: 429,
        ),
      ),
      TimeoutException('GitHub timed out'),
    ]);
    final subject = coordinator(service);
    addTearDown(subject.dispose);

    for (var index = 0; index < 3; index++) {
      final result = await subject.checkAutomatically(
        index == 0 ? UpdateTrigger.coldStart : UpdateTrigger.resume,
      );
      expect(result, isA<UpdateCheckFailed>());
      now = now.add(AppUpdateCoordinator.failedCheckCooldown);
    }
    expect(service.calls, 3);
  });
}

const _release = AppReleaseInfo(
  version: '1.4.3',
  buildNumber: 9,
  tagName: 'v1.4.3',
  title: 'Dhwani v1.4.3',
  notes: 'Update detection',
  downloadUrl: 'https://github.com/Mr-Dark-debug/dhwani/app.apk',
  apkFileName: 'Dhwani-v1.4.3-build9-android.apk',
);

class _FakeUpdateService extends AppUpdateService {
  _FakeUpdateService(this.outcomes);

  final List<Object> outcomes;
  int calls = 0;

  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    final outcome = outcomes[calls++];
    if (outcome is Future<UpdateCheckResult>) return outcome;
    if (outcome is UpdateCheckResult) return outcome;
    throw outcome;
  }
}
