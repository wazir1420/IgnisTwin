/// Ek waqt ki sensor reading (flame + smoke)
class SensorReading {
  final bool flame;
  final int smoke; // ESP32 ADC value (0-4095)
  final DateTime time;

  const SensorReading({required this.flame, required this.smoke, required this.time});

  /// ESP32 ka JSON: {"flame":true,"smoke":1234,"smokeAlert":false}
  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
        flame: j['flame'] == true,
        smoke: (j['smoke'] as num).toInt(),
        time: DateTime.now(),
      );
}
