import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../core/app_config.dart';
import '../models/sensor_reading.dart';
import 'sensor_service.dart';

/// ESP32 -> Firebase Realtime Database (/sensors) -> yeh service -> app
///
/// Database mein ye data hona chahiye:
///   `sensors: { flame: true/false, smoke: 0-4095, lastSeen: <server timestamp ms> }`
///
/// Parsing flexible hai: flame 0/1 ya "true"/"false" bhi chalega, smoke string
/// bhi chalega, aur lastSeen seconds mein ho to bhi theek.
///
/// Firebase ka listener (onValue) real time mein naya data khud push karta hai.
/// Provider har second read() bulata hai aur yahan se latest value mil jati hai.
class FirebaseSensorService implements SensorService {
  StreamSubscription<DatabaseEvent>? _dataSub;
  StreamSubscription<DatabaseEvent>? _offsetSub;
  final _firstEvent = Completer<void>();

  bool? _flame;
  int _smoke = 0;
  int? _lastSeenMs; // ESP32 ne data kab bheja (server time)
  int _offsetMs = 0; // phone ki clock aur Firebase server ki clock ka farq
  String? _lastError;

  FirebaseSensorService() {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kDatabaseUrl,
    );

    _offsetSub = db.ref('.info/serverTimeOffset').onValue.listen((e) {
      _offsetMs = (e.snapshot.value as num?)?.toInt() ?? 0;
    }, onError: (e) => debugPrint('Firebase offset error: $e'));

    _dataSub = db
        .ref('sensors')
        .onValue
        .listen(
          (event) {
            _apply(event.snapshot.value);
            if (!_firstEvent.isCompleted) _firstEvent.complete();
          },
          onError: (e) {
            // Aksar yahan "permission-denied" aata hai (Rules ka masla)
            _lastError = '$e';
            debugPrint('Firebase read error: $e');
            if (!_firstEvent.isCompleted) _firstEvent.complete();
          },
        );
  }

  /// /sensors ka raw value -> flame + smoke + lastSeen.
  /// Agar data `/sensors/<device>/...` jaisa nested ho to pehla device utha lete hain.
  void _apply(dynamic raw) {
    final map = _readingsMap(raw);
    if (map == null) return;

    final flame = _asBool(_pick(map, const ['flame', 'flameDetected', 'fire']));
    if (flame == null) return; // flame field hi nahi mila

    _flame = flame;
    _smoke = _asInt(_pick(map, const ['smoke', 'smokeLevel', 'smokeValue']));
    _lastSeenMs = _asMillis(
      _pick(map, const ['lastSeen', 'last_seen', 'timestamp', 'updatedAt']),
    );
    _lastError = null;
  }

  Map? _readingsMap(dynamic raw) {
    if (raw is! Map) return null;
    if (_pick(raw, const ['flame', 'flameDetected', 'fire']) != null) return raw;
    // Nested (per-device) structure: pehla child jo reading rakhta ho
    for (final child in raw.values) {
      if (child is Map &&
          _pick(child, const ['flame', 'flameDetected', 'fire']) != null) {
        return child;
      }
    }
    return null;
  }

  /// Case-insensitive key lookup (ESP32 code mein "Flame" / "flame" dono ho sakta hai).
  static dynamic _pick(Map map, List<String> names) {
    for (final n in names) {
      if (map.containsKey(n)) return map[n];
    }
    for (final entry in map.entries) {
      final k = '${entry.key}'.toLowerCase();
      if (names.any((n) => n.toLowerCase() == k)) return entry.value;
    }
    return null;
  }

  static bool? _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      switch (v.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
        case 'detected':
        case 'high':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'clear':
        case 'low':
          return false;
      }
    }
    return null;
  }

  static int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) {
      return int.tryParse(v.trim()) ??
          double.tryParse(v.trim())?.toInt() ??
          0;
    }
    return 0;
  }

  /// lastSeen seconds mein bhi bheja gaya ho to ms mein badal dete hain.
  static int? _asMillis(dynamic v) {
    final n = v is num
        ? v.toInt()
        : (v is String ? int.tryParse(v.trim()) : null);
    if (n == null || n <= 0) return null;
    if (n > 100000000000) return n; // already milliseconds
    if (n > 1000000000) return n * 1000; // seconds
    return null; // kuch samajh nahi aaya
  }

  @override
  Future<SensorReading> read() async {
    // Pehla jawab aane tak thora intezar (max 3 second), phir hi offline maanein
    if (!_firstEvent.isCompleted) {
      await _firstEvent.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    }

    final flame = _flame;
    if (flame == null) {
      throw Exception(
        _lastError != null
            ? 'Firebase error: $_lastError'
            : 'Firebase ke /sensors mein data nahi hai (URL, Rules ya ESP32 check karein)',
      );
    }

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
