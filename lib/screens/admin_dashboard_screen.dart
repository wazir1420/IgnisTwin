import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_config.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_card.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_DashboardData> _data;
  StreamSubscription<Map<String, int>>? _sensorSubscription;
  Timer? _statusRefreshTimer;
  Map<String, int> _sensorLastSeen = const {};
  final Set<String> _knownLiveDeviceIds = {};

  @override
  void initState() {
    super.initState();
    _data = _loadData();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
    _sensorSubscription = AuthService.instance.watchDeviceLastSeen().listen(
      (lastSeen) {
        if (!mounted) return;
        final newDeviceIds = lastSeen.keys
            .where((id) => !_knownLiveDeviceIds.contains(id))
            .toList();
        _knownLiveDeviceIds.addAll(newDeviceIds);
        setState(() {
          _sensorLastSeen = lastSeen;
        });
        if (newDeviceIds.isNotEmpty) _refresh();
      },
      onError: (Object error) {
        debugPrint('Admin dashboard sensor status error: $error');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read sensor status: $error')),
        );
      },
    );
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  Future<_DashboardData> _loadData() async {
    final results = await Future.wait<Object>([
      AuthService.instance.fetchUsers(),
      AuthService.instance.fetchDevices(),
      AuthService.instance.fetchUnassignedLiveDeviceIds(),
    ]);
    return _DashboardData(
      users: results[0] as List<Map<String, dynamic>>,
      devices: results[1] as List<Map<String, dynamic>>,
      unassignedDeviceIds: results[2] as List<String>,
    );
  }

  void _refresh() {
    setState(() {
      _data = _loadData();
    });
  }

  Future<void> _signOut() async {
    final app = context.read<AppProvider>();
    app.stop();
    await AuthService.instance.signOut();
    if (!mounted) return;
    app.setCurrentUser(role: 'user', name: 'Operator', email: '');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved.')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Realtime Database error (${e.code}): $e')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save changes: $e')));
    }
  }

  Future<void> _changeRole(
    Map<String, dynamic> user,
    List<Map<String, dynamic>> users,
    String currentUid,
  ) async {
    final uid = user['id'].toString();
    final currentRole = user['role']?.toString() ?? 'user';
    final nextRole = currentRole == 'admin' ? 'user' : 'admin';
    if (uid == currentUid && nextRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot remove your own admin role.')),
      );
      return;
    }
    if (currentRole == 'admin' &&
        nextRole == 'user' &&
        users.where((item) => item['role'] == 'admin').length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keep at least one administrator account.'),
        ),
      );
      return;
    }
    await _runAction(() => AuthService.instance.updateUserRole(uid, nextRole));
  }

  Future<void> _toggleUserAccess(Map<String, dynamic> user) async {
    final uid = user['id'].toString();
    final isApproved = user['accessStatus'] == 'approved';
    await _runAction(
      () => AuthService.instance.updateUserAccessStatus(
        uid,
        isApproved ? 'pending' : 'approved',
      ),
    );
  }

  Future<void> _removeUserProfile(
    Map<String, dynamic> user,
    List<Map<String, dynamic>> users,
    String currentUid,
  ) async {
    final uid = user['id'].toString();
    if (uid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot remove your own profile.')),
      );
      return;
    }
    if (user['role'] == 'admin' &&
        users.where((item) => item['role'] == 'admin').length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keep at least one administrator account.'),
        ),
      );
      return;
    }
    final confirmed = await _confirmAction(
      title: 'Remove user profile?',
      message:
          'This removes the database profile and unassigns its devices. The Firebase Authentication account itself must be deleted separately in Firebase Console.',
      action: 'Remove profile',
    );
    if (confirmed) {
      await _runAction(() => AuthService.instance.removeUserProfile(uid));
    }
  }

  Future<void> _removeDevice(Map<String, dynamic> device) async {
    final ownerUid = device['ownerUid']?.toString();
    if (ownerUid == null || ownerUid.isEmpty) return;
    final id = device['id'].toString();
    final confirmed = await _confirmAction(
      title: 'Remove device?',
      message:
          'This removes the user assignment and current readings for $id. If the ESP32 keeps sending, it may appear again as an unassigned live device.',
      action: 'Remove device',
    );
    if (confirmed) {
      await _runAction(
        () =>
            AuthService.instance.removeDevice(ownerUid: ownerUid, deviceId: id),
      );
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _registerDevice(
    List<Map<String, dynamic>> users,
    List<String> liveDeviceIds,
  ) async {
    final assignableUsers = _assignableUsers(users);
    if (assignableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approve a user account before assigning devices.'),
        ),
      );
      return;
    }
    if (liveDeviceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No unassigned live devices found. Check the ESP32 connection.',
          ),
        ),
      );
      return;
    }

    final name = TextEditingController();
    final zone = TextEditingController();
    var selectedDeviceId = liveDeviceIds.first;
    var selectedUid = assignableUsers.first['id'].toString();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign live device'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedDeviceId,
                  decoration: const InputDecoration(
                    labelText: 'Detected live device',
                  ),
                  items: [
                    for (final id in liveDeviceIds)
                      DropdownMenuItem(value: id, child: Text(id)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedDeviceId = value);
                    }
                  },
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Device name'),
                ),
                TextField(
                  controller: zone,
                  decoration: const InputDecoration(labelText: 'Room / zone'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedUid,
                  decoration: const InputDecoration(
                    labelText: 'Assign to user',
                  ),
                  items: [
                    for (final user in assignableUsers)
                      DropdownMenuItem(
                        value: user['id'].toString(),
                        child: Text(
                          '${user['name'] ?? user['email'] ?? user['id']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedUid = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (result == true && name.text.trim().isNotEmpty) {
      await _runAction(
        () => AuthService.instance.createDevice(
          deviceId: selectedDeviceId,
          name: name.text,
          zone: zone.text,
          ownerUid: selectedUid,
        ),
      );
    }
    name.dispose();
    zone.dispose();
  }

  List<Map<String, dynamic>> _assignableUsers(
    List<Map<String, dynamic>> users,
  ) => users
      .where(
        (user) => user['role'] == 'user' && user['accessStatus'] == 'approved',
      )
      .toList();

  Future<void> _assignDevice(
    Map<String, dynamic> device,
    List<Map<String, dynamic>> users,
  ) async {
    final assignableUsers = _assignableUsers(users);
    if (assignableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approve a user account before assigning devices.'),
        ),
      );
      return;
    }

    final currentOwner = device['ownerUid']?.toString();
    var selectedUserUid =
        assignableUsers.any((user) => user['id'] == currentOwner)
        ? currentOwner!
        : assignableUsers.first['id'].toString();
    final name = TextEditingController(text: device['name']?.toString() ?? '');
    final zone = TextEditingController(text: device['zone']?.toString() ?? '');
    final assignedUid = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedUserUid,
                decoration: const InputDecoration(labelText: 'Assign to user'),
                items: [
                  for (final user in assignableUsers)
                    DropdownMenuItem(
                      value: user['id'].toString(),
                      child: Text(
                        '${user['name'] ?? user['email'] ?? user['id']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedUserUid = value);
                  }
                },
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Device name'),
              ),
              TextField(
                controller: zone,
                decoration: const InputDecoration(labelText: 'Room / zone'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedUserUid),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    final deviceName = name.text;
    final deviceZone = zone.text;
    name.dispose();
    zone.dispose();
    if (assignedUid != null) {
      await _runAction(() async {
        await AuthService.instance.assignDevice(
          deviceId: device['id'].toString(),
          currentOwnerUid: currentOwner,
          newOwnerUid: assignedUid,
          name: deviceName,
          zone: deviceZone,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    if (!app.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin dashboard')),
        body: const Center(child: Text('Administrator access required.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<_DashboardData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, color: AppColors.red, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Realtime Database could not be read:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _data;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _summary(data),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text('${data.users.length}'),
                  ],
                ),
                const SizedBox(height: 10),
                if (data.users.isEmpty)
                  _emptyCard('No profiles found at users/{UID}.')
                else
                  for (final user in data.users)
                    _userCard(user, data.users, app.currentUserId),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Devices',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          _registerDevice(data.users, data.unassignedDeviceIds),
                      icon: const Icon(Icons.add),
                      label: const Text('Assign live device'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (data.unassignedDeviceIds.isNotEmpty)
                  _emptyCard(
                    'Live devices waiting for assignment: ${data.unassignedDeviceIds.join(', ')}',
                  ),
                if (data.devices.isEmpty)
                  _emptyCard(
                    'No assigned devices. Connect an ESP32 and wait for its first reading.',
                  )
                else
                  for (final device in data.devices)
                    _deviceCard(device, data.users),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summary(_DashboardData data) {
    final admins = data.users.where((user) => user['role'] == 'admin').length;
    final online = data.devices.where(_isOnline).length;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metric('${data.users.length}', 'Users')),
            const SizedBox(width: 10),
            Expanded(child: _metric('$admins', 'Admins')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _metric('${data.devices.length}', 'Devices')),
            const SizedBox(width: 10),
            Expanded(child: _metric('$online', 'Online')),
          ],
        ),
      ],
    );
  }

  Widget _metric(String value, String label) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: AppColors.muted)),
      ],
    ),
  );

  Widget _emptyCard(String text) => AppCard(
    child: Text(text, style: const TextStyle(color: AppColors.muted)),
  );

  Widget _userCard(
    Map<String, dynamic> user,
    List<Map<String, dynamic>> users,
    String currentUid,
  ) {
    final role = user['role']?.toString() ?? 'user';
    final isAdmin = role == 'admin';
    final isApproved = user['accessStatus'] == 'approved' || isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: isAdmin ? AppColors.cyan : AppColors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name']?.toString() ?? 'Unnamed user',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        user['email']?.toString() ?? '',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      Text(
                        'UID: ${user['id']} · ${role.toUpperCase()} · ${isApproved ? 'APPROVED' : 'PENDING'}',
                        style: mono.copyWith(
                          color: isApproved
                              ? AppColors.green
                              : AppColors.yellow,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isAdmin) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _toggleUserAccess(user),
                  child: Text(isApproved ? 'Revoke access' : 'Approve access'),
                ),
              ),
            ],
            if (isAdmin || user['accessStatus'] == 'approved')
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _changeRole(user, users, currentUid),
                  child: Text(isAdmin ? 'Make user' : 'Make admin'),
                ),
              ),
            if (user['id'] != currentUid)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _removeUserProfile(user, users, currentUid),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove profile'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(
    Map<String, dynamic> device,
    List<Map<String, dynamic>> users,
  ) {
    final enabled = device['enabled'] != false;
    final online = _isOnline(device);
    final ownerUid = device['ownerUid']?.toString();
    Map<String, dynamic>? owner;
    for (final user in users) {
      if (user['id'] == ownerUid) {
        owner = user;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: !enabled
                      ? AppColors.grey
                      : online
                      ? AppColors.green
                      : AppColors.yellow,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['name']?.toString() ?? 'Unnamed device',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${device['zone'] ?? 'No zone'} · ${owner?['name'] ?? ownerUid ?? 'Unassigned'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'ID: ${device['id']} · ${!enabled
                            ? 'Disabled'
                            : online
                            ? 'Online'
                            : 'Offline'}',
                        style: TextStyle(
                          color: !enabled
                              ? AppColors.grey
                              : online
                              ? AppColors.green
                              : AppColors.yellow,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (value) => _runAction(
                    () => AuthService.instance.updateDeviceEnabled(
                      device['ownerUid'].toString(),
                      device['id'].toString(),
                      value,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _assignDevice(device, users),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Assign to user'),
                  ),
                  TextButton.icon(
                    onPressed: () => _removeDevice(device),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isOnline(Map<String, dynamic> device) {
    final lastSeen = _sensorLastSeen[device['id']?.toString()];
    if (lastSeen == null) return false;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    final age = DateTime.now().difference(timestamp);
    return !age.isNegative && age.inMilliseconds <= kStaleAfterMs;
  }
}

class _DashboardData {
  const _DashboardData({
    required this.users,
    required this.devices,
    required this.unassignedDeviceIds,
  });

  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> devices;
  final List<String> unassignedDeviceIds;
}
