import 'dart:math';
import '../models/sensor_reading.dart';
import 'sensor_service.dart';

/// Hardware ke baghair demo data. Har 70 second ka ek chakkar chalta hai:
///   0-15s   normal
///  15-30s   smoke barhta hai  -> WARNING
///  30-50s   flame + zyada smoke -> CRITICAL (incident ban jata hai)
///  50-60s   aag bujh jati hai, smoke kam hota hai
///  60-66s   sensor offline (error)
///  66-70s   normal
class DummySensorService implements SensorService {
  final _rng = Random(7);
  int _tick = 0;
  static const _cycle = 70;

  @override
  Future<SensorReading> read() async {
    final t = _tick++ % _cycle;
    var flame = false;
    int smoke;

    if (t < 15) {
      smoke = 350 + _rng.nextInt(150);
    } else if (t < 30) {
      smoke = 500 + (t - 15) * 90 + _rng.nextInt(80);
    } else if (t < 50) {
      flame = true;
      smoke = 2600 + _rng.nextInt(600);
    } else if (t < 60) {
      smoke = 3000 - (t - 50) * 260 + _rng.nextInt(100);
    } else if (t < 66) {
      throw Exception('Dummy sensor offline');
    } else {
      smoke = 350 + _rng.nextInt(150);
    }

    return SensorReading(
      flame: flame,
      smoke: smoke.clamp(0, 4095).toInt(),
      time: DateTime.now(),
    );
  }
}
