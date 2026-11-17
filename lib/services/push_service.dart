import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM topic — sender (ESP32 ya Mac par chalne wala script) isi topic par
/// message bhejta hai, aur app isi ko subscribe karti hai.
const String kAlertTopic = 'home_alerts';

/// Android channel ki settings ek dafa ban jayein to badli nahi ja saktin, is liye
/// id ke saath version hai. Sound/vibration badalne par id badha dein (v5 -> v6).
const String _channelId = 'ignis_alerts_v4';
const String _channelName = 'Fire alerts';

/// Fixed id — naya alert purane ko replace karta hai. Stack hoti notifications
/// Android ko "noisy" lagti hain aur wo app ka sound mute kar deta hai.
const int _alertNotificationId = 1001;

/// Sender ki taraf se aane wala message jab app band ho.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint('FCM (background): ${message.notification?.title}');
}

/// Notifications: channel + alert sound + FCM receive.
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

  /// Channel + notification permission. Firebase ke bagair bhi chalta hai.
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

  /// Alert ki aawaz app khud bajata hai, is liye OEM ki notification-sound
  /// policies asar nahi karti.
  static Future<void> _playAlertSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/alert.wav'), volume: 1.0);
    } catch (e) {
      debugPrint('Alert sound error: $e');
    }
  }

  /// Alert notification + beep.
  static Future<void> showAlert(String title, String body) async {
    if (!_isAndroid) return;

    // Wahi alert 15 second ke andar dobara na dikhayein (spam guard).
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

  /// FCM receive — app band ho tab bhi push aa sake. Koi sender na ho to
  /// ye quietly kuch nahi karta.
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
