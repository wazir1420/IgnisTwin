import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/app_config.dart';

class AuthAccessException implements Exception {
  const AuthAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: kDatabaseUrl,
  );

  User? get currentUser => _auth.currentUser;

  DatabaseReference get _users => _database.ref('users');
  DatabaseReference get _devices => _database.ref('devices');

  Stream<Map<String, int>> watchDeviceLastSeen() {
    late final StreamController<Map<String, int>> controller;
    StreamSubscription<DatabaseEvent>? devicesSubscription;
    final readingSubscriptions = <String, StreamSubscription<DatabaseEvent>>{};
    final lastSeen = <String, int>{};

    Future<void> start() async {
      devicesSubscription = _devices.onValue.listen((event) {
        final value = event.snapshot.value;
        final deviceIds = value is Map
            ? value.keys.map((key) => key.toString()).toSet()
            : <String>{};

        for (final id in readingSubscriptions.keys.toList()) {
          if (deviceIds.contains(id)) continue;
          readingSubscriptions.remove(id)?.cancel();
          lastSeen.remove(id);
        }

        if (value is Map) {
          for (final entry in value.entries) {
            final id = entry.key.toString();
            if (entry.value is! Map || readingSubscriptions.containsKey(id)) {
              continue;
            }
            var firstSnapshot = true;
            readingSubscriptions[id] = _devices
                .child(id)
                .child('sensordata')
                .onValue
                .listen((readingEvent) {
                  final readings = readingEvent.snapshot.value;
                  if (readings is Map) {
                    final timestamp = _lastSeenMillis(readings);
                    final now = DateTime.now().millisecondsSinceEpoch;
                    lastSeen[id] = firstSnapshot && timestamp != null
                        ? (timestamp > now ? now : timestamp)
                        : now;
                  } else {
                    lastSeen.remove(id);
                  }
                  firstSnapshot = false;
                  controller.add(Map<String, int>.unmodifiable(lastSeen));
                }, onError: controller.addError);
          }
        }
        controller.add(Map<String, int>.unmodifiable(lastSeen));
      }, onError: controller.addError);
    }

    Future<void> stop() async {
      await devicesSubscription?.cancel();
      await Future.wait(readingSubscriptions.values.map((sub) => sub.cancel()));
      readingSubscriptions.clear();
    }

    controller = StreamController<Map<String, int>>(
      onListen: start,
      onCancel: stop,
    );
    return controller.stream;
  }

  int? _lastSeenMillis(Map value) {
    for (final key in const [
      'lastSeen',
      'last_seen',
      'timestamp',
      'updatedAt',
    ]) {
      final raw = value[key];
      final timestamp = raw is num
          ? raw.toInt()
          : raw is String
          ? int.tryParse(raw)
          : null;
      if (timestamp == null || timestamp <= 0) continue;
      if (timestamp > 100000000000) return timestamp;
      if (timestamp > 1000000000) return timestamp * 1000;
    }
    return null;
  }

  Future<void> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AuthAccessException(
        'Firebase did not return a user account.',
      );
    }

    try {
      await _users.child(user.uid).set({
        'name': name.trim(),
        'email': user.email ?? email.trim().toLowerCase(),
        'role': 'user',
        'accessStatus': 'pending',
      });
    } finally {
      await _auth.signOut();
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AuthAccessException(
        'Firebase did not return a user account.',
      );
    }

    try {
      final profile = await getProfile(user.uid);
      if (profile == null) {
        throw const AuthAccessException(
          'Your Realtime Database profile is missing. Contact the administrator.',
        );
      }
      final role = profile['role']?.toString();
      if (role != 'admin' && role != 'user') {
        throw const AuthAccessException(
          'Profile role must be either admin or user. Contact the administrator.',
        );
      }
      if (role != 'admin' && profile['accessStatus'] != 'approved') {
        throw const AuthAccessException(
          'Your account is waiting for administrator approval.',
        );
      }

      return {
        ...profile,
        'uid': user.uid,
        'email': user.email ?? email.trim().toLowerCase(),
      };
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    final current = _auth.currentUser;
    if (current == null) return null;

    try {
      final profile = await getProfile(current.uid);
      final role = profile?['role']?.toString();
      if (profile == null ||
          (role != 'admin' && role != 'user') ||
          (role != 'admin' && profile['accessStatus'] != 'approved')) {
        await _auth.signOut();
        return null;
      }
      return {...profile, 'uid': current.uid, 'email': current.email ?? ''};
    } on FirebaseException {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snapshot = await _users.child(uid).get();
    final value = snapshot.value;
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  Future<void> updateOwnProfile({
    required String name,
    required String phone,
    required String photoBase64,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthAccessException('Sign in before updating your profile.');
    }

    final profile = _users.child(user.uid);
    try {
      await Future.wait([
        profile.child('name').set(name.trim()),
        profile.child('phone').set(phone.trim()),
        profile.child('photoBase64').set(photoBase64),
      ]);
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const AuthAccessException(
          'Firebase rejected the profile update. Publish the latest '
          'database.rules.json rules, then try again.',
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final snapshot = await _users.get();
    final value = snapshot.value;
    if (value is! Map) return const [];
    final users = <Map<String, dynamic>>[];
    for (final entry in value.entries) {
      if (entry.value is Map) {
        users.add({
          'id': entry.key.toString(),
          ...Map<String, dynamic>.from(entry.value as Map),
        });
      }
    }
    users.sort(
      (a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()),
    );
    return users;
  }

  Future<List<Map<String, dynamic>>> fetchDevices() async {
    final snapshot = await _users.get();
    final value = snapshot.value;
    if (value is! Map) return const [];
    final devices = <Map<String, dynamic>>[];
    for (final userEntry in value.entries) {
      final profile = userEntry.value;
      final userDevices = profile is Map ? profile['devices'] : null;
      if (userDevices is! Map) continue;
      for (final deviceEntry in userDevices.entries) {
        if (deviceEntry.value is Map) {
          devices.add({
            'id': deviceEntry.key.toString(),
            'ownerUid': userEntry.key.toString(),
            ...Map<String, dynamic>.from(deviceEntry.value as Map),
          });
        }
      }
    }
    devices.sort(
      (a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()),
    );
    return devices;
  }

  Future<List<String>> fetchUnassignedLiveDeviceIds() async {
    final results = await Future.wait([_users.get(), _devices.get()]);
    final usersValue = results[0].value;
    final devicesValue = results[1].value;
    if (devicesValue is! Map) return const [];

    final assignedIds = <String>{};
    if (usersValue is Map) {
      for (final profile in usersValue.values) {
        final userDevices = profile is Map ? profile['devices'] : null;
        if (userDevices is Map) {
          assignedIds.addAll(userDevices.keys.map((key) => key.toString()));
        }
      }
    }

    final ids = <String>[];
    for (final entry in devicesValue.entries) {
      final device = entry.value;
      if (device is Map &&
          device['sensordata'] is Map &&
          !assignedIds.contains(entry.key.toString())) {
        ids.add(entry.key.toString());
      }
    }
    ids.sort();
    return ids;
  }

  Future<void> updateUserRole(String userId, String role) async {
    if (role != 'admin' && role != 'user') {
      throw ArgumentError.value(role, 'role', 'Role must be admin or user.');
    }
    await _users.child(userId).child('role').set(role);
  }

  Future<void> updateUserAccessStatus(String userId, String status) async {
    if (status != 'pending' && status != 'approved') {
      throw ArgumentError.value(
        status,
        'status',
        'Access status must be pending or approved.',
      );
    }
    await _users.child(userId).child('accessStatus').set(status);
  }

  Future<void> removeUserProfile(String userId) async {
    if (userId == currentUser?.uid) {
      throw StateError('You cannot remove your own administrator profile.');
    }
    final snapshot = await _users.child(userId).get();
    final profile = snapshot.value;
    if (profile is! Map) {
      throw StateError('User profile $userId was not found.');
    }
    if (profile['role'] == 'admin') {
      final users = await fetchUsers();
      if (users.where((user) => user['role'] == 'admin').length <= 1) {
        throw StateError('Keep at least one administrator account.');
      }
    }

    final updates = <String, Object?>{'users/$userId': null};
    final devices = profile['devices'];
    if (devices is Map) {
      for (final entry in devices.entries) {
        final deviceId = entry.key.toString();
        updates['devices/$deviceId/ownerUid'] = null;
      }
    }
    await _database.ref().update(updates);
  }

  Future<String> createDevice({
    required String deviceId,
    required String name,
    required String zone,
    required String ownerUid,
  }) async {
    final id = deviceId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Device ID is required.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Device name is required.');
    }
    final liveDevice = await _devices.child(id).child('sensordata').get();
    if (!liveDevice.exists) {
      throw StateError('No live readings found for device $id.');
    }
    final ownerDevices = _users.child(ownerUid).child('devices');
    final ref = ownerDevices.child(id);
    if ((await ref.get()).exists) {
      throw StateError('A device with ID $id is already registered.');
    }

    final oldOwnerUid = (await _devices.child(id).child('ownerUid').get()).value
        ?.toString();
    if (oldOwnerUid != null && oldOwnerUid != ownerUid) {
      final oldAssignment = await _users
          .child(oldOwnerUid)
          .child('devices')
          .child(id)
          .get();
      if (oldAssignment.exists) {
        throw StateError('Device $id is already assigned to another user.');
      }
    }

    final updates = <String, Object?>{
      'users/$ownerUid/devices/$id': {
        'name': name.trim(),
        'zone': zone.trim(),
        'enabled': true,
      },
      'devices/$id/ownerUid': ownerUid,
    };
    if (oldOwnerUid != null && oldOwnerUid != ownerUid) {
      updates['users/$oldOwnerUid/devices/$id'] = null;
    }
    await _database.ref().update(updates);
    return id;
  }

  Future<void> updateDeviceEnabled(
    String ownerUid,
    String deviceId,
    bool enabled,
  ) async {
    await _users
        .child(ownerUid)
        .child('devices')
        .child(deviceId)
        .child('enabled')
        .set(enabled);
  }

  Future<void> assignDevice({
    required String deviceId,
    required String? currentOwnerUid,
    required String newOwnerUid,
    required String name,
    required String zone,
  }) async {
    final id = deviceId.trim();
    if (!(await _devices.child(id).child('sensordata').get()).exists) {
      throw StateError('No live readings found for device $id.');
    }
    final updates = <String, Object?>{};
    if (currentOwnerUid != null && currentOwnerUid != newOwnerUid) {
      updates['users/$currentOwnerUid/devices/$id'] = null;
    }
    updates['users/$newOwnerUid/devices/$id'] = {
      'name': name.trim(),
      'zone': zone.trim(),
      'enabled': true,
    };
    updates['devices/$id/ownerUid'] = newOwnerUid;
    await _database.ref().update(updates);
  }

  Future<void> removeDevice({
    required String ownerUid,
    required String deviceId,
  }) async {
    final id = deviceId.trim();
    final updates = <String, Object?>{
      'users/$ownerUid/devices/$id': null,
      'devices/$id': null,
    };
    await _database.ref().update(updates);
  }
}
