import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TemperatureStore {
  static final TemperatureStore _singleton = new TemperatureStore._internal();
  static List<TemperatureReading> _temperatureReadings = [];

  List<TemperatureReading> get data => _temperatureReadings;

  factory TemperatureStore() {
    return _singleton;
  }
  final RegExp _timeParser = new RegExp(r"(.+\.\d{1,6})\d*.*Z");
  static int _lastCall = (DateTime.now().millisecondsSinceEpoch / 1000).floor() - 7*24*3600;

  Future<bool> updateStore() async {
    int now = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    int interval = now - _lastCall;
    if (interval < 10) {
      return true;
    }

    final response = await http.get(
      'https://aare-tempi.data.thethingsnetwork.org/api/v2/query/tempi-sensor-aarweg?last=${interval}s',
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.authorizationHeader:
            'key ttn-account-v2.vO1iK1sVuNaUq-zm8aDVNK53d_uHv9eEO8lrDbMbyX0'
      },
    );

    switch (response.statusCode) {
      case 200:
            // If the call to the server was successful, parse the JSON.
        for (Map item in json.decode(response.body)) {
          var match = _timeParser.firstMatch(item['time']);
          _temperatureReadings.add(TemperatureReading(
            celsius1: item['celsius1'],
            celsius2: item['celsius2'],
            volt: item['volt'],
            time: DateTime.parse(match[1] + 'Z')
          ));
        }
        continue ok;
      ok:
      case 204: // no content
        _lastCall = now;
        return true;
        break;
      default:
         // If that call was not successful, throw an error.
        throw Exception(response.reasonPhrase);
        break;
    }
  }

  TemperatureStore._internal();
}

class TemperatureReading {
  final num celsius1;
  final num celsius2;
  final num volt;
  final DateTime time;

  TemperatureReading({this.celsius1, this.celsius2, this.volt, this.time});
}
