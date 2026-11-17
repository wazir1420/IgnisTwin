import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_reading.dart';
import 'sensor_service.dart';

/// Real ESP32 se data (ESP32 par WebServer ka /data endpoint chalna chahiye)
class Esp32SensorService implements SensorService {
  final String ip;
  Esp32SensorService(this.ip);

  @override
  Future<SensorReading> read() async {
    final r = await http.get(Uri.parse('http://$ip/data')).timeout(const Duration(seconds: 3));
    return SensorReading.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  @override
  void dispose() {}
}
