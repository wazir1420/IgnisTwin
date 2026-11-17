import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  bool _saving = false;
  String? _cachedPhotoBase64;
  ImageProvider<Object>? _cachedPhoto;

  Future<void> _choosePhoto(AppProvider app) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 320,
        maxHeight: 320,
        imageQuality: 60,
      );
      if (image == null || !mounted) return;

      final encoded = base64Encode(await image.readAsBytes());
      if (!mounted) return;
      if (encoded.length > 180000) {
        _showMessage('Choose a smaller photo and try again.');
        return;
      }

      await _saveProfile(
        app,
        name: app.currentUserName,
        phone: app.currentUserPhone,
        photoBase64: encoded,
      );
    } catch (error) {
      _showMessage('Could not upload profile photo: $error');
    }
  }

  Future<void> _editProfile(AppProvider app) async {
    final name = TextEditingController(text: app.currentUserName);
    final phone = TextEditingController(text: app.currentUserPhone);
    final formKey = GlobalKey<FormState>();
    try {
      final values = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Edit profile'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required.'
                      : value.trim().length > 100
                      ? 'Name must be 100 characters or fewer.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) => (value?.trim().length ?? 0) > 32
                      ? 'Phone must be 32 characters or fewer.'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, {
                  'name': name.text.trim(),
                  'phone': phone.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (values == null || !mounted) return;
      await _saveProfile(
        app,
        name: values['name']!,
        phone: values['phone']!,
        photoBase64: app.currentUserPhotoBase64,
      );
    } finally {
      name.dispose();
      phone.dispose();
    }
  }

  Future<void> _saveProfile(
    AppProvider app, {
    required String name,
    required String phone,
    required String photoBase64,
  }) async {
    if (_saving || !mounted) return;
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateOwnProfile(
        name: name,
        phone: phone,
        photoBase64: photoBase64,
      );
      if (!mounted) return;
      app.updateCurrentUserProfile(
        name: name,
        phone: phone,
        photoBase64: photoBase64,
      );
      _showMessage('Profile updated.');
    } catch (error) {
      _showMessage('Could not update profile: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  ImageProvider<Object>? _profileImage(String encoded) {
    if (encoded == _cachedPhotoBase64) return _cachedPhoto;
    _cachedPhotoBase64 = encoded;
    if (encoded.isEmpty) return null;
    try {
      return _cachedPhoto = MemoryImage(base64Decode(encoded));
    } on FormatException {
      return _cachedPhoto = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context
        .select<
          AppProvider,
          ({
            String name,
            String email,
            String phone,
            String photoBase64,
            String role,
            int tab,
          })
        >(
          (app) => (
            name: app.currentUserName,
            email: app.currentUserEmail,
            phone: app.currentUserPhone,
            photoBase64: app.currentUserPhotoBase64,
            role: app.currentUserRole,
            tab: app.tab,
          ),
        );
    final photo = _profileImage(profile.photoBase64);
    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF17313C), AppColors.card],
                ),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.border,
                          backgroundImage: photo,
                          child: photo == null
                              ? const Icon(
                                  Icons.person_outline,
                                  color: AppColors.muted,
                                  size: 48,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: AppColors.cyan,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _saving
                                  ? null
                                  : () => _choosePhoto(
                                      context.read<AppProvider>(),
                                    ),
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(9),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 18,
                                        color: AppColors.bg,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _choosePhoto(context.read<AppProvider>()),
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: Text(
                        profile.photoBase64.isEmpty
                            ? 'Add profile photo'
                            : 'Change profile photo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _accountLine(Icons.email_outlined, profile.email),
                  const SizedBox(height: 5),
                  _accountLine(
                    Icons.phone_outlined,
                    profile.phone.isEmpty ? 'Add phone number' : profile.phone,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile.role.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _editProfile(context.read<AppProvider>()),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit profile'),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            _destination(
              context,
              profile.tab,
              0,
              Icons.home_outlined,
              'Dashboard',
            ),
            _destination(
              context,
              profile.tab,
              1,
              Icons.layers_outlined,
              'Home map',
            ),
            _destination(
              context,
              profile.tab,
              2,
              Icons.sensors_outlined,
              'Safety checks',
            ),
            _destination(
              context,
              profile.tab,
              3,
              Icons.notifications_outlined,
              'Alerts',
            ),
            _destination(
              context,
              profile.tab,
              4,
              Icons.tune_outlined,
              'More & settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountLine(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.muted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _destination(
    BuildContext context,
    int currentTab,
    int tab,
    IconData icon,
    String label,
  ) => ListTile(
    leading: Icon(
      icon,
      color: currentTab == tab ? AppColors.cyan : AppColors.muted,
    ),
    title: Text(
      label,
      style: TextStyle(
        color: currentTab == tab ? AppColors.cyan : AppColors.text,
        fontWeight: currentTab == tab ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
    selected: currentTab == tab,
    selectedTileColor: AppColors.cyan.withValues(alpha: 0.08),
    onTap: () {
      Navigator.pop(context);
      context.read<AppProvider>().setTab(tab);
    },
  );
}
