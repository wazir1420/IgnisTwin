import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../core/app_config.dart';
import '../models/sensor_reading.dart';
import 'sensor_service.dart';

class FirebaseSensorService implements SensorService {
  FirebaseSensorService(this.userUid, {required this.onSensorCountChanged}) {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kDatabaseUrl,
    );
    _offsetSub = db.ref('.info/serverTimeOffset').onValue.listen((event) {
      _offsetMs = (event.snapshot.value as num?)?.toInt() ?? 0;
    }, onError: (Object error) => debugPrint('Firebase offset error: $error'));
    _assignmentSub = db
        .ref('users/$userUid/devices')
        .onValue
        .listen(
          (event) => _syncDeviceSubscriptions(db, event.snapshot.value),
          onError: (Object error) {
            _lastError = '$error';
            debugPrint('Firebase user device read error: $error');
            _completeFirstEvent();
          },
        );
  }

  final String userUid;
  final ValueChanged<int> onSensorCountChanged;
  StreamSubscription<DatabaseEvent>? _assignmentSub;
  StreamSubscription<DatabaseEvent>? _offsetSub;
  final Map<String, StreamSubscription<DatabaseEvent>> _deviceSubscriptions =
      {};
  final Map<String, dynamic> _deviceReadings = {};
  final _firstEvent = Completer<void>();

  bool? _flame;
  int _smoke = 0;
  int? _lastSeenMs;
  int _offsetMs = 0;
  String? _lastError;
  int _sensorCount = 0;

  @override
  int get sensorCount => _sensorCount;

  void _completeFirstEvent() {
    if (!_firstEvent.isCompleted) _firstEvent.complete();
  }

  void _syncDeviceSubscriptions(FirebaseDatabase db, dynamic rawAssignments) {
    final assignments = rawAssignments is Map ? rawAssignments : const {};
    final enabledIds = <String>{};
    for (final entry in assignments.entries) {
      if (entry.value is Map && (entry.value as Map)['enabled'] != false) {
        enabledIds.add(entry.key.toString());
      }
    }
    _sensorCount = enabledIds.length * 2;
    onSensorCountChanged(_sensorCount);

    for (final id in _deviceSubscriptions.keys.toList()) {
      if (enabledIds.contains(id)) continue;
      _deviceSubscriptions.remove(id)?.cancel();
      _deviceReadings.remove(id);
    }
    for (final id in enabledIds) {
      if (_deviceSubscriptions.containsKey(id)) continue;
      _deviceSubscriptions[id] = db
          .ref('devices/$id/sensordata')
          .onValue
          .listen(
            (event) {
              _deviceReadings[id] = event.snapshot.value;
              _apply(_deviceReadings);
              if (_flame != null) _completeFirstEvent();
            },
            onError: (Object error) {
              _lastError = '$error';
              debugPrint('Firebase sensor read error for $id: $error');
              _completeFirstEvent();
            },
          );
    }
    _apply(_deviceReadings);
    if (enabledIds.isEmpty || _flame != null) _completeFirstEvent();
  }

  void _apply(Map<String, dynamic> readingsByDevice) {
    Map? latestReadings;
    int latestTimestamp = -1;
    for (final raw in readingsByDevice.values) {
      final readings = _readingsMap(raw);
      if (readings == null ||
          _asBool(_pick(readings, const ['flame', 'flameDetected', 'fire'])) ==
              null) {
        continue;
      }
      final timestamp = _asMillis(
        _pick(readings, const [
          'lastSeen',
          'last_seen',
          'timestamp',
          'updatedAt',
        ]),
      );
      if (latestReadings == null || (timestamp ?? 0) > latestTimestamp) {
        latestReadings = readings;
        latestTimestamp = timestamp ?? 0;
      }
    }

    if (latestReadings == null) {
      _flame = null;
      _smoke = 0;
      _lastSeenMs = null;
      return;
    }
    _flame = _asBool(
      _pick(latestReadings, const ['flame', 'flameDetected', 'fire']),
    );
    _smoke = _asInt(
      _pick(latestReadings, const ['smoke', 'smokeLevel', 'smokeValue']),
    );
    _lastSeenMs = _asMillis(
      _pick(latestReadings, const [
        'lastSeen',
        'last_seen',
        'timestamp',
        'updatedAt',
      ]),
    );
    _lastError = null;
  }

  Map? _readingsMap(dynamic raw) {
    if (raw is! Map) return null;
    if (_pick(raw, const ['flame', 'flameDetected', 'fire']) != null) {
      return raw;
    }

    for (final child in raw.values) {
      if (child is Map &&
          _pick(child, const ['flame', 'flameDetected', 'fire']) != null) {
        return child;
      }
    }
    return null;
  }

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
      return int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.toInt() ?? 0;
    }
    return 0;
  }

  static int? _asMillis(dynamic v) {
    final n = v is num
        ? v.toInt()
        : (v is String ? int.tryParse(v.trim()) : null);
    if (n == null || n <= 0) return null;
    if (n > 100000000000) return n;
    if (n > 1000000000) return n * 1000;
    return null;
  }

  @override
  Future<SensorReading> read() async {
    if (!_firstEvent.isCompleted) {
      await _firstEvent.future.timeout(
        const Duration(seconds: 3),
        onTimeout: _completeFirstEvent,
      );
    }

    final flame = _flame;
    if (flame == null) {
      throw Exception(
        _lastError != null
            ? 'Firebase error: $_lastError'
            : 'Aap ke users/$userUid/devices mein assigned device ki live reading nahi mili. Device ID aur rules check karein.',
      );
    }

    final ls = _lastSeenMs;
    if (ls != null) {
      final serverNow = DateTime.now().millisecondsSinceEpoch + _offsetMs;
      if (serverNow - ls > kStaleAfterMs) {
        throw Exception('The device has not sent a reading recently.');
      }
    }
    return SensorReading(flame: flame, smoke: _smoke, time: DateTime.now());
  }

  @override
  void dispose() {
    _assignmentSub?.cancel();
    _offsetSub?.cancel();
    for (final subscription in _deviceSubscriptions.values) {
      subscription.cancel();
    }
  }
}
