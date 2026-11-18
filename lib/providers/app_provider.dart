import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/home_config.dart';
import '../models/alert_item.dart';
import '../models/data_source.dart';
import '../models/incident.dart';
import '../models/risk_level.dart';
import '../models/sensor_reading.dart';
import '../services/esp32_sensor_service.dart';
import '../services/firebase_sensor_service.dart';
import '../services/push_service.dart';
import '../services/sensor_service.dart';

class AppProvider extends ChangeNotifier {
  static const _offlineAlertFailureThreshold = 10;

  static const _smokeWarmupDuration = Duration(seconds: 60);

  AppProvider({this.firebaseReady = false}) : source = DataSource.firebase {
    _service = _create(source);
  }

  final bool firebaseReady;

  late SensorService _service;
  DataSource source;
  String espIp = '192.168.1.50';
  int smokeThreshold = 1500;
  int _assignedSensorCount = 0;

  bool simulation = false;
  bool simFlame = true;
  int simSmoke = 2000;

  bool online = false;
  bool liveFlame = false;
  int liveSmoke = 0;
  bool? _sensorSmokeReady;
  DateTime? _smokeWarmupUntil;
  DateTime? lastUpdate;

  String? lastError;
  int _fails = 0;
  bool _busy = false;
  bool _offlineAlerted = false;

  String currentUserRole = 'user';
  String currentUserName = 'Operator';
  String currentUserEmail = '';
  String currentUserPhone = '';
  String currentUserPhotoBase64 = '';
  String currentUserId = '';

  bool get isAdmin => currentUserRole == 'admin';
  bool get canRespond =>
      currentUserRole == 'admin' || currentUserRole == 'user';

  void setCurrentUser({
    required String role,
    required String name,
    required String email,
    String uid = '',
    String phone = '',
    String photoBase64 = '',
  }) {
    final userChanged = currentUserId != uid;
    currentUserRole = role;
    currentUserName = name;
    currentUserEmail = email;
    currentUserPhone = phone;
    currentUserPhotoBase64 = photoBase64;
    currentUserId = uid;
    if (userChanged && source == DataSource.firebase) {
      tab = 0;
      _service.dispose();
      _assignedSensorCount = 0;
      _service = _create(source);
      online = false;
      _sensorSmokeReady = null;
      _smokeWarmupUntil = null;
      _fails = 0;
      lastError = null;
    }
    notifyListeners();
  }

  void updateCurrentUserProfile({
    required String name,
    required String phone,
    required String photoBase64,
  }) {
    currentUserName = name;
    currentUserPhone = phone;
    currentUserPhotoBase64 = photoBase64;
    notifyListeners();
  }

  final List<AlertItem> alerts = [];
  final List<Incident> incidents = [];
  Incident? active;
  RiskLevel _prev = RiskLevel.normal;
  int _counter = 140;
  Timer? _timer;

  int tab = 0;
  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  bool get flame => simulation ? simFlame : liveFlame;
  int get smoke => simulation ? simSmoke : liveSmoke;
  bool get sensorsOnline => simulation || online;
  bool get smokeWarmingUp =>
      !simulation &&
      online &&
      (_sensorSmokeReady == false ||
          (_sensorSmokeReady == null &&
              _smokeWarmupUntil != null &&
              DateTime.now().isBefore(_smokeWarmupUntil!)));
  int get totalSensorCount => simulation
      ? 2
      : source == DataSource.firebase
      ? _assignedSensorCount
      : 2;
  int get onlineCount => sensorsOnline ? totalSensorCount : 0;
  int get offlineCount => totalSensorCount - onlineCount;

  double get risk {
    final reading = smokeWarmingUp ? 0 : smoke;
    final s = (reading / smokeThreshold).clamp(0.0, 1.0).toDouble();
    return (flame ? 0.6 : 0.0) + 0.4 * s;
  }

  RiskLevel get level {
    if (!sensorsOnline) return RiskLevel.unknown;
    if (risk >= 0.6) return RiskLevel.critical;
    if (!smokeWarmingUp && smoke >= smokeThreshold) return RiskLevel.warning;
    return RiskLevel.normal;
  }

  int get unreadCount => alerts.where((a) => !a.read).length;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
    _poll();
  }

  void stop() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    _service.dispose();
    super.dispose();
  }

  SensorService _create(DataSource s) => switch (s) {
    DataSource.firebase =>
      firebaseReady && currentUserId.isNotEmpty
          ? FirebaseSensorService(
              currentUserId,
              onSensorCountChanged: (count) {
                _assignedSensorCount = count;
                notifyListeners();
              },
            )
          : _UnavailableService(),
    DataSource.esp32 => Esp32SensorService(espIp),
  };

  void setSource(DataSource s) {
    if (s == source) return;
    _service.dispose();
    source = s;
    _service = _create(s);
    online = false;
    _sensorSmokeReady = null;
    _smokeWarmupUntil = null;
    _fails = 0;
    _offlineAlerted = false;
    notifyListeners();
  }

  void saveSettings(String ip, int thr) {
    final normalizedIp = ip.trim();
    final ipChanged = normalizedIp != espIp;
    espIp = normalizedIp;
    smokeThreshold = thr;
    if (source == DataSource.esp32 && ipChanged) {
      _service.dispose();
      _service = Esp32SensorService(espIp);
      online = false;
      _sensorSmokeReady = null;
      _smokeWarmupUntil = null;
      _fails = 0;
    }
    notifyListeners();
  }

  Future<void> _poll() async {
    if (_busy) return;
    _busy = true;
    if (!simulation) {
      try {
        final r = await _service.read();
        if (r.isStale) {
          lastError = 'The device has not sent a reading recently.';
          _fails++;
          online = false;
          _sensorSmokeReady = null;
          _smokeWarmupUntil = null;
        } else {
          if (!online && r.smokeReady == null) {
            _smokeWarmupUntil = DateTime.now().add(_smokeWarmupDuration);
          }
          liveFlame = r.flame;
          liveSmoke = r.smoke;
          _sensorSmokeReady = r.smokeReady;
          online = true;
          _fails = 0;
          _offlineAlerted = false;
          lastUpdate = r.time;
          lastError = null;
        }
      } catch (e) {
        lastError = '$e';
        _fails++;
        if (_fails >= 2) {
          online = false;
          _sensorSmokeReady = null;
          _smokeWarmupUntil = null;
        }
      }
    } else {
      lastUpdate = DateTime.now();
    }
    _busy = false;
    _evaluate();
  }

  void _evaluate() {
    if (totalSensorCount == 0) {
      _offlineAlerted = false;
      _fails = 0;
      lastError = null;
      _prev = RiskLevel.unknown;
      notifyListeners();
      return;
    }

    final l = level;

    if (!sensorsOnline) {
      if (_fails >= _offlineAlertFailureThreshold && !_offlineAlerted) {
        _offlineAlerted = true;
        _addAlert(
          RiskLevel.unknown,
          'Safety device has lost connection',
          'Check power and Wi-Fi for $kMonitoredRoom.',
        );
      }
    } else {
      if (l == RiskLevel.critical &&
          _prev != RiskLevel.critical &&
          active == null) {
        _counter++;
        final inc = Incident(
          simulation ? 'SIM-$_counter' : 'INC-2026-0$_counter',
          simulation,
        );
        inc.timeline.add(
          TimelineEntry('Estimated fire risk reached ${(risk * 100).round()}%'),
        );
        inc.timeline.add(TimelineEntry('Alert started'));
        if (flame) inc.timeline.add(TimelineEntry('Fire signs detected'));
        incidents.insert(0, inc);
        active = inc;
        _addAlert(
          RiskLevel.critical,
          'Possible fire danger — $kMonitoredRoom',
          flame ? 'Fire signs detected' : 'Smoke level is high',
        );
      } else if (l == RiskLevel.warning && _prev == RiskLevel.normal) {
        _addAlert(
          RiskLevel.warning,
          'Smoke level is rising — $kMonitoredRoom',
          'Check the air in $kMonitoredRoom.',
        );
      } else if (l == RiskLevel.normal && active != null) {
        final inc = active!;
        inc.end = DateTime.now();
        inc.timeline.add(TimelineEntry('Conditions returned to normal'));
        _addAlert(
          RiskLevel.normal,
          'Conditions are back to normal',
          '$kMonitoredRoom · Alert closed',
          resolved: true,
        );
        active = null;
      }
      _prev = l;
    }
    notifyListeners();
  }

  void _addAlert(RiskLevel l, String t, String s, {bool resolved = false}) {
    PushService.showAlert(t, s);
    alerts.insert(
      0,
      AlertItem(l, simulation ? '[TEST] $t' : t, s, resolved: resolved),
    );
  }

  void acknowledge() {
    final inc = active;
    if (inc == null || inc.acknowledged) return;
    inc.acknowledged = true;
    inc.timeline.add(TimelineEntry('Alert acknowledged'));
    notifyListeners();
  }

  void markAllRead() {
    for (final a in alerts) {
      a.read = true;
    }
    notifyListeners();
  }

  void markRead(AlertItem a) {
    a.read = true;
    notifyListeners();
  }

  void setSimulation(bool on) {
    if (simulation == on) return;
    simulation = on;
    if (active != null) {
      active!.end = DateTime.now();
      active = null;
    }
    _prev = RiskLevel.normal;
    _offlineAlerted = false;
    _evaluate();
  }

  void updateSim({bool? f, int? s}) {
    if (f != null) simFlame = f;
    if (s != null) simSmoke = s;
    if (simulation) {
      _evaluate();
    } else {
      notifyListeners();
    }
  }
}

class _UnavailableService implements SensorService {
  @override
  int get sensorCount => 0;

  @override
  Future<SensorReading> read() async => throw Exception(
    'Firebase initialize nahi hua (lib/firebase_options.dart bharein)',
  );

  @override
  void dispose() {}
}
