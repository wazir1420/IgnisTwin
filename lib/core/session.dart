import 'package:shared_preferences/shared_preferences.dart';

/// Login yaad rakhne ke liye (phone par dobara login na karna pade).
class Session {
  static const _key = 'logged_in';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_key, true);
    } else {
      await prefs.remove(_key);
    }
  }
}
