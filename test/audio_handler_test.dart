import 'dart:async';

import 'package:dhwani/core/audio/dhwani_audio_engine.dart';
import 'package:dhwani/core/audio/dhwani_audio_handler.dart';
import 'package:dhwani/core/audio/playback_failure.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  group('DhwaniAudioHandler operation state machine', () {
    test(
      'live play returns control without waiting for broadcast completion',
      () async {
        final engine = FakeAudioEngine(endlessPlayFuture: true);
        final handler = _handler(engine);
        final station = _station('live', 'https://live.test/stream');

        await handler
            .tuneStation(station, queueStations: [station], autoplay: true)
            .timeout(const Duration(milliseconds: 250));

        expect(handler.snapshot.value.status, DhwaniPlaybackStatus.playing);
        await handler.disposeHandler();
      },
    );

    test('a newer tune cancels stale completion and wins', () async {
      final engine = FakeAudioEngine(
        loadDelays: {
          'https://slow.test/live': const Duration(milliseconds: 80),
        },
      );
      final handler = _handler(engine);
      final slow = _station('slow', 'https://slow.test/live');
      final fast = _station('fast', 'https://fast.test/live');

      final first = handler.tuneStation(
        slow,
        queueStations: [slow, fast],
        autoplay: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await handler.tuneStation(
        fast,
        queueStations: [slow, fast],
        autoplay: true,
      );
      await first;

      expect(handler.currentStation?.id, 'fast');
      expect(handler.snapshot.value.station?.id, 'fast');
      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.playing);
      await handler.disposeHandler();
    });

    test('a timed-out source falls back within the station deadline', () async {
      final engine = FakeAudioEngine(hangingUrls: {'https://dead.test/live'});
      final handler = _handler(
        engine,
        perSourceTimeout: const Duration(milliseconds: 25),
        stationTimeout: const Duration(milliseconds: 150),
      );
      final station = _station(
        'fallback',
        'https://dead.test/live',
        alternative: 'https://working.test/live',
      );

      await handler.tuneStation(
        station,
        queueStations: [station],
        autoplay: true,
      );

      expect(
        engine.loadedUrls,
        containsAllInOrder([
          'https://dead.test/live',
          'https://working.test/live',
        ]),
      );
      expect(handler.activeStream?.url, 'https://working.test/live');
      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.playing);
      await handler.disposeHandler();
    });

    test(
      'failed connection never creates a listening-history session',
      () async {
        var sessions = 0;
        final engine = FakeAudioEngine(failingUrls: {'https://dead.test/live'});
        final handler = _handler(
          engine,
          onSessionStarted: (_) async => ++sessions,
          perSourceTimeout: const Duration(milliseconds: 25),
          stationTimeout: const Duration(milliseconds: 50),
        );
        final station = _station('dead', 'https://dead.test/live');

        await handler.tuneStation(
          station,
          queueStations: [station],
          autoplay: true,
        );

        expect(sessions, 0);
        expect(handler.snapshot.value.status, DhwaniPlaybackStatus.unavailable);
        expect(handler.snapshot.value.failure, isNotNull);
        await handler.disposeHandler();
      },
    );

    test(
      '100 rapid next/previous intents settle on the newest station',
      () async {
        final engine = FakeAudioEngine();
        final handler = _handler(engine);
        final stations = List.generate(
          5,
          (index) => _station('station-$index', 'https://s$index.test/live'),
        );
        await handler.tuneStation(
          stations.first,
          queueStations: stations,
          autoplay: false,
        );

        final operations = <Future<RadioStation?>>[];
        for (var index = 0; index < 100; index++) {
          operations.add(handler.tuneRelative(index.isEven ? 1 : -1));
        }
        await Future.wait(operations);

        expect(handler.snapshot.value.busy, isFalse);
        expect(handler.snapshot.value.failure, isNull);
        expect(handler.snapshot.value.station?.id, handler.currentStation?.id);
        expect(handler.snapshot.value.status, DhwaniPlaybackStatus.ready);
        await handler.disposeHandler();
      },
    );

    test('pause, resume, retry, and stop reach deterministic states', () async {
      final engine = FakeAudioEngine(
        failuresRemaining: {'https://retry.test/live': 1},
      );
      final handler = _handler(engine);
      final station = _station('retry', 'https://retry.test/live');

      await handler.tuneStation(
        station,
        queueStations: [station],
        autoplay: true,
      );
      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.unavailable);

      await handler.retry();
      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.playing);
      await handler.pause();
      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.paused);
      await handler.play();
      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.playing);
      await handler.stop();
      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.selected);
      await handler.disposeHandler();
    });

    test('known offline state terminates without loading a source', () async {
      final engine = FakeAudioEngine();
      final handler = _handler(
        engine,
        connectivityCheck: () async => [ConnectivityResult.none],
      );
      final station = _station('offline', 'https://offline.test/live');

      await handler.tuneStation(
        station,
        queueStations: [station],
        autoplay: true,
      );

      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.offline);
      expect(engine.loadedUrls, isEmpty);
      await handler.disposeHandler();
    });

    test('runtime stream end reconnects once and returns to playing', () async {
      final engine = FakeAudioEngine();
      final handler = _handler(engine);
      final station = _station('runtime', 'https://runtime.test/live');
      await handler.tuneStation(
        station,
        queueStations: [station],
        autoplay: true,
      );

      engine.emitCompleted();
      await handler.snapshot
          .firstWhere(
            (snapshot) => snapshot.status == DhwaniPlaybackStatus.reconnecting,
          )
          .timeout(const Duration(milliseconds: 250));
      await handler.snapshot
          .firstWhere(
            (snapshot) => snapshot.status == DhwaniPlaybackStatus.playing,
          )
          .timeout(const Duration(seconds: 2));

      expect(engine.loadedUrls.length, 2);
      await handler.disposeHandler();
    });

    test('a newer station cancels a scheduled runtime reconnect', () async {
      final engine = FakeAudioEngine();
      final handler = _handler(engine);
      final first = _station('first', 'https://first.test/live');
      final second = _station('second', 'https://second.test/live');
      await handler.tuneStation(
        first,
        queueStations: [first, second],
        autoplay: true,
      );

      engine.emitCompleted();
      await handler.snapshot
          .firstWhere(
            (snapshot) => snapshot.status == DhwaniPlaybackStatus.reconnecting,
          )
          .timeout(const Duration(milliseconds: 250));
      await handler.tuneStation(
        second,
        queueStations: [first, second],
        autoplay: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(handler.currentStation?.id, 'second');
      expect(handler.snapshot.value.status, DhwaniPlaybackStatus.playing);
      expect(
        engine.loadedUrls.where((url) => url == 'https://first.test/live'),
        hasLength(1),
      );
      await handler.disposeHandler();
    });
  });

  group('playback failure classification', () {
    test('sanitizes query credentials from diagnostics', () {
      final failure = classifyPlaybackFailure(
        Exception(
          'failed https://radio.test/live?token=private-value&channel=one',
        ),
      );

      expect(failure.diagnostic, isNot(contains('private-value')));
      expect(failure.diagnostic, contains('redacted'));
    });

    test('reports policy and HTTP failures with actionable categories', () {
      expect(
        classifyPlaybackFailure(Exception('CLEARTEXT not permitted')).reason,
        PlaybackFailureReason.cleartextPolicy,
      );
      expect(
        classifyPlaybackFailure(Exception('HTTP 404')).reason,
        PlaybackFailureReason.notFound,
      );
      expect(
        classifyPlaybackFailure(Exception('HTTP 403')).reason,
        PlaybackFailureReason.geoBlocked,
      );
    });
  });
}

DhwaniAudioHandler _handler(
  FakeAudioEngine engine, {
  Future<int> Function(RadioStation)? onSessionStarted,
  Duration perSourceTimeout = const Duration(milliseconds: 100),
  Duration stationTimeout = const Duration(milliseconds: 300),
  Future<List<ConnectivityResult>> Function()? connectivityCheck,
}) => DhwaniAudioHandler(
  engine: engine,
  enablePlatformIntegrations: false,
  connectivityCheck: connectivityCheck ?? () async => [ConnectivityResult.wifi],
  onSessionStarted: onSessionStarted,
  perSourceTimeout: perSourceTimeout,
  stationTimeout: stationTimeout,
  playConfirmationTimeout: const Duration(milliseconds: 100),
  bufferingTimeout: const Duration(milliseconds: 100),
);

RadioStation _station(String id, String url, {String? alternative}) =>
    RadioStation(
      id: id,
      name: id,
      country: 'Testland',
      countryCode: 'TT',
      band: RadioBand.net,
      streams: [
        StationStream(url: url),
        if (alternative != null) StationStream(url: alternative),
      ],
      directory: RadioDirectory.custom,
    );

class FakeAudioEngine implements DhwaniAudioEngine {
  FakeAudioEngine({
    this.loadDelays = const {},
    this.hangingUrls = const {},
    this.failingUrls = const {},
    this.failuresRemaining = const {},
    this.endlessPlayFuture = false,
  });

  final Map<String, Duration> loadDelays;
  final Set<String> hangingUrls;
  final Set<String> failingUrls;
  final Map<String, int> failuresRemaining;
  final bool endlessPlayFuture;
  final List<String> loadedUrls = [];
  final _states = StreamController<PlayerState>.broadcast();
  final _errors = StreamController<PlayerException>.broadcast();
  final _metadata = StreamController<IcyMetadata?>.broadcast();
  bool _playing = false;
  ProcessingState _processingState = ProcessingState.idle;
  double _volume = 1;

  @override
  Stream<PlayerState> get playerStateStream => _states.stream;
  @override
  Stream<PlayerException> get errorStream => _errors.stream;
  @override
  Stream<IcyMetadata?> get icyMetadataStream => _metadata.stream;
  @override
  bool get playing => _playing;
  @override
  ProcessingState get processingState => _processingState;
  @override
  Duration get position => Duration.zero;
  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  double get speed => 1;
  @override
  double get volume => _volume;

  @override
  Future<Duration?> setUrl(String url, {Map<String, String>? headers}) async {
    loadedUrls.add(url);
    _playing = false;
    _processingState = ProcessingState.loading;
    _states.add(PlayerState(false, ProcessingState.loading));
    if (hangingUrls.contains(url)) return Completer<Duration?>().future;
    final delay = loadDelays[url];
    if (delay != null) await Future<void>.delayed(delay);
    final remaining = failuresRemaining[url] ?? 0;
    if (remaining > 0) {
      failuresRemaining[url] = remaining - 1;
      throw Exception('HTTP 404');
    }
    if (failingUrls.contains(url)) throw Exception('HTTP 404');
    _processingState = ProcessingState.ready;
    _states.add(PlayerState(false, ProcessingState.ready));
    return null;
  }

  @override
  Future<void> play() async {
    _playing = true;
    _processingState = ProcessingState.ready;
    _states.add(PlayerState(true, ProcessingState.ready));
    if (endlessPlayFuture) return Completer<void>().future;
  }

  void emitCompleted() {
    _playing = false;
    _processingState = ProcessingState.completed;
    _states.add(PlayerState(false, ProcessingState.completed));
  }

  @override
  Future<void> pause() async {
    _playing = false;
    _states.add(PlayerState(false, _processingState));
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _processingState = ProcessingState.idle;
    _states.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> setVolume(double volume) async => _volume = volume;

  @override
  Future<void> dispose() async {
    await _states.close();
    await _errors.close();
    await _metadata.close();
  }
}
