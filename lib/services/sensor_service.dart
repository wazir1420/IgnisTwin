import '../models/sensor_reading.dart';


abstract class SensorService {
  int get sensorCount => 1;


  Future<SensorReading> read();


  void dispose();
}
