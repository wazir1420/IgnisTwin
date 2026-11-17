
class SensorReading {
  final bool flame;
  final int smoke;
  final DateTime time;

  const SensorReading({required this.flame, required this.smoke, required this.time});


  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
        flame: j['flame'] == true,
        smoke: (j['smoke'] as num).toInt(),
        time: DateTime.now(),
      );
}
