import 'dart:async';
import 'dart:io';

import 'package:dhwani/core/persistence/app_database.dart';
import 'package:dhwani/core/recording/recording_backend.dart';
import 'package:dhwani/core/recording/recording_service.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late AppDatabase database;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'dhwani-recorder-test-',
    );
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('REC starts only after output bytes are observed', () async {
    final backend = FakeRecordingBackend(
      writeDelay: const Duration(milliseconds: 15),
    );
    final service = _service(database, temporaryDirectory, backend);

    final start = service.start(station, station.streams.single);
    expect(service.state.value.status, RecordingStatus.starting);
    await start;

    expect(service.state.value.status, RecordingStatus.recording);
    expect(await File(service.state.value.path!).length(), greaterThan(2048));
    final entry = await service.stop();
    expect(entry.duration, const Duration(seconds: 1));
    expect(service.state.value.status, RecordingStatus.saved);
    expect(await database.allRecordings(), hasLength(1));
  });

  test('early process exit terminates as failed with no orphan row', () async {
    final backend = FakeRecordingBackend(
      exitDelay: const Duration(milliseconds: 10),
      writeBytes: false,
    );
    final service = _service(database, temporaryDirectory, backend);

    await expectLater(
      service.start(station, station.streams.single),
      throwsStateError,
    );

    expect(service.state.value.status, RecordingStatus.failed);
    expect(service.isBusy, isFalse);
    expect(await database.allRecordings(), isEmpty);
    expect(temporaryDirectory.listSync().whereType<File>(), isEmpty);
  });

  test('unexpected station exit saves a valid partial recording', () async {
    final backend = FakeRecordingBackend(
      writeDelay: const Duration(milliseconds: 10),
      exitDelay: const Duration(milliseconds: 150),
    );
    final service = _service(
      database,
      temporaryDirectory,
      backend,
      probeDuration: const Duration(seconds: 3),
    );

    await service.start(station, station.streams.single);
    await service.state.firstWhere(
      (snapshot) => snapshot.status == RecordingStatus.saved,
    );

    final entries = await database.allRecordings();
    expect(entries, hasLength(1));
    expect(entries.single.duration, const Duration(seconds: 3));
    expect(service.state.value.message, contains('partial'));
  });

  test(
    'start timeout cancels the process and returns a terminal state',
    () async {
      final backend = FakeRecordingBackend(writeBytes: false);
      final service = _service(
        database,
        temporaryDirectory,
        backend,
        startTimeout: const Duration(milliseconds: 120),
      );

      await expectLater(
        service.start(station, station.streams.single),
        throwsStateError,
      );

      expect(backend.lastProcess?.cancelled, isTrue);
      expect(service.state.value.status, RecordingStatus.failed);
      expect(service.isBusy, isFalse);
    },
  );

  for (final seconds in [1, 3, 10, 30]) {
    test(
      '$seconds-second validated duration is stored from the media probe',
      () async {
        final backend = FakeRecordingBackend(
          writeDelay: const Duration(milliseconds: 5),
        );
        final service = _service(
          database,
          temporaryDirectory,
          backend,
          probeDuration: Duration(seconds: seconds),
        );

        await service.start(station, station.streams.single);
        final entry = await service.stop();

        expect(entry.duration, Duration(seconds: seconds));
        expect(entry.sizeBytes, greaterThan(1024));
      },
    );
  }
}

RecordingService _service(
  AppDatabase database,
  Directory directory,
  FakeRecordingBackend backend, {
  Duration probeDuration = const Duration(seconds: 1),
  Duration startTimeout = const Duration(seconds: 1),
}) => RecordingService(
  database: database,
  backend: backend,
  directoryProvider: () async => directory,
  probe: (_) async => probeDuration,
  startTimeout: startTimeout,
  minimumStartBytes: 2048,
);

const station = RadioStation(
  id: 'record-test',
  name: 'Test Radio',
  country: 'Testland',
  countryCode: 'TT',
  band: RadioBand.net,
  streams: [StationStream(url: 'https://radio.test/live.mp3', codec: 'MP3')],
  directory: RadioDirectory.custom,
);

class FakeRecordingBackend implements RecordingBackend {
  FakeRecordingBackend({
    this.writeDelay,
    this.exitDelay,
    this.writeBytes = true,
  });

  final Duration? writeDelay;
  final Duration? exitDelay;
  final bool writeBytes;
  FakeRecordingProcess? lastProcess;

  @override
  Future<RecordingProcess> start(String command) async {
    final path = RegExp(r'"([^"]+)"\s*$').firstMatch(command)?.group(1);
    if (path == null) throw StateError('Output path missing from command');
    final process = FakeRecordingProcess();
    lastProcess = process;
    if (writeBytes) {
      unawaited(
        Future<void>.delayed(
          writeDelay ?? Duration.zero,
          () => File(path).writeAsBytes(List.filled(4096, 7), flush: true),
        ),
      );
    }
    if (exitDelay != null) {
      unawaited(
        Future<void>.delayed(
          exitDelay!,
          () => process.complete(exitCode: 1, output: 'upstream ended'),
        ),
      );
    }
    return process;
  }
}

class FakeRecordingProcess implements RecordingProcess {
  final _completion = Completer<RecordingProcessResult>();
  bool cancelled = false;

  @override
  Future<RecordingProcessResult> get completed => _completion.future;

  void complete({required int exitCode, required String output}) {
    if (!_completion.isCompleted) {
      _completion.complete(
        RecordingProcessResult(
          exitCode: exitCode,
          cancelled: false,
          output: output,
        ),
      );
    }
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
    if (!_completion.isCompleted) {
      _completion.complete(
        const RecordingProcessResult(
          exitCode: 255,
          cancelled: true,
          output: 'cancelled',
        ),
      );
    }
  }
}
