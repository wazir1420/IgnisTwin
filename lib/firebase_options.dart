import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'core/app_config.dart';













const String _apiKey = 'AIzaSyABx4zqJNyirhLrgt4HCLq4GTcHJGzTdog';
const String _appId = '1:684858196022:android:f5953b5bf0f06eb0a0d897';
const String _senderId = '684858196022';


const bool kFirebasePlaceholders = _apiKey == 'PASTE_API_KEY_HERE';

class DefaultFirebaseOptions {

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
