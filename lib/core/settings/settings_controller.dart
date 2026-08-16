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
  });

  final ThemeMode themeMode;
  final bool reducedMotion;
  final bool autoPlay;
  final bool autoReconnect;
  final bool wifiOnly;
  final bool preferLowerBitrate;
  final bool backgroundPlayback;

  DhwaniSettings copyWith({
    ThemeMode? themeMode,
    bool? reducedMotion,
    bool? autoPlay,
    bool? autoReconnect,
    bool? wifiOnly,
    bool? preferLowerBitrate,
    bool? backgroundPlayback,
  }) => DhwaniSettings(
    themeMode: themeMode ?? this.themeMode,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    autoPlay: autoPlay ?? this.autoPlay,
    autoReconnect: autoReconnect ?? this.autoReconnect,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    preferLowerBitrate: preferLowerBitrate ?? this.preferLowerBitrate,
    backgroundPlayback: backgroundPlayback ?? this.backgroundPlayback,
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
    ]);
  }
}

final sharedPreferencesForSettingsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final settingsProvider = NotifierProvider<SettingsController, DhwaniSettings>(
  SettingsController.new,
);
