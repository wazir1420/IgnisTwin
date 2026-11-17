import '../models/sensor_reading.dart';

/// Data ka source. Dummy, Firebase ya ESP32, sab isi interface ko follow karte hain.
abstract class SensorService {
  /// Exception phenkta hai agar sensor se data na aaye (offline).
  Future<SensorReading> read();

  /// Listener waghera band karne ke liye
  void dispose();
}
