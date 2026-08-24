import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/radio_station.dart';
import '../../data/models/recording_entry.dart';
import '../logging/dhwani_log.dart';
import '../persistence/app_database.dart';
import 'recording_backend.dart';

enum RecordingStatus {
  idle,
  starting,
  recording,
  stopping,
  finalizing,
  saved,
  failed,
}

class RecordingSnapshot {
  const RecordingSnapshot({
    required this.status,
    this.station,
    this.elapsed = Duration.zero,
    this.path,
    this.message,
  });

  final RecordingStatus status;
  final RadioStation? station;
  final Duration elapsed;
  final String? path;
  final String? message;

  bool get busy =>
      status == RecordingStatus.starting ||
      status == RecordingStatus.recording ||
      status == RecordingStatus.stopping ||
      status == RecordingStatus.finalizing;
}

typedef RecordingDirectoryProvider = Future<Directory> Function();
typedef RecordingProbe = Future<Duration?> Function(String path);

class RecordingService {
  RecordingService({
    required this.database,
    RecordingBackend? backend,
    RecordingDirectoryProvider? directoryProvider,
    RecordingProbe? probe,
    this.startTimeout = const Duration(seconds: 25),
    this.minimumStartBytes = 2048,
  }) : _backend = backend ?? const FfmpegRecordingBackend(),
       _directoryProvider = directoryProvider ?? _defaultDirectory,
       _probe = probe ?? _defaultProbe;

  final AppDatabase database;
  final RecordingBackend _backend;
  final RecordingDirectoryProvider _directoryProvider;
  final RecordingProbe _probe;
  final Duration startTimeout;
  final int minimumStartBytes;

  final BehaviorSubject<RecordingSnapshot> state = BehaviorSubject.seeded(
    const RecordingSnapshot(status: RecordingStatus.idle),
  );

  RecordingProcess? _process;
  Future<RecordingProcess>? _processReady;
  Timer? _timer;
  DateTime? _startedAt;
  String? _path;
  RadioStation? _station;
  String _preferredFormat = 'auto';
  int _operationId = 0;
  String? lastDiagnostic;

  void configure({required String preferredFormat}) {
    _preferredFormat = {'auto', 'mp3', 'm4a'}.contains(preferredFormat)
        ? preferredFormat
        : 'auto';
  }

  bool get isRecording => state.value.status == RecordingStatus.recording;
  bool get isBusy => state.value.busy;

  static String fileName(
    RadioStation station,
    DateTime time,
    String extension,
  ) {
    final safe = station.name
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'Dhwani_${safe}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(time)}.$extension';
  }

  Future<void> start(RadioStation station, StationStream stream) async {
    if (isBusy || _process != null || _processReady != null) {
      throw StateError('A recording is already active');
    }
    final operation = ++_operationId;
    final now = DateTime.now();
    state.add(
      RecordingSnapshot(status: RecordingStatus.starting, station: station),
    );
    final sourceExtension = _extension(stream);
    final extension = _preferredFormat == 'auto'
        ? sourceExtension
        : _preferredFormat;
    late final Directory directory;
    try {
      directory = await _directoryProvider();
      await directory.create(recursive: true);
    } catch (error, stack) {
      _reset();
      DhwaniLog.recorder('Recording directory is unavailable', error, stack);
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.failed,
          station: station,
          message: 'Recording storage is unavailable.',
        ),
      );
      throw StateError('Recording storage is unavailable');
    }
    if (operation != _operationId) return;
    final path =
        '${directory.path}${Platform.pathSeparator}${fileName(station, now, extension)}';
    _path = path;
    _station = station;
    _startedAt = now;
    final codecArguments = extension == sourceExtension
        ? '-c:a copy'
        : extension == 'mp3'
        ? '-c:a libmp3lame -b:a 128k'
        : '-c:a aac -b:a 128k';
    final command =
        '-hide_banner -loglevel warning -y -user_agent ${_quote('Dhwani/1 (com.prashant.dhwani)')} '
        '-rw_timeout 8000000 -reconnect 1 -reconnect_streamed 1 '
        '-reconnect_delay_max 2 -i ${_quote(stream.url)} -map 0:a:0 '
        '-vn -sn -dn -fflags +flush_packets -flush_packets 1 '
        '$codecArguments ${_quote(path)}';

    try {
      lastDiagnostic = null;
      _processReady = _backend.start(command);
      final process = await _processReady!;
      _processReady = null;
      if (operation != _operationId) {
        await process.cancel();
        return;
      }
      _process = process;
      final handshake = await _waitForStart(File(path), process);
      if (operation != _operationId) return;
      if (handshake is RecordingProcessResult) {
        lastDiagnostic = _sanitizeDiagnostic(handshake.output);
        throw StateError(
          'Recorder exited before receiving audio (code ${handshake.exitCode ?? 'unknown'}).',
        );
      }
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.recording,
          station: station,
          path: path,
        ),
      );
      _startTimer(operation, station, path, now);
      unawaited(_watchUnexpectedExit(operation, process, station, path, now));
    } catch (error, stack) {
      if (operation != _operationId) return;
      final process = _process;
      if (process != null) {
        await process.cancel().catchError((_) {});
        try {
          final result = await process.completed.timeout(
            const Duration(seconds: 3),
          );
          lastDiagnostic = _sanitizeDiagnostic(result.output);
        } catch (_) {
          // The user-facing failure remains bounded even if native teardown is.
        }
      }
      await _deleteIfPresent(path);
      _reset();
      DhwaniLog.recorder(
        'Unable to start recording${lastDiagnostic?.isNotEmpty == true ? ': $lastDiagnostic' : ''}',
        error,
        stack,
      );
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.failed,
          station: station,
          message:
              'Recording could not start because no audio bytes were received.',
        ),
      );
      throw StateError('Recording start handshake failed');
    }
  }

  Future<RecordingEntry> stop() async {
    final station = _station ?? state.value.station;
    final path = _path;
    final startedAt = _startedAt;
    if (station == null || path == null || startedAt == null) {
      throw StateError('No recording is active');
    }
    final operation = ++_operationId;
    state.add(
      RecordingSnapshot(
        status: RecordingStatus.stopping,
        station: station,
        path: path,
        elapsed: DateTime.now().difference(startedAt),
      ),
    );
    _timer?.cancel();
    final process =
        _process ?? await _processReady?.timeout(const Duration(seconds: 5));
    if (process != null) {
      await process.cancel();
      final result = await process.completed.timeout(
        const Duration(seconds: 8),
        onTimeout: () => const RecordingProcessResult(
          exitCode: null,
          cancelled: true,
          output: 'Recorder cancellation acknowledgement timed out.',
        ),
      );
      lastDiagnostic = _sanitizeDiagnostic(result.output);
    }
    if (operation != _operationId) {
      throw StateError('Recording finalization was superseded');
    }
    return _finalize(
      operation,
      station,
      path,
      startedAt,
      message: 'Recording saved',
    );
  }

  Future<void> _watchUnexpectedExit(
    int operation,
    RecordingProcess process,
    RadioStation station,
    String path,
    DateTime startedAt,
  ) async {
    final result = await process.completed;
    if (operation != _operationId ||
        state.value.status != RecordingStatus.recording) {
      return;
    }
    lastDiagnostic = _sanitizeDiagnostic(result.output);
    _timer?.cancel();
    try {
      await _finalize(
        operation,
        station,
        path,
        startedAt,
        message: 'Broadcast ended; partial recording saved.',
      );
    } catch (error, stack) {
      DhwaniLog.recorder(
        'Unexpected recorder exit was not recoverable',
        error,
        stack,
      );
    }
  }

  Future<RecordingEntry> _finalize(
    int operation,
    RadioStation station,
    String path,
    DateTime startedAt, {
    required String message,
  }) async {
    state.add(
      RecordingSnapshot(
        status: RecordingStatus.finalizing,
        station: station,
        path: path,
        elapsed: DateTime.now().difference(startedAt),
      ),
    );
    final file = File(path);
    final length = await file.exists() ? await file.length() : 0;
    final duration = length > 1024 ? await _probe(path) : null;
    if (operation != _operationId) {
      throw StateError('Recording validation was superseded');
    }
    if (length <= 1024 || duration == null || duration <= Duration.zero) {
      await _deleteIfPresent(path);
      _reset();
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.failed,
          station: station,
          message: 'Recording could not be saved as a valid audio file.',
        ),
      );
      throw StateError('Recording output failed validation');
    }
    final entry = RecordingEntry(
      id: const Uuid().v4(),
      station: station,
      path: path,
      name: path.split(Platform.pathSeparator).last,
      createdAt: startedAt,
      duration: duration,
      sizeBytes: length,
      format: path.split('.').last.toLowerCase(),
    );
    await database.addRecording(entry);
    if (operation != _operationId) {
      throw StateError('Recording database write was superseded');
    }
    _reset();
    state.add(
      RecordingSnapshot(
        status: RecordingStatus.saved,
        station: station,
        path: path,
        elapsed: duration,
        message: message,
      ),
    );
    return entry;
  }

  Future<void> cancel() async {
    ++_operationId;
    var process = _process;
    final processReady = _processReady;
    if (process == null && processReady != null) {
      try {
        process = await processReady;
      } catch (_) {
        // A failed launch has no native process left to cancel.
      }
    }
    if (process != null) await process.cancel().catchError((_) {});
    final path = _path;
    if (path != null) await _deleteIfPresent(path);
    _reset();
    state.add(const RecordingSnapshot(status: RecordingStatus.idle));
  }

  Future<int> clearTemporaryFiles() async {
    final directory = await _directoryProvider();
    if (!await directory.exists()) return 0;
    final indexed = (await database.allRecordings())
        .map((entry) => entry.path)
        .toSet();
    var removed = 0;
    await for (final entity in directory.list()) {
      if (entity is File && !indexed.contains(entity.path)) {
        await entity.delete();
        removed++;
      }
    }
    return removed;
  }

  Future<void> deleteAllRecordings() async {
    for (final entry in await database.allRecordings()) {
      await _deleteIfPresent(entry.path);
    }
    await database.clearRecordings();
  }

  Future<Object> _waitForStart(File file, RecordingProcess process) async {
    final deadline = DateTime.now().add(startTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await file.exists() && await file.length() >= minimumStartBytes) {
        return true;
      }
      final outcome = await Future.any<Object?>([
        Future<void>.delayed(const Duration(milliseconds: 100)),
        process.completed,
      ]);
      if (outcome is RecordingProcessResult) {
        if (await file.exists() && await file.length() >= minimumStartBytes) {
          return true;
        }
        return outcome;
      }
    }
    throw TimeoutException('No recording bytes arrived before the deadline.');
  }

  void _startTimer(
    int operation,
    RadioStation station,
    String path,
    DateTime startedAt,
  ) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (operation != _operationId ||
          state.value.status != RecordingStatus.recording) {
        return;
      }
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.recording,
          station: station,
          path: path,
          elapsed: DateTime.now().difference(startedAt),
        ),
      );
    });
  }

  static Future<Directory> _defaultDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return Directory('${root.path}${Platform.pathSeparator}recordings');
  }

  static Future<Duration?> _defaultProbe(String path) async {
    final session = await FFprobeKit.getMediaInformation(path);
    final durationSeconds = double.tryParse(
      session.getMediaInformation()?.getDuration() ?? '',
    );
    if (durationSeconds == null || durationSeconds <= 0) return null;
    return Duration(milliseconds: (durationSeconds * 1000).round());
  }

  static String _extension(StationStream stream) {
    final codec = stream.codec?.toLowerCase() ?? '';
    if (codec.contains('mp3') || stream.url.toLowerCase().contains('.mp3')) {
      return 'mp3';
    }
    if (codec.contains('opus') || codec.contains('vorbis')) return 'ogg';
    if (stream.hls || codec.contains('aac')) return 'm4a';
    return 'mka';
  }

  static String _quote(String value) => '"${value.replaceAll('"', r'\"')}"';

  static String _sanitizeDiagnostic(String value) => value
      .replaceAllMapped(
        RegExp(r'https?://[^\s]+', caseSensitive: false),
        (match) => Uri.tryParse(match.group(0)!)?.host ?? '<stream-host>',
      )
      .replaceAll(RegExp(r'[\r\n]+'), ' ')
      .trim();

  static Future<void> _deleteIfPresent(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    _process = null;
    _processReady = null;
    _path = null;
    _station = null;
    _startedAt = null;
  }
}
