import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert_item.dart';
import '../models/data_source.dart';
import '../models/incident.dart';
import '../models/risk_level.dart';
import '../models/sensor_reading.dart';
import '../services/esp32_sensor_service.dart';
import '../services/firebase_sensor_service.dart';
import '../services/sensor_service.dart';

class AppProvider extends ChangeNotifier {
  /// firebaseReady = Firebase.initializeApp kamyab hua ya nahi.
  /// Kamyab na ho to app dummy data nahi dikhati, sensors OFFLINE dikhate hain.
  AppProvider({this.firebaseReady = false}) : source = DataSource.firebase {
    _service = _create(source);
  }

  final bool firebaseReady;

  // ---- data source ----
  late SensorService _service;
  DataSource source;
  String espIp = '192.168.1.50'; // sirf DataSource.esp32 (local WiFi) ke liye
  int smokeThreshold = 1500; // ESP32 ADC (0-4095)

  // ---- manual simulation (slider wali screen) ----
  bool simulation = false;
  bool simFlame = true;
  int simSmoke = 2000;

  // ---- latest sensor data ----
  bool online = false;
  bool liveFlame = false;
  int liveSmoke = 0;
  DateTime? lastUpdate;
  /// Aakhri failure ki wajah (sensors screen par dikhti hai) — masla debug karne ke liye
  String? lastError;
  int _fails = 0;
  bool _busy = false;
  bool _offlineAlerted = false;

  // ---- history ----
  final List<AlertItem> alerts = [];
  final List<Incident> incidents = [];
  Incident? active;
  RiskLevel _prev = RiskLevel.normal;
  int _counter = 140;
  Timer? _timer;

  // ---- bottom navigation ----
  int tab = 0;
  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  // ---- derived values ----
  bool get flame => simulation ? simFlame : liveFlame;
  int get smoke => simulation ? simSmoke : liveSmoke;
  bool get sensorsOnline => simulation || online;
  int get onlineCount => sensorsOnline ? 2 : 0;

  /// Fire probability (0..1): flame 60% + smoke 40%
  double get risk {
    final s = (smoke / smokeThreshold).clamp(0.0, 1.0).toDouble();
    return (flame ? 0.6 : 0.0) + 0.4 * s;
  }

  RiskLevel get level {
    if (!sensorsOnline) return RiskLevel.unknown;
    if (risk >= 0.6) return RiskLevel.critical;
    if (risk >= 0.3) return RiskLevel.warning;
    return RiskLevel.normal;
  }

  int get unreadCount => alerts.where((a) => !a.read).length;

  // ---- lifecycle ----
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

  // ---- settings ----
  SensorService _create(DataSource s) => switch (s) {
    DataSource.firebase =>
      firebaseReady ? FirebaseSensorService() : _UnavailableService(),
    DataSource.esp32 => Esp32SensorService(espIp),
  };

  void setSource(DataSource s) {
    if (s == source) return;
    _service.dispose();
    source = s;
    _service = _create(s);
    online = false;
    _fails = 0;
    _offlineAlerted = false;
    notifyListeners();
  }

  void saveSettings(String ip, int thr) {
    espIp = ip.trim();
    smokeThreshold = thr;
    if (source == DataSource.esp32) {
      _service.dispose();
      _service = Esp32SensorService(espIp);
    }
    notifyListeners();
  }

  // ---- polling ----
  Future<void> _poll() async {
    if (_busy) return;
    _busy = true;
    if (!simulation) {
      try {
        final r = await _service.read();
        liveFlame = r.flame;
        liveSmoke = r.smoke;
        online = true;
        _fails = 0;
        _offlineAlerted = false;
        lastUpdate = r.time;
        lastError = null;
      } catch (e) {
        lastError = '$e';
        _fails++;
        if (_fails >= 2) online = false;
      }
    } else {
      lastUpdate = DateTime.now();
    }
    _busy = false;
    _evaluate();
  }

  void _evaluate() {
    final l = level;

    if (!sensorsOnline) {
      if (!_offlineAlerted) {
        _offlineAlerted = true;
        _addAlert(
          RiskLevel.unknown,
          'Sensors offline',
          'Laboratory 03 · Health check failed',
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
          TimelineEntry('Fire probability reached ${(risk * 100).round()}%'),
        );
        inc.timeline.add(TimelineEntry('Incident ${inc.id} generated'));
        if (flame) inc.timeline.add(TimelineEntry('Flame detected'));
        incidents.insert(0, inc);
        active = inc;
        _addAlert(
          RiskLevel.critical,
          'Fire alert — Laboratory 03',
          flame
              ? 'Ground Floor · Flame confirmed'
              : 'Ground Floor · High smoke level',
        );
      } else if (l == RiskLevel.warning && _prev == RiskLevel.normal) {
        _addAlert(
          RiskLevel.warning,
          'Smoke rising — Laboratory 03',
          'Ground Floor · Smoke $smoke',
        );
      } else if (l == RiskLevel.normal && active != null) {
        final inc = active!;
        inc.end = DateTime.now();
        inc.timeline.add(TimelineEntry('Conditions returned to normal'));
        _addAlert(
          RiskLevel.normal,
          'Incident ${inc.id} closed',
          'Laboratory 03 · ${inc.acknowledged ? "Acknowledged" : "Auto-resolved"}',
          resolved: true,
        );
        active = null;
      }
      _prev = l;
    }
    notifyListeners();
  }

  void _addAlert(RiskLevel l, String t, String s, {bool resolved = false}) {
    alerts.insert(
      0,
      AlertItem(l, simulation ? '[SIM] $t' : t, s, resolved: resolved),
    );
  }

  // ---- actions ----
  void acknowledge() {
    final inc = active;
    if (inc == null || inc.acknowledged) return;
    inc.acknowledged = true;
    inc.timeline.add(TimelineEntry('Incident acknowledged'));
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

/// Firebase start nahi hua to ye service sirf error deti hai (app OFFLINE dikhati hai)
class _UnavailableService implements SensorService {
  @override
  Future<SensorReading> read() async =>
      throw Exception(
        'Firebase initialize nahi hua (lib/firebase_options.dart bharein)',
      );

  @override
  void dispose() {}
}
