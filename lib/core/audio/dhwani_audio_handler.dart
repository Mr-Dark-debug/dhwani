import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/models/radio_station.dart';
import '../logging/dhwani_log.dart';
import 'dhwani_audio_engine.dart';
import 'playback_failure.dart';

enum DhwaniPlaybackStatus {
  idle,
  selected,
  switching,
  connecting,
  loading,
  ready,
  buffering,
  playing,
  paused,
  reconnecting,
  unavailable,
  offline,
  geoBlocked,
  unsupported,
  error,
}

class DhwaniPlayerSnapshot {
  const DhwaniPlayerSnapshot({
    required this.status,
    this.station,
    this.stream,
    this.message,
    this.icyTitle,
    this.failure,
    this.operationId = 0,
  });

  final DhwaniPlaybackStatus status;
  final RadioStation? station;
  final StationStream? stream;
  final String? message;
  final String? icyTitle;
  final PlaybackFailure? failure;
  final int operationId;

  bool get busy => switch (status) {
    DhwaniPlaybackStatus.switching ||
    DhwaniPlaybackStatus.connecting ||
    DhwaniPlaybackStatus.loading ||
    DhwaniPlaybackStatus.buffering ||
    DhwaniPlaybackStatus.reconnecting => true,
    _ => false,
  };
}

class DhwaniAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  DhwaniAudioHandler({
    DhwaniAudioEngine? engine,
    Future<int> Function(RadioStation station)? onSessionStarted,
    Future<void> Function(int sessionId, Duration duration)? onSessionUpdated,
    Future<void> Function(
      RadioStation station,
      StationStream stream,
      bool success,
      PlaybackFailure? failure,
      Duration? startupTime,
    )?
    onStreamResult,
    this.perSourceTimeout = const Duration(seconds: 10),
    this.stationTimeout = const Duration(seconds: 24),
    this.playConfirmationTimeout = const Duration(seconds: 4),
    this.bufferingTimeout = const Duration(seconds: 14),
    bool enablePlatformIntegrations = true,
    Future<List<ConnectivityResult>> Function()? connectivityCheck,
    Stream<List<ConnectivityResult>>? connectivityChanges,
  }) : _onSessionStarted = onSessionStarted,
       _onSessionUpdated = onSessionUpdated,
       _onStreamResult = onStreamResult,
       _connectivityCheck =
           connectivityCheck ?? Connectivity().checkConnectivity {
    if (engine == null) {
      final equalizer = AndroidEqualizer();
      _equalizer = equalizer;
      _engine = JustAudioEngine(equalizer: equalizer);
    } else {
      _equalizer = null;
      _engine = engine;
    }
    _listenToEngine();
    if (enablePlatformIntegrations) {
      unawaited(_initializePlatform(connectivityChanges));
    } else if (connectivityChanges != null) {
      _listenToConnectivity(connectivityChanges);
    }
  }

  final Future<int> Function(RadioStation station)? _onSessionStarted;
  final Future<void> Function(int sessionId, Duration duration)?
  _onSessionUpdated;
  final Future<void> Function(
    RadioStation station,
    StationStream stream,
    bool success,
    PlaybackFailure? failure,
    Duration? startupTime,
  )?
  _onStreamResult;
  final Future<List<ConnectivityResult>> Function() _connectivityCheck;

  final Duration perSourceTimeout;
  final Duration stationTimeout;
  final Duration playConfirmationTimeout;
  final Duration bufferingTimeout;

  late final DhwaniAudioEngine _engine;
  AndroidEqualizer? _equalizer;
  final BehaviorSubject<DhwaniPlayerSnapshot> snapshot = BehaviorSubject.seeded(
    const DhwaniPlayerSnapshot(status: DhwaniPlaybackStatus.idle),
  );

  List<RadioStation> _stations = const [];
  RadioStation? _currentStation;
  int _index = -1;
  StationStream? _activeStream;
  int _operationId = 0;
  bool _wantsPlayback = false;
  bool _loadingCandidate = false;
  int _runtimeReconnectAttempts = 0;
  String? _icyTitle;
  PlaybackFailure? _lastFailure;

  StreamSubscription<AudioInterruptionEvent>? _interruption;
  StreamSubscription<void>? _noisy;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<PlayerException>? _errorSubscription;
  StreamSubscription<IcyMetadata?>? _icySubscription;
  Timer? _reconnectTimer;
  Timer? _bufferingTimer;

  DateTime? _sessionStartedAt;
  RadioStation? _sessionStation;
  Future<int?>? _sessionIdFuture;

  bool _wifiOnly = false;
  bool _preferLowerBitrate = false;
  bool _autoReconnect = true;
  bool _networkWasUnavailable = false;
  String _equalizerPreset = 'flat';
  String _equalizerConfiguration = 'flat';

  RadioStation? get currentStation => _currentStation;
  StationStream? get activeStream => _activeStream;
  List<RadioStation> get queueStations => List.unmodifiable(_stations);
  bool get intendsPlayback => _wantsPlayback;
  int get operationId => _operationId;
  PlaybackFailure? get lastFailure => _lastFailure;
  bool get equalizerSupported => Platform.isAndroid && _equalizer != null;
  String get equalizerPreset => _equalizerPreset;
  bool get isBusy => snapshot.value.busy;

  void configureNetworkPolicy({
    required bool wifiOnly,
    required bool preferLowerBitrate,
    required bool autoReconnect,
  }) {
    _wifiOnly = wifiOnly;
    _preferLowerBitrate = preferLowerBitrate;
    _autoReconnect = autoReconnect;
    if (!autoReconnect) _reconnectTimer?.cancel();
  }

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
    final equalizer = _equalizer;
    if (!equalizerSupported || equalizer == null) return null;
    try {
      await equalizer.setEnabled(true).timeout(const Duration(seconds: 5));
      return await equalizer.parameters.timeout(const Duration(seconds: 5));
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
    final equalizer = _equalizer;
    final parameters = await equalizerParameters();
    if (parameters == null || equalizer == null) return;
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
    await equalizer.setEnabled(preset != 'flat');
  }

  void _listenToEngine() {
    _playerStateSubscription = _engine.playerStateStream.listen(
      _handlePlayerState,
      onError: (Object error, StackTrace stack) {
        DhwaniLog.player('Player state stream failed', error, stack);
        unawaited(_handleRuntimeFailure(error, stack));
      },
    );
    _errorSubscription = _engine.errorStream.listen((error) {
      if (_loadingCandidate) {
        DhwaniLog.player('Candidate load emitted an error', error);
        return;
      }
      unawaited(_handleRuntimeFailure(error, StackTrace.current));
    });
    _icySubscription = _engine.icyMetadataStream.listen((metadata) {
      final title = metadata?.info?.title?.trim();
      if (title == null || title.isEmpty || _currentStation == null) return;
      _icyTitle = title;
      _emit(
        snapshot.value.status,
        station: _currentStation,
        stream: _activeStream,
        message: snapshot.value.message,
      );
    });
  }

  Future<void> _initializePlatform(
    Stream<List<ConnectivityResult>>? connectivityChanges,
  ) async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _interruption = session.interruptionEventStream.listen((event) {
        if (event.begin && _wantsPlayback) unawaited(pause());
      });
      _noisy = session.becomingNoisyEventStream.listen((_) {
        if (_wantsPlayback) unawaited(pause());
      });
      _listenToConnectivity(
        connectivityChanges ?? Connectivity().onConnectivityChanged,
      );
    } catch (error, stack) {
      DhwaniLog.player('Platform audio initialization failed', error, stack);
    }
  }

  void _listenToConnectivity(Stream<List<ConnectivityResult>> changes) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = changes.listen((results) {
      final available = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!available) {
        _networkWasUnavailable = true;
        if (_wantsPlayback && _currentStation != null) {
          final operation = ++_operationId;
          _cancelTimers();
          unawaited(_stopEngineExpected());
          unawaited(_finishSession());
          final failure = classifyPlaybackFailure(
            const SocketException('Connection offline'),
          );
          _lastFailure = failure;
          _emit(
            DhwaniPlaybackStatus.offline,
            station: _currentStation,
            stream: _activeStream,
            failure: failure,
            operation: operation,
          );
        }
        return;
      }
      if (_networkWasUnavailable &&
          _autoReconnect &&
          _wantsPlayback &&
          _currentStation?.canPlay == true) {
        _networkWasUnavailable = false;
        _scheduleReconnect();
      }
    });
  }

  Future<void> setQueueStations(
    List<RadioStation> stations, {
    RadioStation? selected,
  }) async {
    _stations = _deduplicateStations(stations);
    final target = selected ?? _currentStation;
    if (target != null && !_stations.any((item) => item.id == target.id)) {
      _stations.insert(0, target);
    }
    _index = target == null
        ? (_stations.isEmpty ? -1 : 0)
        : _stations.indexWhere((item) => item.id == target.id);
    queue.add(_stations.map(_mediaItem).toList());
    _broadcastMediaState();
  }

  Future<void> tuneStation(
    RadioStation station, {
    List<RadioStation>? queueStations,
    bool autoplay = false,
  }) async {
    final operation = ++_operationId;
    _cancelTimers();
    _runtimeReconnectAttempts = 0;
    _wantsPlayback = autoplay;
    _lastFailure = null;
    _icyTitle = null;
    final previous = _currentStation;
    _currentStation = station;
    if (queueStations != null) {
      _stations = _deduplicateStations(queueStations);
    }
    if (!_stations.any((item) => item.id == station.id)) {
      _stations.insert(0, station);
    }
    _index = _stations.indexWhere((item) => item.id == station.id);
    queue.add(_stations.map(_mediaItem).toList());
    mediaItem.add(_mediaItem(station));
    _activeStream = null;
    _emit(
      previous?.id == station.id
          ? DhwaniPlaybackStatus.selected
          : DhwaniPlaybackStatus.switching,
      station: station,
      operation: operation,
    );

    await _finishSession();
    await _stopEngineExpected();
    if (!_isActive(operation, station)) return;
    _emit(DhwaniPlaybackStatus.ready, station: station, operation: operation);
    if (autoplay) await _attemptStation(operation, station);
  }

  Future<void> selectStation(RadioStation station, {bool autoplay = false}) =>
      tuneStation(station, autoplay: autoplay);

  @override
  Future<void> play() async {
    final station = _currentStation;
    if (station == null) return;
    final operation = ++_operationId;
    _cancelTimers();
    _runtimeReconnectAttempts = 0;
    _wantsPlayback = true;
    _lastFailure = null;

    if (_activeStream != null &&
        _engine.processingState != ProcessingState.idle &&
        _engine.processingState != ProcessingState.completed) {
      _emit(
        DhwaniPlaybackStatus.connecting,
        station: station,
        stream: _activeStream,
        operation: operation,
      );
      try {
        await _startPlaybackAndConfirm(operation, station);
        if (!_isActive(operation, station)) return;
        _beginSession(operation, station);
        _emit(
          DhwaniPlaybackStatus.playing,
          station: station,
          stream: _activeStream,
          operation: operation,
        );
      } catch (error, stack) {
        if (!_isActive(operation, station)) return;
        await _finishWithFailure(
          operation,
          station,
          error,
          stack,
          runtime: true,
        );
      }
      return;
    }
    await _attemptStation(operation, station);
  }

  Future<void> _attemptStation(int operation, RadioStation station) async {
    if (!_isActive(operation, station)) return;
    final connectivity = await _connectivityCheck().catchError((Object error) {
      DhwaniLog.player(
        'Connectivity check failed; stream remains authoritative',
        error,
      );
      return <ConnectivityResult>[];
    });
    if (!_isActive(operation, station)) return;
    final hasKnownNetwork = connectivity.any(
      (value) => value != ConnectivityResult.none,
    );
    final unmetered = connectivity.any(
      (value) =>
          value == ConnectivityResult.wifi ||
          value == ConnectivityResult.ethernet,
    );
    if (connectivity.isNotEmpty && !hasKnownNetwork) {
      final failure = classifyPlaybackFailure(
        const SocketException('Connection offline'),
      );
      _lastFailure = failure;
      _emit(
        DhwaniPlaybackStatus.offline,
        station: station,
        failure: failure,
        operation: operation,
      );
      return;
    }
    if (_wifiOnly && !unmetered) {
      const failure = PlaybackFailure(
        reason: PlaybackFailureReason.offline,
        userTitle: 'Wi-Fi connection required',
        userMessage:
            'Wi-Fi only is enabled. Connect to Wi-Fi to play live radio.',
        diagnostic: 'Playback blocked by the user Wi-Fi-only policy.',
      );
      _lastFailure = failure;
      _emit(
        DhwaniPlaybackStatus.offline,
        station: station,
        failure: failure,
        operation: operation,
      );
      return;
    }

    final streams = _playableStreams(station);
    if (streams.isEmpty) {
      final failure = noPlayableStreamFailure();
      _lastFailure = failure;
      _emit(
        DhwaniPlaybackStatus.unsupported,
        station: station,
        failure: failure,
        operation: operation,
      );
      return;
    }
    if (_preferLowerBitrate && !unmetered) {
      streams.sort(
        (a, b) => (a.bitrate ?? 1 << 30).compareTo(b.bitrate ?? 1 << 30),
      );
    }

    final started = DateTime.now();
    final deadline = started.add(stationTimeout);
    Object? lastError;
    StackTrace? lastStack;
    PlaybackFailure? lastFailure;
    final attempted = <String>{};
    for (final stream in streams) {
      if (!_isActive(operation, station)) return;
      if (!attempted.add(stream.url)) continue;
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        lastError = TimeoutException('Whole-station startup deadline expired');
        lastStack = StackTrace.current;
        lastFailure = classifyPlaybackFailure(lastError);
        break;
      }
      final candidateTimeout = remaining < perSourceTimeout
          ? remaining
          : perSourceTimeout;
      _activeStream = stream;
      _emit(
        attempted.length == 1
            ? DhwaniPlaybackStatus.connecting
            : DhwaniPlaybackStatus.reconnecting,
        station: station,
        stream: stream,
        message: attempted.length == 1
            ? 'Connecting…'
            : 'Trying another stream…',
        operation: operation,
      );
      try {
        _loadingCandidate = true;
        await _engine
            .setUrl(
              stream.url,
              headers: Uri.parse(stream.url).scheme == 'file'
                  ? null
                  : _streamHeaders,
            )
            .timeout(candidateTimeout);
        _loadingCandidate = false;
        if (!_isActive(operation, station)) return;
        await _startPlaybackAndConfirm(
          operation,
          station,
          timeout: _minimumDuration(
            playConfirmationTimeout,
            deadline.difference(DateTime.now()),
          ),
        );
        if (!_isActive(operation, station)) return;
        _runtimeReconnectAttempts = 0;
        _beginSession(operation, station);
        unawaited(
          _recordStreamResult(
            station,
            stream,
            true,
            null,
            DateTime.now().difference(started),
          ),
        );
        _emit(
          DhwaniPlaybackStatus.playing,
          station: station,
          stream: stream,
          operation: operation,
        );
        return;
      } on PlayerInterruptedException catch (error, stack) {
        _loadingCandidate = false;
        if (!_isActive(operation, station)) return;
        lastError = error;
        lastStack = stack;
        lastFailure = classifyPlaybackFailure(error);
      } catch (error, stack) {
        _loadingCandidate = false;
        if (!_isActive(operation, station)) return;
        lastError = error;
        lastStack = stack;
        lastFailure = classifyPlaybackFailure(error);
      }
      if (!_isActive(operation, station)) return;
      await _stopEngineExpected();
      unawaited(_recordStreamResult(station, stream, false, lastFailure, null));
      DhwaniLog.player(
        'Stream candidate failed (${lastFailure.reason.name}): ${_safeHost(stream.url)}',
        lastError,
        lastStack,
      );
    }

    if (!_isActive(operation, station)) return;
    await _finishWithFailure(
      operation,
      station,
      lastError ?? TimeoutException('No stream candidate completed'),
      lastStack ?? StackTrace.current,
      failure: lastFailure,
    );
  }

  Future<void> _startPlaybackAndConfirm(
    int operation,
    RadioStation station, {
    Duration? timeout,
  }) async {
    final failure = Completer<Object>();
    final playFuture = _engine.play();
    unawaited(
      playFuture.catchError((Object error, StackTrace stack) {
        if (!failure.isCompleted && _isActive(operation, station)) {
          failure.complete(error);
        }
      }),
    );
    if (_engine.playing) return;
    final confirmation = _engine.playerStateStream
        .firstWhere((state) => state.playing)
        .then<Object?>((_) => null);
    final result = await Future.any<Object?>([confirmation, failure.future])
        .timeout(
          timeout == null || timeout <= Duration.zero
              ? playConfirmationTimeout
              : timeout,
        );
    if (result != null) throw result;
  }

  @override
  Future<void> pause() async {
    final operation = ++_operationId;
    _wantsPlayback = false;
    _cancelTimers();
    try {
      await _engine.pause().timeout(const Duration(seconds: 3));
    } catch (error, stack) {
      DhwaniLog.player('Pause failed', error, stack);
    }
    await _finishSession();
    _emit(
      DhwaniPlaybackStatus.paused,
      station: _currentStation,
      stream: _activeStream,
      operation: operation,
    );
  }

  @override
  Future<void> stop() async {
    final operation = ++_operationId;
    _wantsPlayback = false;
    _cancelTimers();
    await _stopEngineExpected();
    await _finishSession();
    _emit(
      _currentStation == null
          ? DhwaniPlaybackStatus.idle
          : DhwaniPlaybackStatus.selected,
      station: _currentStation,
      stream: _activeStream,
      operation: operation,
    );
    await super.stop();
  }

  Future<void> retry() async {
    _activeStream = null;
    await play();
  }

  Future<void> setVolume(double volume) =>
      _engine.setVolume(volume.clamp(0, 1));
  double get volume => _engine.volume;

  @override
  Future<void> skipToNext() async {
    await tuneRelative(1, autoplay: true);
  }

  @override
  Future<void> skipToPrevious() async {
    await tuneRelative(-1, autoplay: true);
  }

  Future<RadioStation?> tuneRelative(int delta, {bool? autoplay}) async {
    if (_stations.isEmpty) return null;
    final currentIndex = _index < 0 ? 0 : _index;
    final targetIndex = (currentIndex + delta).remainder(_stations.length) < 0
        ? (currentIndex + delta).remainder(_stations.length) + _stations.length
        : (currentIndex + delta).remainder(_stations.length);
    final target = _stations[targetIndex];
    await tuneStation(
      target,
      queueStations: _stations,
      autoplay: autoplay ?? _wantsPlayback,
    );
    return target;
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _stations.length) return;
    await tuneStation(
      _stations[index],
      queueStations: _stations,
      autoplay: true,
    );
  }

  void _handlePlayerState(PlayerState state) {
    _broadcastMediaState();
    final station = _currentStation;
    if (station == null || !_wantsPlayback || _loadingCandidate) return;
    final status = snapshot.value.status;
    if (state.processingState == ProcessingState.buffering &&
        status != DhwaniPlaybackStatus.connecting &&
        status != DhwaniPlaybackStatus.reconnecting) {
      _emit(
        DhwaniPlaybackStatus.buffering,
        station: station,
        stream: _activeStream,
        message: 'Buffering…',
      );
      _startBufferingDeadline(_operationId, station);
      return;
    }
    if (state.playing && state.processingState == ProcessingState.ready) {
      _bufferingTimer?.cancel();
      _beginSession(_operationId, station);
      _emit(
        DhwaniPlaybackStatus.playing,
        station: station,
        stream: _activeStream,
      );
      return;
    }
    if (state.processingState == ProcessingState.completed &&
        status == DhwaniPlaybackStatus.playing) {
      unawaited(
        _handleRuntimeFailure(
          StateError('Live stream ended unexpectedly'),
          StackTrace.current,
        ),
      );
    }
  }

  void _startBufferingDeadline(int operation, RadioStation station) {
    _bufferingTimer?.cancel();
    _bufferingTimer = Timer(bufferingTimeout, () {
      if (_isActive(operation, station) &&
          snapshot.value.status == DhwaniPlaybackStatus.buffering) {
        unawaited(
          _handleRuntimeFailure(
            TimeoutException('Runtime buffering deadline expired'),
            StackTrace.current,
          ),
        );
      }
    });
  }

  Future<void> _handleRuntimeFailure(Object error, StackTrace stack) async {
    final station = _currentStation;
    final stream = _activeStream;
    if (station == null ||
        stream == null ||
        !_wantsPlayback ||
        _loadingCandidate) {
      return;
    }
    final operation = ++_operationId;
    _cancelTimers();
    final failure = classifyPlaybackFailure(error, runtime: true);
    _lastFailure = failure;
    await _finishSession();
    await _stopEngineExpected();
    if (!_isActive(operation, station)) return;
    unawaited(_recordStreamResult(station, stream, false, failure, null));
    DhwaniLog.player(
      'Runtime stream failure (${failure.reason.name}): ${_safeHost(stream.url)}',
      error,
      stack,
    );
    if (_autoReconnect && _runtimeReconnectAttempts < 3) {
      _runtimeReconnectAttempts++;
      final delay = Duration(seconds: 1 << (_runtimeReconnectAttempts - 1));
      _emit(
        DhwaniPlaybackStatus.reconnecting,
        station: station,
        stream: stream,
        message: 'Reconnecting in ${delay.inSeconds}s…',
        failure: failure,
        operation: operation,
      );
      _reconnectTimer = Timer(delay, () {
        if (!_isActive(operation, station) || !_wantsPlayback) return;
        final reconnectOperation = ++_operationId;
        unawaited(_attemptStation(reconnectOperation, station));
      });
      return;
    }
    _emitFailure(operation, station, stream, failure);
  }

  void _scheduleReconnect() {
    final station = _currentStation;
    if (station == null || !_wantsPlayback) return;
    _reconnectTimer?.cancel();
    final operation = ++_operationId;
    _emit(
      DhwaniPlaybackStatus.reconnecting,
      station: station,
      stream: _activeStream,
      message: 'Network restored. Reconnecting…',
      operation: operation,
    );
    _reconnectTimer = Timer(const Duration(seconds: 1), () {
      if (_isActive(operation, station) && _wantsPlayback) {
        unawaited(_attemptStation(operation, station));
      }
    });
  }

  Future<void> _finishWithFailure(
    int operation,
    RadioStation station,
    Object error,
    StackTrace stack, {
    PlaybackFailure? failure,
    bool runtime = false,
  }) async {
    if (!_isActive(operation, station)) return;
    await _finishSession();
    final classified =
        failure ?? classifyPlaybackFailure(error, runtime: runtime);
    _lastFailure = classified;
    DhwaniLog.player(
      'Station attempt failed (${classified.reason.name})',
      error,
      stack,
    );
    _emitFailure(operation, station, _activeStream, classified);
  }

  void _emitFailure(
    int operation,
    RadioStation station,
    StationStream? stream,
    PlaybackFailure failure,
  ) {
    final status = switch (failure.reason) {
      PlaybackFailureReason.offline => DhwaniPlaybackStatus.offline,
      PlaybackFailureReason.geoBlocked => DhwaniPlaybackStatus.geoBlocked,
      PlaybackFailureReason.unsupported ||
      PlaybackFailureReason.noStream ||
      PlaybackFailureReason.cleartextPolicy => DhwaniPlaybackStatus.unsupported,
      _ => DhwaniPlaybackStatus.unavailable,
    };
    _emit(
      status,
      station: station,
      stream: stream,
      failure: failure,
      operation: operation,
    );
  }

  Future<void> _recordStreamResult(
    RadioStation station,
    StationStream stream,
    bool success,
    PlaybackFailure? failure,
    Duration? startupTime,
  ) async {
    try {
      await _onStreamResult?.call(
        station,
        stream,
        success,
        failure,
        startupTime,
      );
    } catch (error, stack) {
      DhwaniLog.database(
        'Could not persist local station health',
        error,
        stack,
      );
    }
  }

  void _beginSession(int operation, RadioStation station) {
    if (!_isActive(operation, station) ||
        _sessionStartedAt != null && _sessionStation?.id == station.id) {
      return;
    }
    _sessionStartedAt = DateTime.now();
    _sessionStation = station;
    final callback = _onSessionStarted;
    _sessionIdFuture = callback == null
        ? Future<int?>.value()
        : callback(station).then<int?>((value) => value).catchError((
            Object error,
            StackTrace stack,
          ) {
            DhwaniLog.database('Could not start history session', error, stack);
            return null;
          });
  }

  Future<void> _finishSession() async {
    final startedAt = _sessionStartedAt;
    final station = _sessionStation;
    final sessionIdFuture = _sessionIdFuture;
    _sessionStartedAt = null;
    _sessionStation = null;
    _sessionIdFuture = null;
    if (startedAt == null || station == null || sessionIdFuture == null) return;
    final duration = DateTime.now().difference(startedAt);
    final sessionId = await sessionIdFuture;
    if (sessionId == null || _onSessionUpdated == null) return;
    try {
      await _onSessionUpdated(sessionId, duration);
    } catch (error, stack) {
      DhwaniLog.database('Could not finish history session', error, stack);
    }
  }

  Future<void> _stopEngineExpected() async {
    try {
      await _engine.stop().timeout(const Duration(seconds: 3));
    } on PlayerInterruptedException {
      // A newer tune intentionally superseded the active load.
    } catch (error, stack) {
      DhwaniLog.player('Player stop during transition failed', error, stack);
    }
  }

  bool _isActive(int operation, RadioStation station) =>
      operation == _operationId && _currentStation?.id == station.id;

  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _bufferingTimer?.cancel();
  }

  List<StationStream> _playableStreams(RadioStation station) {
    final seen = <String>{};
    return station.rankedStreams.where((stream) {
      final uri = Uri.tryParse(stream.url.trim());
      final supportedScheme =
          uri?.scheme == 'https' ||
          uri?.scheme == 'http' ||
          (station.sourceType == RadioSourceType.localRecording &&
              uri?.scheme == 'file');
      if (uri == null ||
          !uri.hasScheme ||
          (!uri.hasAuthority && uri.scheme != 'file') ||
          !supportedScheme ||
          uri.userInfo.isNotEmpty ||
          !seen.add(uri.toString())) {
        return false;
      }
      return true;
    }).toList();
  }

  List<RadioStation> _deduplicateStations(List<RadioStation> stations) {
    final ids = <String>{};
    return stations.where((station) => ids.add(station.id)).toList();
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

  void _emit(
    DhwaniPlaybackStatus status, {
    RadioStation? station,
    StationStream? stream,
    String? message,
    PlaybackFailure? failure,
    int? operation,
  }) {
    snapshot.add(
      DhwaniPlayerSnapshot(
        status: status,
        station: station,
        stream: stream,
        message: message ?? failure?.userMessage,
        icyTitle: _icyTitle,
        failure: failure,
        operationId: operation ?? _operationId,
      ),
    );
    _broadcastMediaState();
  }

  void _broadcastMediaState() {
    final state = snapshot.value;
    final processing = switch (state.status) {
      DhwaniPlaybackStatus.switching ||
      DhwaniPlaybackStatus.connecting ||
      DhwaniPlaybackStatus.loading ||
      DhwaniPlaybackStatus.reconnecting => AudioProcessingState.loading,
      DhwaniPlaybackStatus.buffering => AudioProcessingState.buffering,
      DhwaniPlaybackStatus.error ||
      DhwaniPlaybackStatus.unavailable ||
      DhwaniPlaybackStatus.offline ||
      DhwaniPlaybackStatus.geoBlocked ||
      DhwaniPlaybackStatus.unsupported => AudioProcessingState.error,
      _ => switch (_engine.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
    };
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          state.status == DhwaniPlaybackStatus.playing
              ? MediaControl.pause
              : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 3],
        processingState: processing,
        playing:
            state.status == DhwaniPlaybackStatus.playing && _engine.playing,
        updatePosition: _engine.position,
        bufferedPosition: _engine.bufferedPosition,
        speed: _engine.speed,
        queueIndex: _index < 0 ? null : _index,
        errorMessage: state.failure?.userTitle,
      ),
    );
  }

  Future<void> disposeHandler() async {
    ++_operationId;
    _wantsPlayback = false;
    _cancelTimers();
    await _finishSession();
    await _interruption?.cancel();
    await _noisy?.cancel();
    await _connectivitySubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _icySubscription?.cancel();
    await snapshot.close();
    await _engine.dispose();
  }

  static const _streamHeaders = {
    'User-Agent': 'Dhwani/1 (com.prashant.dhwani)',
    'Accept': '*/*',
    'Accept-Encoding': 'identity',
    'Icy-MetaData': '1',
  };

  static Duration _minimumDuration(Duration a, Duration b) {
    if (b <= Duration.zero) return const Duration(milliseconds: 1);
    return a < b ? a : b;
  }

  static String _safeHost(String value) =>
      Uri.tryParse(value)?.host.isNotEmpty == true
      ? Uri.parse(value).host
      : '<invalid-host>';
}
