import '../models/sensor_reading.dart';

/// Data ka source. Firebase ya ESP32, dono isi interface ko follow karte hain.
abstract class SensorService {
  int get sensorCount => 1;

  /// Exception phenkta hai agar sensor se data na aaye (offline).
  Future<SensorReading> read();

  /// Listener waghera band karne ke liye
  void dispose();
}
