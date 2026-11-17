import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';



const String kAlertTopic = 'home_alerts';



const String _channelId = 'ignis_alerts_v4';
const String _channelName = 'Fire alerts';



const int _alertNotificationId = 1001;


@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint('FCM (background): ${message.notification?.title}');
}


class PushService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _player = AudioPlayer();

  static bool _localReady = false;
  static bool _fcmStarted = false;

  static String? _lastTitle;
  static String? _lastBody;
  static DateTime? _lastShownAt;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;


  static Future<void> initLocal() async {
    if (_localReady || !_isAndroid) return;
    _localReady = true;

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Flame aur smoke alerts aap ke ghar se',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ignis_alert'),
        audioAttributesUsage: AudioAttributesUsage.notification,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 600, 300, 600]),
        showBadge: true,
      ),
    );

    await android?.requestNotificationsPermission();
  }



  static Future<void> _playAlertSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/alert.wav'), volume: 1.0);
    } catch (e) {
      debugPrint('Alert sound error: $e');
    }
  }


  static Future<void> showAlert(String title, String body) async {
    if (!_isAndroid) return;


    final now = DateTime.now();
    if (title == _lastTitle &&
        body == _lastBody &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < const Duration(seconds: 15)) {
      return;
    }
    _lastTitle = title;
    _lastBody = body;
    _lastShownAt = now;

    _playAlertSound();

    try {
      await initLocal();
      await _local.show(
        id: _alertNotificationId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Local notification error: $e');
    }
  }



  static Future<void> initFcm() async {
    if (_fcmStarted) return;
    _fcmStarted = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    await messaging.subscribeToTopic(kAlertTopic);
    await messaging.register();
  }
}
