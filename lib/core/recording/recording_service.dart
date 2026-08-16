import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/radio_station.dart';
import '../../data/models/recording_entry.dart';
import '../logging/dhwani_log.dart';
import '../persistence/app_database.dart';

enum RecordingStatus { idle, starting, recording, stopping, saved, error }

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
}

class RecordingService {
  RecordingService({required this.database});

  final AppDatabase database;
  final BehaviorSubject<RecordingSnapshot> state = BehaviorSubject.seeded(
    const RecordingSnapshot(status: RecordingStatus.idle),
  );
  FFmpegSession? _session;
  Timer? _timer;
  DateTime? _startedAt;
  Completer<void>? _finished;
  String? _path;
  RadioStation? _station;

  bool get isRecording => state.value.status == RecordingStatus.recording;

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
    if (isRecording || _session != null) {
      throw StateError('A recording is already active');
    }
    state.add(
      RecordingSnapshot(status: RecordingStatus.starting, station: station),
    );
    final extension = _extension(stream);
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}recordings',
    );
    await directory.create(recursive: true);
    final now = DateTime.now();
    final path =
        '${directory.path}${Platform.pathSeparator}${fileName(station, now, extension)}';
    _path = path;
    _station = station;
    _startedAt = now;
    _finished = Completer<void>();
    final command =
        '-hide_banner -loglevel warning -y -i ${_quote(stream.url)} -map 0:a:0 -c:a copy ${_quote(path)}';
    try {
      _session = await FFmpegKit.executeAsync(command, (session) async {
        final output = await session.getOutput();
        if (!(_finished?.isCompleted ?? true)) _finished!.complete();
        DhwaniLog.recorder('FFmpeg recording session ended: $output');
      });
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.recording,
          station: station,
          path: path,
        ),
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        state.add(
          RecordingSnapshot(
            status: RecordingStatus.recording,
            station: station,
            path: path,
            elapsed: DateTime.now().difference(now),
          ),
        );
      });
    } catch (error, stack) {
      _reset();
      DhwaniLog.recorder('Unable to start recording', error, stack);
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.error,
          station: station,
          message: 'Recording could not start.',
        ),
      );
      rethrow;
    }
  }

  Future<RecordingEntry> stop() async {
    final session = _session;
    final path = _path;
    final station = _station;
    final startedAt = _startedAt;
    if (session == null ||
        path == null ||
        station == null ||
        startedAt == null) {
      throw StateError('No recording is active');
    }
    state.add(
      RecordingSnapshot(
        status: RecordingStatus.stopping,
        station: station,
        path: path,
        elapsed: DateTime.now().difference(startedAt),
      ),
    );
    _timer?.cancel();
    await FFmpegKit.cancel(session.getSessionId());
    await _finished?.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
    final file = File(path);
    if (!await file.exists() || await file.length() <= 1024) {
      _reset();
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.error,
          station: station,
          message: 'Recording could not be saved.',
        ),
      );
      throw StateError('Recording output is missing or empty');
    }
    final probe = await FFprobeKit.getMediaInformation(path);
    final information = probe.getMediaInformation();
    if (information == null) {
      _reset();
      state.add(
        RecordingSnapshot(
          status: RecordingStatus.error,
          station: station,
          message: 'Saved file format was not recognised.',
        ),
      );
      throw StateError('FFprobe could not recognise recording');
    }
    final elapsed = DateTime.now().difference(startedAt);
    final entry = RecordingEntry(
      id: const Uuid().v4(),
      station: station,
      path: path,
      name: path.split(Platform.pathSeparator).last,
      createdAt: startedAt,
      duration: elapsed,
      sizeBytes: await file.length(),
      format: path.split('.').last.toLowerCase(),
    );
    await database.addRecording(entry);
    _reset();
    state.add(
      RecordingSnapshot(
        status: RecordingStatus.saved,
        station: station,
        path: path,
        elapsed: elapsed,
        message: 'Recording saved',
      ),
    );
    return entry;
  }

  Future<void> cancel() async {
    final session = _session;
    final path = _path;
    if (session != null) await FFmpegKit.cancel(session.getSessionId());
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    _reset();
    state.add(const RecordingSnapshot(status: RecordingStatus.idle));
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

  void _reset() {
    _timer?.cancel();
    _timer = null;
    _session = null;
    _path = null;
    _station = null;
    _startedAt = null;
    _finished = null;
  }
}
