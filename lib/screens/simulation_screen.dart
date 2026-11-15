import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_box.dart';
import '../widgets/section_label.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
        builder: (context, appState, _) {
          final s = appState;
          return Scaffold(
            body: SafeArea(
              child: Column(children: [
                Expanded(
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    Row(children: [
                      IconBox(Icons.chevron_left, color: AppColors.text, onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 14),
                      const Text('Simulation Mode', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        _seg('LIVE', !s.simulation, () => s.setSimulation(false)),
                        _seg('SIMULATION', s.simulation, () => s.setSimulation(true)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      border: AppColors.orange.withValues(alpha: 0.5),
                      fill: const Color(0xFF2E2A22),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.simulation ? 'SIMULATION MODE ACTIVE' : 'LIVE MODE',
                                style: mono.copyWith(color: AppColors.orange, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              s.simulation
                                  ? 'Values below replace the real ESP32 data. Events generated here are marked [SIM].'
                                  : 'The app is reading real ESP32 sensor data.',
                              style: const TextStyle(color: AppColors.muted, height: 1.4),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                    const SectionLabel('SCENARIO CONFIGURATION'),
                    const Text('TARGET ZONE', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    AppCard(child: const Text('Laboratory 03 · Ground Floor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
                    const SizedBox(height: 22),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('SMOKE LEVEL', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('${s.simSmoke}', style: mono.copyWith(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 17)),
                    ]),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(activeTrackColor: AppColors.orange, thumbColor: Colors.white, inactiveTrackColor: AppColors.border),
                      child: Slider(
                        min: 0,
                        max: 4095,
                        value: s.simSmoke.toDouble(),
                        onChanged: (v) => s.updateSim(s: v.round()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      child: Row(children: [
                        const Expanded(child: Text('Flame Present', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
                        Switch(
                          value: s.simFlame,
                          activeTrackColor: AppColors.orange,
                          onChanged: (v) => s.updateSim(f: v),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.info_outline, color: AppColors.grey, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Simulated incidents are marked SIM and kept separate from real incidents.',
                              style: mono.copyWith(color: AppColors.grey, fontSize: 13)),
                        ),
                      ]),
                    ),
                  ]),
                ),
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
                          onPressed: () {
                            s.updateSim(f: true, s: 2000);
                            s.setSimulation(false);
                          },
                          child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            s.setSimulation(true);
                            appState.setTab(0);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Simulation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

  Widget _seg(String t, bool on, VoidCallback f) => Expanded(
        child: GestureDetector(
          onTap: f,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: on ? AppColors.orange : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: on ? Colors.black : AppColors.grey)),
          ),
        ),
      );
}
