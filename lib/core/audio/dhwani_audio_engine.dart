import 'package:just_audio/just_audio.dart';

/// Small boundary around just_audio so live-operation concurrency can be
/// exercised without a platform player or an unreliable public station.
abstract interface class DhwaniAudioEngine {
  Stream<PlayerState> get playerStateStream;
  Stream<PlayerException> get errorStream;
  Stream<IcyMetadata?> get icyMetadataStream;

  bool get playing;
  ProcessingState get processingState;
  Duration get position;
  Duration get bufferedPosition;
  double get speed;
  double get volume;

  Future<Duration?> setUrl(String url, {Map<String, String>? headers});
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

class JustAudioEngine implements DhwaniAudioEngine {
  JustAudioEngine({required AndroidEqualizer equalizer})
    : _player = AudioPlayer(
        userAgent: 'Dhwani/1 (com.prashant.dhwani)',
        // Android ExoPlayer supports request headers directly. Avoid the
        // localhost proxy, which adds a device-dependent cleartext hop and can
        // surface transport failures outside the player's fallback pipeline.
        useProxyForRequestHeaders: false,
        audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
      );

  final AudioPlayer _player;

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  Stream<PlayerException> get errorStream => _player.errorStream;

  @override
  Stream<IcyMetadata?> get icyMetadataStream => _player.icyMetadataStream;

  @override
  bool get playing => _player.playing;

  @override
  ProcessingState get processingState => _player.processingState;

  @override
  Duration get position => _player.position;

  @override
  Duration get bufferedPosition => _player.bufferedPosition;

  @override
  double get speed => _player.speed;

  @override
  double get volume => _player.volume;

  @override
  Future<Duration?> setUrl(String url, {Map<String, String>? headers}) =>
      _player.setUrl(url, headers: headers);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> dispose() => _player.dispose();
}
