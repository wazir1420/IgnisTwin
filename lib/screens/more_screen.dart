import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/home_config.dart';
import '../models/data_source.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_box.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'simulation_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'More',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        _overviewCard(p),
        const SizedBox(height: 6),
        _hardwareCard(),
        const SizedBox(height: 6),
        if (p.isAdmin)
          _tile(
            Icons.science_outlined,
            'Test alerts',
            'Try sample fire and smoke alerts',
            AppColors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimulationScreen()),
            ),
          ),
        if (p.isAdmin)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBox(
                        Icons.storage_outlined,
                        color: AppColors.green,
                        bg: AppColors.green.withValues(alpha: 0.15),
                        size: 48,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Sensor connection',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<DataSource>(
                      showSelectedIcon: false,
                      segments: [
                        for (final d in DataSource.values)
                          ButtonSegment(value: d, label: Text(d.label)),
                      ],
                      selected: {p.source},
                      onSelectionChanged: (v) => p.setSource(v.first),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    switch (p.source) {
                      DataSource.firebase =>
                        'Readings sent through your online account.',
                      DataSource.esp32 =>
                        'Readings sent directly over the local Wi-Fi network.',
                    },
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (p.isAdmin)
          _tile(
            Icons.router_outlined,
            'Device settings',
            'Wi-Fi address and alert level',
            AppColors.cyan,
            () => _settings(context),
          ),
        if (p.isAdmin)
          _tile(
            Icons.dashboard_customize,
            'Admin Dashboard',
            'Manage users and connected devices',
            AppColors.cyan,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            ),
          ),
        _tile(Icons.logout, 'Sign out', '', AppColors.muted, () async {
          final app = context.read<AppProvider>();
          app.stop();
          app.setCurrentUser(role: 'user', name: 'Operator', email: '');
          await AuthService.instance.signOut();
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }),
        const SizedBox(height: 20),
        Text(
          'For extra awareness only. Do not rely on this app as a certified fire alarm.',
          style: mono.copyWith(color: AppColors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _overviewCard(AppProvider p) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.monitor_heart_outlined,
          title: 'Monitoring overview',
          color: AppColors.cyan,
        ),
        const SizedBox(height: 16),
        _detailRow(
          Icons.wifi_tethering,
          'Connection',
          p.simulation
              ? 'Test alerts'
              : p.totalSensorCount == 0
              ? 'No device assigned'
              : p.sensorsOnline
              ? 'Connected'
              : 'Waiting for device readings',
          p.sensorsOnline ? AppColors.green : AppColors.orange,
        ),
        _detailRow(
          Icons.sensors_outlined,
          'Safety checks',
          '${p.totalSensorCount} checks · ${p.totalSensorCount ~/ 2} device${p.totalSensorCount ~/ 2 == 1 ? '' : 's'}',
          AppColors.cyan,
        ),
        _detailRow(
          Icons.notifications_active_outlined,
          'Active alerts',
          p.active == null ? 'None' : '1 · Fire response active',
          p.active == null ? AppColors.green : AppColors.red,
        ),
        _detailRow(
          Icons.update,
          'Last reading',
          ago(p.lastUpdate),
          AppColors.muted,
        ),
        _detailRow(
          Icons.meeting_room_outlined,
          'Monitored area',
          '$kHomeName · $kMonitoredRoom',
          AppColors.muted,
          last: true,
        ),
      ],
    ),
  );

  Widget _hardwareCard() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.memory_outlined,
          title: 'Your safety devices',
          color: AppColors.orange,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your connected device watches for fire signs and changes in the air.',
          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 14),
        _hardwareItem(
          icon: Icons.developer_board_outlined,
          title: 'Wireless safety device',
          detail: 'Sends new readings over Wi-Fi about every 2 seconds.',
          color: AppColors.cyan,
        ),
        _hardwareItem(
          icon: Icons.local_fire_department_outlined,
          title: 'Fire detector',
          detail: 'Looks for signs of an open flame in the monitored area.',
          color: AppColors.red,
        ),
        _hardwareItem(
          icon: Icons.cloud_outlined,
          title: 'Smoke and gas detector',
          detail:
              'MQ-2 model. Checks the air for smoke and certain gases; it may need time to warm up.',
          color: AppColors.orange,
        ),
        _hardwareItem(
          icon: Icons.sync,
          title: 'Updates',
          detail: 'Your device sends new readings about every 2 seconds.',
          color: AppColors.green,
          last: true,
        ),
      ],
    ),
  );

  Widget _hardwareItem({
    required IconData icon,
    required String title,
    required String detail,
    required Color color,
    bool last = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
    Color color, {
    bool last = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 13),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _tile(IconData i, String t, String sub, Color c, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          onTap: onTap,
          child: Row(
            children: [
              IconBox(i, color: c, bg: c.withValues(alpha: 0.15), size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ),
        ),
      );

  void _settings(BuildContext context) {
    final provider = context.read<AppProvider>();
    final ip = TextEditingController(text: provider.espIp);
    final thr = TextEditingController(text: '${provider.smokeThreshold}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Device connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ip,
              decoration: const InputDecoration(
                labelText: 'Device Wi-Fi address',
              ),
            ),
            TextField(
              controller: thr,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Smoke alert level (advanced)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.saveSettings(ip.text, int.tryParse(thr.text) ?? 1500);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}
