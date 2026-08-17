import 'package:dhwani/core/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings backup parser validates constrained values', () {
    final settings = DhwaniSettings.fromJson({
      'themeMode': 'dark',
      'autoPlay': true,
      'recordingFormat': 'mp3',
      'defaultScope': 'country',
      'equalizerPreset': 'custom',
      'equalizerGains': [1, 2.5, -1],
    });

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.autoPlay, isTrue);
    expect(settings.recordingFormat, 'mp3');
    expect(settings.defaultScope, 'country');
    expect(settings.equalizerGains, [1, 2.5, -1]);
  });

  test('settings parser rejects unsupported imported choices', () {
    final settings = DhwaniSettings.fromJson({
      'recordingFormat': 'exe',
      'defaultScope': 'somewhere',
      'equalizerPreset': 'explode',
    });

    expect(settings.recordingFormat, 'auto');
    expect(settings.defaultScope, 'city');
    expect(settings.equalizerPreset, 'flat');
  });
}
