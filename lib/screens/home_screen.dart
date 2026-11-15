import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/incident.dart';
import '../models/risk_level.dart';
import '../providers/app_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_box.dart';
import '../widgets/pill.dart';
import '../widgets/section_label.dart';
import 'incident_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
        builder: (context, appState, _) {
          final s = appState;
          final lvl = s.level;
          final col = lvl.color;
          final risk = s.risk;
          final riskCol = Color.lerp(AppColors.yellow, AppColors.red, risk)!;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const IconBox(Icons.menu, color: AppColors.text),
              s.simulation
                  ? const Pill('SIMULATION', AppColors.orange, dot: true)
                  : !s.sensorsOnline
                      ? const Pill('OFFLINE', AppColors.grey, dot: true)
                      : s.useDummy
                          ? const Pill('DEMO DATA', AppColors.cyan, dot: true)
                          : const Pill('LIVE', AppColors.green, dot: true),
              Stack(clipBehavior: Clip.none, children: [
                IconBox(Icons.notifications_none, color: AppColors.text, onTap: () => appState.setTab(3)),
                if (s.unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.red,
                      child: Text('${s.unreadCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
            ]),
            const SizedBox(height: 18),
            AppCard(
              border: col.withValues(alpha: 0.5),
              fill: col.withValues(alpha: 0.10),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(lvl == RiskLevel.critical ? Icons.local_fire_department : Icons.warning_amber_rounded, color: col),
                  const SizedBox(width: 8),
                  Text(lvl.label, style: mono.copyWith(color: col, fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  Text('Updated ${ago(s.lastUpdate)}', style: mono.copyWith(color: AppColors.grey, fontSize: 12)),
                ]),
                const SizedBox(height: 12),
                const Text('Main Building', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  lvl == RiskLevel.normal
                      ? 'Ground Floor · All zones normal'
                      : lvl == RiskLevel.unknown
                          ? 'Ground Floor · Sensors not responding'
                          : 'Ground Floor · 1 zone elevated',
                  style: const TextStyle(color: AppColors.muted, fontSize: 16),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _stat(Icons.sensors, '${s.onlineCount}', 'Sensors Online', trailing: '${s.onlineCount}/2', trailingColor: AppColors.green)),
              const SizedBox(width: 14),
              Expanded(child: _stat(Icons.wifi_off, '${2 - s.onlineCount}', 'Sensors Offline')),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _stat(Icons.local_fire_department, '${s.active != null ? 1 : 0}', 'Active Incidents',
                    iconColor: AppColors.red, valueColor: s.active != null ? AppColors.red : AppColors.text),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _stat(Icons.location_on_outlined, '${lvl == RiskLevel.critical ? 1 : 0}', 'Critical Zones'),
              ),
            ]),
            const SizedBox(height: 14),
            AppCard(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Fire Probability · Zone LAB03', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${(risk * 100).round()}%', style: TextStyle(color: riskCol, fontWeight: FontWeight.w800, fontSize: 17)),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: risk, minHeight: 8, color: riskCol, backgroundColor: AppColors.border),
                ),
              ]),
            ),
            SectionLabel('ACTIVE INCIDENTS', action: 'View all', onAction: () {}),
            if (s.active != null)
              _incidentCard(context, s.active!, s.flame)
            else
              const AppCard(child: Text('No active incidents', style: TextStyle(color: AppColors.muted))),
            SectionLabel('RECENT ALERTS', action: 'View all', onAction: () => appState.setTab(3)),
            if (s.alerts.isEmpty) const AppCard(child: Text('No alerts yet', style: TextStyle(color: AppColors.muted))),
            for (final a in s.alerts.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: a.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(a.title, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis)),
                    Text(ago(a.time), style: mono.copyWith(color: AppColors.grey, fontSize: 12)),
                  ]),
                ),
              ),
          ]);
        },
      );

  Widget _stat(IconData icon, String value, String label,
      {String? trailing, Color? trailingColor, Color iconColor = AppColors.muted, Color valueColor = AppColors.text}) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: iconColor, size: 20),
          if (trailing != null) Text(trailing, style: mono.copyWith(color: trailingColor, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: valueColor)),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
      ]),
    );
  }

  Widget _incidentCard(BuildContext context, Incident inc, bool flame) => AppCard(
        border: AppColors.red.withValues(alpha: 0.5),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentScreen(incident: inc))),
        child: Row(children: [
          const IconBox(Icons.local_fire_department, color: AppColors.red, bg: Color(0xFF3A1D22), size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('CRITICAL', style: mono.copyWith(color: AppColors.red, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(inc.id, style: mono.copyWith(color: AppColors.grey, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              const Text('Laboratory 03 · Ground Floor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(
                '${flame ? "Flame confirmed" : "High smoke"} · ${mmss(inc.duration)} ago',
                style: const TextStyle(color: AppColors.muted),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey),
        ]),
      );
}
