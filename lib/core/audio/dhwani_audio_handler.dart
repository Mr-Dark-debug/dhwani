import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/models/radio_station.dart';
import '../logging/dhwani_log.dart';

enum DhwaniPlaybackStatus {
  idle,
  loading,
  ready,
  buffering,
  playing,
  paused,
  reconnecting,
  error,
}

class DhwaniPlayerSnapshot {
  const DhwaniPlayerSnapshot({
    required this.status,
    this.station,
    this.stream,
    this.message,
    this.icyTitle,
  });

  final DhwaniPlaybackStatus status;
  final RadioStation? station;
  final StationStream? stream;
  final String? message;
  final String? icyTitle;
}

class DhwaniAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  DhwaniAudioHandler({
    Future<void> Function(RadioStation station, Duration duration)?
    onSessionEnded,
    Future<void> Function(
      RadioStation station,
      StationStream stream,
      bool success,
    )?
    onStreamResult,
  }) : _onSessionEnded = onSessionEnded,
       _onStreamResult = onStreamResult {
    _init();
  }

  final Future<void> Function(RadioStation station, Duration duration)?
  _onSessionEnded;
  final Future<void> Function(
    RadioStation station,
    StationStream stream,
    bool success,
  )?
  _onStreamResult;

  final AndroidEqualizer _equalizer = AndroidEqualizer();
  late final AudioPlayer _player = AudioPlayer(
    userAgent: 'Dhwani/1.0 (com.prashant.dhwani)',
    audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer]),
  );
  final BehaviorSubject<DhwaniPlayerSnapshot> snapshot = BehaviorSubject.seeded(
    const DhwaniPlayerSnapshot(status: DhwaniPlaybackStatus.idle),
  );
  List<RadioStation> _stations = const [];
  int _index = -1;
  StationStream? _activeStream;
  StreamSubscription<AudioInterruptionEvent>? _interruption;
  StreamSubscription<void>? _noisy;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _reconnectTimer;
  DateTime? _sessionStartedAt;
  RadioStation? _sessionStation;

  RadioStation? get currentStation =>
      _index >= 0 && _index < _stations.length ? _stations[_index] : null;
  bool _wifiOnly = false;
  bool _preferLowerBitrate = false;
  bool _autoReconnect = true;
  bool _networkWasUnavailable = false;
  String _equalizerPreset = 'flat';
  String _equalizerConfiguration = 'flat';

  void configureNetworkPolicy({
    required bool wifiOnly,
    required bool preferLowerBitrate,
    required bool autoReconnect,
  }) {
    _wifiOnly = wifiOnly;
    _preferLowerBitrate = preferLowerBitrate;
    _autoReconnect = autoReconnect;
  }

  StationStream? get activeStream => _activeStream;
  bool get equalizerSupported => Platform.isAndroid;
  String get equalizerPreset => _equalizerPreset;

  void configureEqualizer(
    String preset, {
    List<double> customGains = const [],
  }) {
    final configuration = '$preset:${customGains.join(',')}';
    if (!equalizerSupported || configuration == _equalizerConfiguration) return;
    _equalizerPreset = preset;
    _equalizerConfiguration = configuration;
    unawaited(_applyEqualizerPreset(preset, customGains));
  }

  Future<AndroidEqualizerParameters?> equalizerParameters() async {
    if (!equalizerSupported) return null;
    try {
      await _equalizer.setEnabled(true).timeout(const Duration(seconds: 5));
      return await _equalizer.parameters.timeout(const Duration(seconds: 5));
    } catch (error, stack) {
      DhwaniLog.player('Android equalizer is unavailable', error, stack);
      return null;
    }
  }

  Future<void> setEqualizerBand(int index, double gain) async {
    final parameters = await equalizerParameters();
    if (parameters == null || index < 0 || index >= parameters.bands.length) {
      return;
    }
    await parameters.bands[index].setGain(
      gain.clamp(parameters.minDecibels, parameters.maxDecibels).toDouble(),
    );
    _equalizerPreset = 'custom';
  }

  Future<void> _applyEqualizerPreset(
    String preset,
    List<double> customGains,
  ) async {
    final parameters = await equalizerParameters();
    if (parameters == null) return;
    for (final band in parameters.bands) {
      final frequency = band.centerFrequency;
      final gain = switch (preset) {
        'custom' when band.index < customGains.length =>
          customGains[band.index],
        'voice' =>
          frequency >= 300 && frequency <= 3500
              ? 4.0
              : frequency < 150
              ? -2.0
              : -1.0,
        'bass' =>
          frequency < 250
              ? 5.0
              : frequency > 4000
              ? -1.0
              : 0.0,
        'treble' =>
          frequency > 4000
              ? 5.0
              : frequency < 250
              ? -1.0
              : 0.0,
        _ => 0.0,
      };
      await band.setGain(
        gain.clamp(parameters.minDecibels, parameters.maxDecibels).toDouble(),
      );
    }
    await _equalizer.setEnabled(preset != 'flat');
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _interruption = session.interruptionEventStream.listen((event) {
      if (event.begin && _player.playing) pause();
    });
    _noisy = session.becomingNoisyEventStream.listen((_) {
      if (_player.playing) pause();
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final available = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!available) {
        _networkWasUnavailable = true;
        return;
      }
      if (_networkWasUnavailable &&
          _autoReconnect &&
          snapshot.value.status == DhwaniPlaybackStatus.error &&
          currentStation?.canPlay == true) {
        _networkWasUnavailable = false;
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 1), play);
      }
    });
    _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (Object error, StackTrace stack) {
        DhwaniLog.player('Playback event error', error, stack);
        snapshot.add(
          DhwaniPlayerSnapshot(
            status: DhwaniPlaybackStatus.error,
            station: currentStation,
            stream: _activeStream,
            message: 'Station isn’t responding.',
          ),
        );
        _broadcastState(error: error.toString());
      },
    );
    _player.icyMetadataStream.listen((metadata) {
      final title = metadata?.info?.title?.trim();
      if (title != null && title.isNotEmpty) {
        snapshot.add(
          DhwaniPlayerSnapshot(
            status: _status,
            station: currentStation,
            stream: _activeStream,
            icyTitle: title,
          ),
        );
      }
    });
  }

  Future<void> setQueueStations(
    List<RadioStation> stations, {
    RadioStation? selected,
  }) async {
    _stations = [...stations];
    if (selected != null) {
      final found = _stations.indexWhere(
        (station) => station.id == selected.id,
      );
      if (found < 0) _stations.insert(0, selected);
      _index = found < 0 ? 0 : found;
    } else if (_stations.isNotEmpty && _index < 0) {
      _index = 0;
    }
    queue.add(_stations.map(_mediaItem).toList());
    if (currentStation != null) mediaItem.add(_mediaItem(currentStation!));
    _broadcastState();
  }

  Future<void> selectStation(
    RadioStation station, {
    bool autoplay = false,
  }) async {
    if (currentStation?.id != station.id) await _finishSession();
    final found = _stations.indexWhere((item) => item.id == station.id);
    if (found < 0) {
      _stations = [station, ..._stations];
      _index = 0;
    } else {
      _index = found;
    }
    queue.add(_stations.map(_mediaItem).toList());
    mediaItem.add(_mediaItem(station));
    _activeStream = null;
    snapshot.add(
      DhwaniPlayerSnapshot(
        status: DhwaniPlaybackStatus.ready,
        station: station,
      ),
    );
    _broadcastState();
    if (autoplay) await play();
  }

  @override
  Future<void> play() async {
    final station = currentStation;
    if (station == null) return;
    if (_activeStream != null &&
        _player.processingState != ProcessingState.idle &&
        _player.processingState != ProcessingState.completed) {
      await _player.play();
      _beginSession(station);
      snapshot.add(
        DhwaniPlayerSnapshot(
          status: DhwaniPlaybackStatus.playing,
          station: station,
          stream: _activeStream,
        ),
      );
      return;
    }
    if (!station.canPlay) {
      snapshot.add(
        DhwaniPlayerSnapshot(
          status: DhwaniPlaybackStatus.error,
          station: station,
          message: 'No internet stream is mapped.',
        ),
      );
      return;
    }
    final connectivity = await Connectivity().checkConnectivity();
    final unmetered = connectivity.any(
      (value) =>
          value == ConnectivityResult.wifi ||
          value == ConnectivityResult.ethernet,
    );
    if (_wifiOnly && !unmetered) {
      snapshot.add(
        DhwaniPlayerSnapshot(
          status: DhwaniPlaybackStatus.error,
          station: station,
          message:
              'Wi-Fi only is enabled. Connect to Wi-Fi to play live radio.',
        ),
      );
      return;
    }
    snapshot.add(
      DhwaniPlayerSnapshot(
        status: DhwaniPlaybackStatus.loading,
        station: station,
      ),
    );
    Object? lastError;
    final streams = station.rankedStreams.where((stream) {
      final scheme = Uri.tryParse(stream.url)?.scheme.toLowerCase();
      return scheme != 'http' || station.userAdded;
    }).toList();
    if (streams.isEmpty) {
      snapshot.add(
        DhwaniPlayerSnapshot(
          status: DhwaniPlaybackStatus.error,
          station: station,
          message:
              'This directory stream uses unencrypted HTTP. Add it as a trusted custom station to play it.',
        ),
      );
      return;
    }
    if (_preferLowerBitrate && !unmetered) {
      streams.sort(
        (a, b) => (a.bitrate ?? 1 << 30).compareTo(b.bitrate ?? 1 << 30),
      );
    }
    for (final stream in streams) {
      try {
        _activeStream = stream;
        await _player
            .setUrl(stream.url)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('Stream connection timed out');
              },
            );
        await _player.play();
        _beginSession(station);
        await _onStreamResult?.call(station, stream, true);
        snapshot.add(
          DhwaniPlayerSnapshot(
            status: DhwaniPlaybackStatus.playing,
            station: station,
            stream: stream,
          ),
        );
        return;
      } catch (error, stack) {
        await _player.stop();
        await _onStreamResult?.call(station, stream, false);
        lastError = error;
        DhwaniLog.player('Stream failed: ${stream.url}', error, stack);
        snapshot.add(
          DhwaniPlayerSnapshot(
            status: DhwaniPlaybackStatus.reconnecting,
            station: station,
            stream: stream,
            message: 'Trying another stream…',
          ),
        );
      }
    }
    snapshot.add(
      DhwaniPlayerSnapshot(
        status: DhwaniPlaybackStatus.error,
        station: station,
        stream: _activeStream,
        message: 'Station isn’t responding. ${lastError ?? ''}'.trim(),
      ),
    );
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    await _finishSession();
    snapshot.add(
      DhwaniPlayerSnapshot(
        status: DhwaniPlaybackStatus.paused,
        station: currentStation,
        stream: _activeStream,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _finishSession();
    snapshot.add(
      DhwaniPlayerSnapshot(
        status: DhwaniPlaybackStatus.ready,
        station: currentStation,
        stream: _activeStream,
      ),
    );
    await super.stop();
  }

  Future<void> retry() => play();

  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0, 1));
  double get volume => _player.volume;

  @override
  Future<void> skipToNext() async {
    if (_stations.isEmpty) return;
    _index = (_index + 1) % _stations.length;
    await selectStation(_stations[_index], autoplay: true);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_stations.isEmpty) return;
    _index = (_index - 1 + _stations.length) % _stations.length;
    await selectStation(_stations[_index], autoplay: true);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _stations.length) return;
    _index = index;
    await selectStation(_stations[index], autoplay: true);
  }

  DhwaniPlaybackStatus get _status {
    if (_player.processingState == ProcessingState.loading) {
      return DhwaniPlaybackStatus.loading;
    }
    if (_player.processingState == ProcessingState.buffering) {
      return DhwaniPlaybackStatus.buffering;
    }
    if (_player.playing) return DhwaniPlaybackStatus.playing;
    if (currentStation != null) return DhwaniPlaybackStatus.paused;
    return DhwaniPlaybackStatus.idle;
  }

  MediaItem _mediaItem(RadioStation station) => MediaItem(
    id: station.id,
    title: station.name,
    artist: [
      station.city,
      station.state,
      station.country,
    ].whereType<String>().join(', '),
    album: station.frequency == null
        ? 'Live internet radio'
        : '${station.frequencyDisplay} ${station.frequencyUnit}',
    artUri: _validArtworkUri(station.favicon),
    playable: station.canPlay,
    extras: {'station': station.toJson()},
  );

  Uri? _validArtworkUri(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }

  void _broadcastState({String? error}) {
    final processing = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 3],
        processingState: error == null
            ? processing
            : AudioProcessingState.error,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _index < 0 ? null : _index,
        errorMessage: error,
      ),
    );
    final current = currentStation;
    if (current != null &&
        snapshot.value.status != DhwaniPlaybackStatus.error &&
        snapshot.value.status != DhwaniPlaybackStatus.reconnecting) {
      snapshot.add(
        DhwaniPlayerSnapshot(
          status: _status,
          station: current,
          stream: _activeStream,
          icyTitle: snapshot.value.icyTitle,
        ),
      );
    }
  }

  void _beginSession(RadioStation station) {
    if (_sessionStartedAt != null && _sessionStation?.id == station.id) return;
    _sessionStartedAt = DateTime.now();
    _sessionStation = station;
  }

  Future<void> _finishSession() async {
    final startedAt = _sessionStartedAt;
    final station = _sessionStation;
    _sessionStartedAt = null;
    _sessionStation = null;
    if (startedAt == null || station == null || _onSessionEnded == null) return;
    final duration = DateTime.now().difference(startedAt);
    if (duration < const Duration(seconds: 1)) return;
    await _onSessionEnded(station, duration);
  }

  Future<void> disposeHandler() async {
    await _finishSession();
    await _interruption?.cancel();
    await _noisy?.cancel();
    await _connectivitySubscription?.cancel();
    _reconnectTimer?.cancel();
    await snapshot.close();
    await _player.dispose();
  }
}
