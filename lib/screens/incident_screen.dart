import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/home_config.dart';
import '../models/incident.dart';
import '../providers/app_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_box.dart';
import '../widgets/pill.dart';
import '../widgets/section_label.dart';

class IncidentScreen extends StatelessWidget {
  final Incident incident;
  const IncidentScreen({super.key, required this.incident});

  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
        builder: (context, appState, _) {
          final inc = incident;
          final s = appState;
          final isActive = inc.isActive;
          final risk = isActive ? s.risk : 1.0;
          return Scaffold(
            body: SafeArea(
              child: Column(children: [
                Expanded(
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    Row(children: [
                      IconBox(Icons.chevron_left, color: AppColors.text, onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 14),
                      Text(inc.id, style: mono.copyWith(color: AppColors.muted)),
                      const Spacer(),
                      isActive ? const Pill('ACTIVE', AppColors.red) : const Pill('CLOSED', AppColors.green),
                    ]),
                    const SizedBox(height: 16),
                    AppCard(
                      border: AppColors.red.withValues(alpha: 0.6),
                      fill: const Color(0xFF3A2026),
                      padding: const EdgeInsets.all(22),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.local_fire_department, color: AppColors.red),
                          const SizedBox(width: 10),
                          Text('CRITICAL', style: mono.copyWith(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 1.5)),
                        ]),
                        const SizedBox(height: 14),
                        const Text('Confirmed high-risk condition', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        const Row(children: [
                          Icon(Icons.location_on_outlined, color: AppColors.muted, size: 18),
                          SizedBox(width: 6),
                          Expanded(child: Text('$kHomeName › $kMonitoredRoom', style: TextStyle(color: AppColors.muted))),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _box('FIRE PROBABILITY', '${(risk * 100).round()}%')),
                      const SizedBox(width: 14),
                      Expanded(child: _box('DURATION', mmss(inc.duration), mono: true)),
                    ]),
                    const SectionLabel('SENSOR EVIDENCE'),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        _row(Icons.air, 'Smoke Density', '${s.smoke}', s.smoke >= s.smokeThreshold ? AppColors.red : AppColors.text, arrow: s.smoke >= s.smokeThreshold),
                        const Divider(height: 1, color: AppColors.border),
                        _row(Icons.local_fire_department_outlined, 'Flame Detected', s.flame ? 'YES' : 'NO', s.flame ? AppColors.red : AppColors.green),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      onTap: () {
                        Navigator.pop(context);
                        appState.setTab(1);
                      },
                      child: const Row(children: [
                        Icon(Icons.layers_outlined, color: AppColors.cyan),
                        SizedBox(width: 14),
                        Expanded(child: Text('View on Digital Twin', style: TextStyle(fontSize: 16))),
                        Icon(Icons.chevron_right, color: AppColors.grey),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Recommended Action', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 8),
                        const Text('Evacuate $kMonitoredRoom immediately and leave the house through the main door.',
                            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4)),
                        const SizedBox(height: 10),
                        Text('Recommended based on currently available sensor information.',
                            style: mono.copyWith(color: AppColors.grey, fontSize: 12)),
                      ]),
                    ),
                    const SectionLabel('TIMELINE'),
                    for (final t in inc.timeline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(hhmmss(t.time), style: mono.copyWith(color: AppColors.grey, fontSize: 13)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(t.text, style: const TextStyle(color: AppColors.muted, fontSize: 15))),
                        ]),
                      ),
                    if (inc.simulated)
                      Text('This incident was generated in Simulation Mode.', style: mono.copyWith(color: AppColors.orange, fontSize: 12)),
                  ]),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                    child: Row(children: [
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: inc.acknowledged ? null : appState.acknowledge,
                            child: Text(inc.acknowledged ? 'Acknowledged' : 'Acknowledge',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 54,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              appState.setTab(1);
                            },
                            child: const Text('Evacuation Route  →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                      ),
                    ]),
                  ),
              ]),
            ),
          );
        },
      );

  Widget _box(String label, String value, {bool mono = false}) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'monospace', color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, fontFamily: mono ? 'monospace' : null)),
        ]),
      );

  Widget _row(IconData i, String label, String value, Color c, {bool arrow = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(children: [
          Icon(i, color: AppColors.muted, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(value, style: mono.copyWith(color: c, fontWeight: FontWeight.w800, fontSize: 16)),
          if (arrow) Icon(Icons.arrow_upward, color: c, size: 18),
        ]),
      );
}
