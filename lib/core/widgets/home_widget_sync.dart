import 'dart:io';

import 'package:flutter/services.dart';

import '../../data/models/radio_station.dart';
import '../audio/dhwani_audio_handler.dart';

class HomeWidgetSync {
  static const MethodChannel _channel = MethodChannel('com.prashant.dhwani/widget');

  static Future<void> update({
    RadioStation? station,
    DhwaniPlaybackStatus? status,
    String? icyTitle,
    int? stationIndex,
    List<RadioStation>? favourites,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      final data = <String, Object>{};

      if (station != null) {
        data['station_name'] = station.name;
        data['station_frequency'] = station.frequencyDisplay;
        data['station_freq_unit'] =
            station.frequency != null ? ' ${station.frequencyUnit ?? 'MHz'}' : '';
        data['station_band'] = station.bandLabel;
        data['station_country'] = station.country.isNotEmpty ? station.country : 'Global';

        final freq = station.frequency;
        if (freq != null) {
          final base = freq.round();
          data['dial_1'] = '${base - 1}';
          data['dial_2'] = '$base';
          data['dial_3'] = '${base + 1}';
          data['dial_4'] = '${base + 2}';
        }
      }

      if (stationIndex != null) {
        data['station_index'] = '${stationIndex + 1}';
      }

      if (status != null) {
        data['is_playing'] = status == DhwaniPlaybackStatus.playing;
      }

      if (icyTitle != null) {
        data['icy_title'] = icyTitle;
      }

      if (favourites != null && favourites.isNotEmpty) {
        data['fav1_id'] = favourites[0].id;
        data['fav1_name'] = favourites[0].name;
        data['fav1_freq'] = favourites[0].frequencyDisplay;

        if (favourites.length > 1) {
          data['fav2_id'] = favourites[1].id;
          data['fav2_name'] = favourites[1].name;
          data['fav2_freq'] = favourites[1].frequencyDisplay;
        }
      }

      if (data.isNotEmpty) {
        await _channel.invokeMethod('updateWidgetState', data);
      }
    } catch (_) {
      // Ignore channel errors if app is not running in full android runtime
    }
  }
}
