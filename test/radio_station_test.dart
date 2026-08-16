import 'package:dhwani/data/models/radio_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadioStation', () {
    test('maps Akashvani Darbhanga without inventing RF playback', () {
      final station = RadioStation.fromAkashvani({
        'name': 'Akashvani Darbhanga',
        'state': 'BIHAR',
        'language': 'Maithili, Hindi',
        'stream_url':
            'https://air.pc.cdn.bitgravity.com/air/live/pbaudio160/playlist.m3u8',
        'epg_id': 69,
      });

      expect(station.id, 'air:69');
      expect(station.band, RadioBand.am);
      expect(station.frequency, 1296);
      expect(station.frequencyUnit, 'kHz');
      expect(station.city, 'Darbhanga');
      expect(station.languages, ['Maithili', 'Hindi']);
      expect(station.streams.single.hls, isTrue);
      expect(station.canPlay, isTrue);
    });

    test('parses real AM/FM forms and leaves unknown stations as NET', () {
      expect(RadioStation.parseFrequency('Akashvani 1296 kHz'), (
        RadioBand.am,
        1296,
        'kHz',
      ));
      expect(RadioStation.parseFrequency('Radio Mirchi 98.3 FM'), (
        RadioBand.fm,
        98.3,
        'MHz',
      ));
      expect(RadioStation.parseFrequency('BBC World Service'), (
        RadioBand.net,
        null,
        null,
      ));
    });

    test('round trips structured metadata', () {
      final original = _station(
        id: 'one',
        name: 'Radio One 98.3 FM',
        band: RadioBand.fm,
        frequency: 98.3,
      );
      final decoded = RadioStation.decode(original.encode());

      expect(decoded.id, original.id);
      expect(decoded.frequencyDisplay, '98.3');
      expect(decoded.frequencySubtitle, 'MHz • FM');
      expect(decoded.streams.single.url, original.streams.single.url);
    });

    test('ranks recent success, fewer failures, and HTTPS', () {
      final now = DateTime(2026, 8, 17);
      final station = _station(id: 'rank', name: 'Rank').copyWith(
        streams: [
          const StationStream(url: 'http://example.test/no-history'),
          const StationStream(
            url: 'https://example.test/failed',
            failureCount: 3,
          ),
          StationStream(url: 'https://example.test/recent', lastSuccess: now),
        ],
      );

      expect(station.rankedStreams.first.url, endsWith('/recent'));
      expect(station.rankedStreams.last.url, endsWith('/failed'));
    });

    test('maps Radio Browser health and searchable metadata', () {
      final station = RadioStation.fromRadioBrowser({
        'stationuuid': 'browser-1',
        'name': 'Radio Mirchi 98.3 FM',
        'country': 'India',
        'countrycode': 'IN',
        'state': 'Bihar',
        'language': 'Hindi',
        'tags': 'music,bollywood',
        'url_resolved': 'https://example.test/mirchi.aac',
        'codec': 'AAC',
        'bitrate': 96,
        'lastcheckok': 1,
        'clickcount': 42,
      });

      expect(station.band, RadioBand.fm);
      expect(station.frequency, 98.3);
      expect(station.health, StationHealth.online);
      expect(station.streams.single.bitrate, 96);
      expect(station.searchableText, contains('bollywood'));
      expect(station.searchableText, contains('98.3'));
    });
  });
}

RadioStation _station({
  required String id,
  required String name,
  RadioBand band = RadioBand.net,
  double? frequency,
}) => RadioStation(
  id: id,
  name: name,
  country: 'India',
  countryCode: 'IN',
  state: 'Bihar',
  city: 'Darbhanga',
  band: band,
  frequency: frequency,
  frequencyUnit: frequency == null
      ? null
      : band == RadioBand.am
      ? 'kHz'
      : 'MHz',
  streams: const [StationStream(url: 'https://example.test/live.mp3')],
  directory: RadioDirectory.offlineSeed,
);
