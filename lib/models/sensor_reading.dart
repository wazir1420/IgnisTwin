
class SensorReading {
  final bool flame;
  final int smoke;
  final DateTime time;
  final bool? smokeReady;
  final bool isStale;

  const SensorReading({
    required this.flame,
    required this.smoke,
    required this.time,
    this.smokeReady,
    this.isStale = false,
  });


  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
        flame: j['flame'] == true,
        smoke: (j['smoke'] as num).toInt(),
        time: DateTime.now(),
        smokeReady: j['smokeReady'] == true
            ? true
            : j['smokeReady'] == false
            ? false
            : null,
      );
}
