import 'package:dhwani/app/providers.dart';
import 'package:dhwani/data/models/radio_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widens a single-city queue through state before country', () {
    final darbhanga = _station('darbhanga', 'Darbhanga', 'Bihar', 1296);
    final patna = _station('patna', 'Patna', 'Bihar', 621);
    final delhi = _station('delhi', 'Delhi', 'Delhi', 819);

    final queue = tuningQueue(
      [darbhanga, patna, delhi],
      current: darbhanga,
      band: RadioBand.am,
    );

    expect(queue.map((station) => station.id), ['patna', 'darbhanga']);
  });

  test('known frequencies sort ahead of unknown frequency streams', () {
    final current = _station('a', 'Darbhanga', 'Bihar', 1296);
    final lower = _station('b', 'Darbhanga', 'Bihar', 621);
    final unknown = _station('c', 'Darbhanga', 'Bihar', null);

    final queue = tuningQueue([current, unknown, lower], current: current);

    expect(queue.map((station) => station.id), ['b', 'a', 'c']);
  });

  test('preferred country scope starts with all playable country stations', () {
    final darbhanga = _station('darbhanga', 'Darbhanga', 'Bihar', 1296);
    final delhi = _station('delhi', 'Delhi', 'Delhi', 819);
    final foreign = RadioStation.fromJson({
      ..._station('foreign', 'Berlin', 'Berlin', 855).toJson(),
      'country': 'Germany',
      'countryCode': 'DE',
    });

    final queue = tuningQueue(
      [darbhanga, delhi, foreign],
      current: darbhanga,
      preferredScope: 'country',
    );

    expect(queue.map((station) => station.id), ['delhi', 'darbhanga']);
  });
}

RadioStation _station(
  String id,
  String city,
  String state,
  double? frequency,
) => RadioStation(
  id: id,
  name: id,
  country: 'India',
  countryCode: 'IN',
  state: state,
  city: city,
  band: frequency == null ? RadioBand.net : RadioBand.am,
  frequency: frequency,
  frequencyUnit: frequency == null ? null : 'kHz',
  streams: const [StationStream(url: 'https://example.test/live')],
  directory: RadioDirectory.offlineSeed,
);
