import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_box.dart';
import 'login_screen.dart';
import 'simulation_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('More', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      _tile(Icons.science_outlined, 'Simulation Mode', 'Test alerts with sliders', AppColors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimulationScreen()))),
      // Data source: dummy ya real ESP32
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Row(children: [
            IconBox(Icons.storage_outlined, color: AppColors.green, bg: AppColors.green.withValues(alpha: 0.15), size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Dummy data', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(p.useDummy ? 'ON · no hardware needed' : 'OFF · reading real ESP32',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ]),
            ),
            Switch(
              value: p.useDummy,
              activeTrackColor: AppColors.cyan,
              onChanged: p.setUseDummy,
            ),
          ]),
        ),
      ),
      _tile(Icons.router_outlined, 'ESP32 connection', 'IP address & smoke threshold', AppColors.cyan,
          () => _settings(context)),
      _tile(Icons.logout, 'Sign out', '', AppColors.muted, () {
        context.read<AppProvider>().stop();
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      }),
      const SizedBox(height: 20),
      Text('Academic prototype v1.0. Not a certified fire alarm.',
          style: mono.copyWith(color: AppColors.grey, fontSize: 12)),
    ]);
  }

  Widget _tile(IconData i, String t, String sub, Color c, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          onTap: onTap,
          child: Row(children: [
            IconBox(i, color: c, bg: c.withValues(alpha: 0.15), size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ]),
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
        title: const Text('ESP32 connection'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ip, decoration: const InputDecoration(labelText: 'ESP32 IP (e.g. 192.168.1.50)')),
          TextField(
            controller: thr,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Smoke threshold (0-4095)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
