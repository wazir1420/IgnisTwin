import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'core/app_config.dart';

/// ⚠️ SIRF YAHAN 3 VALUES BHAREIN (baqi sab automatic hai).
///
/// Ye values Firebase console se milegi: Project settings (~ gear icon) ->
/// Your apps -> Android app (ya jis platform par chalayenge) ->
/// "google-services.json" / "firebaseConfig" section.
///
///   apiKey            -> "current_key" / apiKey
///   appId             -> "mobilesdk_app_id" / appId (1:1234...:android:abcd)
///   messagingSenderId -> "project_number" / messagingSenderId
///
/// Note: ye Firebase client config hai, secret nahi. Realtime Database ka
/// access Security Rules control karte hain, ye values nahi.
const String _apiKey = 'AIzaSyABx4zqJNyirhLrgt4HCLq4GTcHJGzTdog';
const String _appId = '1:684858196022:android:f5953b5bf0f06eb0a0d897';
const String _senderId = '684858196022';

/// True jab tak upar wali values bhari nahi jati.
const bool kFirebasePlaceholders = _apiKey == 'PASTE_API_KEY_HERE';

class DefaultFirebaseOptions {
  /// Bina values bhare app ko connect karne ki koshish hi nahi karni.
  static bool get isConfigured => !kFirebasePlaceholders;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => macos,
      TargetPlatform.windows => windows,
      _ => android,
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: kFirebaseProjectId,
    databaseURL: kDatabaseUrl,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: kFirebaseProjectId,
    databaseURL: kDatabaseUrl,
    iosBundleId: 'com.example.ignistwin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: kFirebaseProjectId,
    databaseURL: kDatabaseUrl,
    iosBundleId: 'com.example.ignistwin',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: kFirebaseProjectId,
    authDomain: '$kFirebaseProjectId.firebaseapp.com',
    databaseURL: kDatabaseUrl,
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: kFirebaseProjectId,
    databaseURL: kDatabaseUrl,
  );
}
