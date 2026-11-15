import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/alert_item.dart';
import '../models/risk_level.dart';
import '../providers/app_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_box.dart';
import '../widgets/filter_chips.dart';
import '../widgets/section_label.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int filter = 0;

  bool _today(DateTime t) {
    final n = DateTime.now();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }

  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
        builder: (context, appState, _) {
          var list = appState.alerts.toList();
          if (filter == 1) list = list.where((a) => !a.read).toList();
          if (filter == 2) list = list.where((a) => a.level == RiskLevel.critical && !a.resolved).toList();
          final today = list.where((a) => _today(a.time)).toList();
          final older = list.where((a) => !_today(a.time)).toList();

          return ListView(padding: const EdgeInsets.all(20), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Alerts', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              IconBox(Icons.done_all, color: AppColors.text, onTap: appState.markAllRead),
            ]),
            const SizedBox(height: 16),
            FilterChips(const ['All', 'Unread', 'Critical'], filter, (i) => setState(() => filter = i)),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('No alerts. Everything looks calm.', style: TextStyle(color: AppColors.muted))),
              ),
            if (today.isNotEmpty) const SectionLabel('TODAY'),
            for (final a in today) _tile(a, appState),
            if (older.isNotEmpty) const SectionLabel('EARLIER'),
            for (final a in older) _tile(a, appState),
          ]);
        },
      );

  Widget _tile(AlertItem a, AppProvider appState) {
    final col = a.color;
    final label = a.resolved ? 'RESOLVED' : a.level.label;
    final icon = a.resolved
        ? Icons.check_circle_outline
        : switch (a.level) {
            RiskLevel.critical => Icons.local_fire_department,
            RiskLevel.warning => Icons.air,
            _ => Icons.wifi_off,
          };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        border: a.level == RiskLevel.critical && !a.resolved ? AppColors.red.withValues(alpha: 0.5) : null,
        fill: a.level == RiskLevel.critical && !a.resolved ? const Color(0xFF2A1D22) : null,
        onTap: () => appState.markRead(a),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconBox(icon, color: col, bg: col.withValues(alpha: 0.18), size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label, style: mono.copyWith(color: col, fontWeight: FontWeight.w700, fontSize: 13)),
                if (!a.read) ...[
                  const SizedBox(width: 8),
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.cyan, shape: BoxShape.circle)),
                ],
              ]),
              const SizedBox(height: 4),
              Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 2),
              Text(a.subtitle, style: const TextStyle(color: AppColors.muted)),
            ]),
          ),
          Text(ago(a.time), style: mono.copyWith(color: AppColors.grey, fontSize: 12)),
        ]),
      ),
    );
  }
}
