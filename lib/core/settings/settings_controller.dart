import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DhwaniSettings {
  const DhwaniSettings({
    this.themeMode = ThemeMode.system,
    this.reducedMotion = false,
    this.autoPlay = false,
    this.autoReconnect = true,
    this.wifiOnly = false,
    this.preferLowerBitrate = false,
    this.backgroundPlayback = true,
    this.recordingFormat = 'auto',
    this.defaultScope = 'city',
    this.equalizerPreset = 'flat',
    this.equalizerGains = const [],
  });

  final ThemeMode themeMode;
  final bool reducedMotion;
  final bool autoPlay;
  final bool autoReconnect;
  final bool wifiOnly;
  final bool preferLowerBitrate;
  final bool backgroundPlayback;
  final String recordingFormat;
  final String defaultScope;
  final String equalizerPreset;
  final List<double> equalizerGains;

  Map<String, Object?> toJson() => {
    'themeMode': themeMode.name,
    'reducedMotion': reducedMotion,
    'autoPlay': autoPlay,
    'autoReconnect': autoReconnect,
    'wifiOnly': wifiOnly,
    'preferLowerBitrate': preferLowerBitrate,
    'backgroundPlayback': backgroundPlayback,
    'recordingFormat': recordingFormat,
    'defaultScope': defaultScope,
    'equalizerPreset': equalizerPreset,
    'equalizerGains': equalizerGains,
  };

  factory DhwaniSettings.fromJson(
    Map<String, Object?> json, {
    DhwaniSettings fallback = const DhwaniSettings(),
  }) => DhwaniSettings(
    themeMode: ThemeMode.values.firstWhere(
      (mode) => mode.name == json['themeMode'],
      orElse: () => fallback.themeMode,
    ),
    reducedMotion: json['reducedMotion'] as bool? ?? fallback.reducedMotion,
    autoPlay: json['autoPlay'] as bool? ?? fallback.autoPlay,
    autoReconnect: json['autoReconnect'] as bool? ?? fallback.autoReconnect,
    wifiOnly: json['wifiOnly'] as bool? ?? fallback.wifiOnly,
    preferLowerBitrate:
        json['preferLowerBitrate'] as bool? ?? fallback.preferLowerBitrate,
    backgroundPlayback:
        json['backgroundPlayback'] as bool? ?? fallback.backgroundPlayback,
    recordingFormat: {'auto', 'mp3', 'm4a'}.contains(json['recordingFormat'])
        ? json['recordingFormat']! as String
        : fallback.recordingFormat,
    defaultScope:
        {'city', 'state', 'country', 'worldwide'}.contains(json['defaultScope'])
        ? json['defaultScope']! as String
        : fallback.defaultScope,
    equalizerPreset:
        {
          'flat',
          'voice',
          'bass',
          'treble',
          'custom',
        }.contains(json['equalizerPreset'])
        ? json['equalizerPreset']! as String
        : fallback.equalizerPreset,
    equalizerGains: (json['equalizerGains'] as List? ?? const [])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList(),
  );

  DhwaniSettings copyWith({
    ThemeMode? themeMode,
    bool? reducedMotion,
    bool? autoPlay,
    bool? autoReconnect,
    bool? wifiOnly,
    bool? preferLowerBitrate,
    bool? backgroundPlayback,
    String? recordingFormat,
    String? defaultScope,
    String? equalizerPreset,
    List<double>? equalizerGains,
  }) => DhwaniSettings(
    themeMode: themeMode ?? this.themeMode,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    autoPlay: autoPlay ?? this.autoPlay,
    autoReconnect: autoReconnect ?? this.autoReconnect,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    preferLowerBitrate: preferLowerBitrate ?? this.preferLowerBitrate,
    backgroundPlayback: backgroundPlayback ?? this.backgroundPlayback,
    recordingFormat: recordingFormat ?? this.recordingFormat,
    defaultScope: defaultScope ?? this.defaultScope,
    equalizerPreset: equalizerPreset ?? this.equalizerPreset,
    equalizerGains: equalizerGains ?? this.equalizerGains,
  );
}

class SettingsController extends Notifier<DhwaniSettings> {
  late SharedPreferences _preferences;

  @override
  DhwaniSettings build() {
    _preferences = ref.read(sharedPreferencesForSettingsProvider);
    return DhwaniSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == _preferences.getString('themeMode'),
        orElse: () => ThemeMode.system,
      ),
      reducedMotion: _preferences.getBool('reducedMotion') ?? false,
      autoPlay: _preferences.getBool('autoPlay') ?? false,
      autoReconnect: _preferences.getBool('autoReconnect') ?? true,
      wifiOnly: _preferences.getBool('wifiOnly') ?? false,
      preferLowerBitrate: _preferences.getBool('preferLowerBitrate') ?? false,
      backgroundPlayback: _preferences.getBool('backgroundPlayback') ?? true,
      recordingFormat: _preferences.getString('recordingFormat') ?? 'auto',
      defaultScope: _preferences.getString('defaultScope') ?? 'city',
      equalizerPreset: _preferences.getString('equalizerPreset') ?? 'flat',
      equalizerGains: (_preferences.getStringList('equalizerGains') ?? const [])
          .map(double.tryParse)
          .whereType<double>()
          .toList(),
    );
  }

  Future<void> update(DhwaniSettings value) async {
    state = value;
    await Future.wait([
      _preferences.setString('themeMode', value.themeMode.name),
      _preferences.setBool('reducedMotion', value.reducedMotion),
      _preferences.setBool('autoPlay', value.autoPlay),
      _preferences.setBool('autoReconnect', value.autoReconnect),
      _preferences.setBool('wifiOnly', value.wifiOnly),
      _preferences.setBool('preferLowerBitrate', value.preferLowerBitrate),
      _preferences.setBool('backgroundPlayback', value.backgroundPlayback),
      _preferences.setString('recordingFormat', value.recordingFormat),
      _preferences.setString('defaultScope', value.defaultScope),
      _preferences.setString('equalizerPreset', value.equalizerPreset),
      _preferences.setStringList(
        'equalizerGains',
        value.equalizerGains.map((gain) => '$gain').toList(),
      ),
    ]);
  }
}

final sharedPreferencesForSettingsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final settingsProvider = NotifierProvider<SettingsController, DhwaniSettings>(
  SettingsController.new,
);
