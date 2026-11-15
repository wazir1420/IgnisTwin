import '../models/sensor_reading.dart';

/// Data ka source. Dummy ho ya real ESP32, dono isi interface ko follow karte hain.
abstract class SensorService {
  /// Exception phenkta hai agar sensor se data na aaye (offline).
  Future<SensorReading> read();
}
