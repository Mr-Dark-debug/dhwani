import 'package:dhwani/core/recording/recording_service.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recording filename is portable, deterministic, and descriptive', () {
    const station = RadioStation(
      id: 'air:69',
      name: 'Akashvani Darbhanga / 1296',
      country: 'India',
      countryCode: 'IN',
      band: RadioBand.am,
      streams: [],
      directory: RadioDirectory.akashvani,
    );

    expect(
      RecordingService.fileName(
        station,
        DateTime(2026, 8, 16, 23, 30, 5),
        'm4a',
      ),
      'Dhwani_Akashvani-Darbhanga-1296_2026-08-16_23-30-05.m4a',
    );
  });
}
