import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/risk_level.dart';
import '../providers/app_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/pill.dart';
import '../widgets/floor_plan.dart';
import 'incident_screen.dart';

class TwinScreen extends StatelessWidget {
  const TwinScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
        builder: (context, appState, _) {
          final s = appState;
          final lvl = s.level;
          final col = lvl.color;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Digital Twin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: const Text('Ground Floor', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              s.simulation
                  ? Text('● SIMULATION', style: mono.copyWith(color: AppColors.orange, fontWeight: FontWeight.w700))
                  : Text('● LIVE', style: mono.copyWith(color: s.sensorsOnline ? AppColors.green : AppColors.grey, fontWeight: FontWeight.w700)),
              Text('Synced ${ago(s.lastUpdate)}', style: mono.copyWith(color: AppColors.grey, fontSize: 13)),
            ]),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 0.98,
                child: LayoutBuilder(builder: (_, box) => FloorPlan(box.maxWidth, box.maxHeight, lvl, s.flame)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 14, runSpacing: 6, children: [
              _legend(AppColors.green, 'NORMAL'),
              _legend(AppColors.yellow, 'WARNING'),
              _legend(AppColors.red, 'CRITICAL'),
              _legend(AppColors.grey, 'UNKNOWN'),
              _legend(AppColors.cyan, 'ROUTE'),
            ]),
            const SizedBox(height: 6),
            Text('Laboratory 03 uses real sensor data. Other rooms are simulated.',
                style: mono.copyWith(color: AppColors.grey, fontSize: 11)),
            const SizedBox(height: 16),
            AppCard(
              border: col.withOpacity(0.5),
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Laboratory 03', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Pill(lvl.label, col),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _metric('FLAME', s.flame ? 'YES' : 'NO', s.flame ? AppColors.red : AppColors.green),
                  _metric('SMOKE', '${s.smoke}', s.smoke >= s.smokeThreshold ? AppColors.red : AppColors.text),
                  _metric('RISK', (s.risk).toStringAsFixed(2), col),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.schedule, color: AppColors.muted, size: 20),
                  const SizedBox(width: 8),
                  Text('Updated ${ago(s.lastUpdate)} · ${s.sensorsOnline ? "Sensor healthy" : "Sensor offline"}',
                      style: const TextStyle(color: AppColors.muted)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: s.active == null
                        ? null
                        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentScreen(incident: s.active!))),
                    child: Text(s.active == null ? 'No active incident' : 'View Incident ${s.active!.id}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ]),
            ),
          ]);
        },
      );

  Widget _legend(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(t, style: mono.copyWith(color: AppColors.muted, fontSize: 11)),
      ]);

  Widget _metric(String label, String value, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: mono.copyWith(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: mono.copyWith(color: c, fontSize: 24, fontWeight: FontWeight.w800)),
        ]),
      );
}
