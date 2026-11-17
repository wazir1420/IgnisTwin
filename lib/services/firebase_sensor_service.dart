import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/app_config.dart';
import '../models/sensor_reading.dart';
import 'sensor_service.dart';

/// ESP32 -> Firebase Realtime Database (/sensors) -> yeh service -> app
///
/// Database mein ye data hona chahiye:
///   sensors: { flame: true/false, smoke: 0-4095, lastSeen: server timestamp ms }
///
/// Firebase ka listener (onValue) real time mein naya data khud push karta hai.
/// Provider har second read() bulata hai aur yahan se latest value mil jati hai.
class FirebaseSensorService implements SensorService {
  StreamSubscription<DatabaseEvent>? _dataSub;
  StreamSubscription<DatabaseEvent>? _offsetSub;

  bool? _flame;
  int _smoke = 0;
  int? _lastSeenMs; // ESP32 ne data kab bheja (server time)
  int _offsetMs = 0; // phone ki clock aur Firebase server ki clock ka farq

  FirebaseSensorService() {
    final db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: kDatabaseUrl);

    _offsetSub = db.ref('.info/serverTimeOffset').onValue.listen((e) {
      _offsetMs = (e.snapshot.value as num?)?.toInt() ?? 0;
    }, onError: (_) {});

    _dataSub = db.ref('sensors').onValue.listen((event) {
      final v = event.snapshot.value;
      if (v is Map) {
        _flame = v['flame'] == true;
        _smoke = (v['smoke'] as num?)?.toInt() ?? 0;
        final ls = v['lastSeen'];
        _lastSeenMs = ls is num ? ls.toInt() : null;
      }
    }, onError: (_) {});
  }

  @override
  Future<SensorReading> read() async {
    final flame = _flame;
    if (flame == null) throw Exception('Firebase se abhi tak data nahi aaya');

    final ls = _lastSeenMs;
    if (ls != null) {
      final serverNow = DateTime.now().millisecondsSinceEpoch + _offsetMs;
      if (serverNow - ls > kStaleAfterMs) {
        throw Exception('ESP32 ne kaafi der se data nahi bheja (offline)');
      }
    }
    return SensorReading(flame: flame, smoke: _smoke, time: DateTime.now());
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _offsetSub?.cancel();
  }
}
