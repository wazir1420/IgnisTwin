import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/home_config.dart';
import '../providers/app_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_box.dart';
import '../widgets/pill.dart';
import '../widgets/filter_chips.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});
  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  int filter = 0;
  static const _filters = ['All', 'Smoke', 'Flame', 'Offline'];

  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
    builder: (context, appState, _) {
      final s = appState;
      final on = s.sensorsOnline;
      final items = <Widget>[];

      if (s.totalSensorCount > 0 &&
          (filter == 0 || filter == 2 || (filter == 3 && !on))) {
        items.add(
          _card(
            icon: Icons.local_fire_department,
            iconColor: s.flame ? AppColors.red : AppColors.muted,
            id: kFlameSensorId,
            loc: '$kMonitoredRoom · Flame sensor',
            online: on,
            value: s.flame ? 'DETECTED' : 'CLEAR',
            valueColor: s.flame ? AppColors.red : AppColors.text,
            ago: on ? null : ago(s.lastUpdate),
          ),
        );
      }
      if (s.totalSensorCount > 0 &&
          (filter == 0 || filter == 1 || (filter == 3 && !on))) {
        items.add(
          _card(
            icon: Icons.air,
            iconColor: s.smoke >= s.smokeThreshold
                ? AppColors.red
                : AppColors.muted,
            id: kSmokeSensorId,
            loc: '$kMonitoredRoom · Smoke sensor',
            online: on,
            value: '${s.smoke}',
            valueColor: s.smoke >= s.smokeThreshold
                ? AppColors.red
                : AppColors.text,
            ago: on ? null : ago(s.lastUpdate),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Sensors',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _dot(AppColors.green),
              Text(
                ' ${s.onlineCount} Online   ',
                style: mono.copyWith(color: AppColors.muted),
              ),
              _dot(AppColors.grey),
              Text(
                ' ${s.offlineCount} Offline',
                style: mono.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          if (s.totalSensorCount == 0) ...[
            const SizedBox(height: 12),
            const AppCard(
              child: Text(
                'No devices are assigned to your account yet. Ask the administrator to assign a live device.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
          if (!s.simulation && !on && s.lastError != null) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Text(
                s.lastError!,
                style: const TextStyle(color: AppColors.orange, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilterChips(_filters, filter, (i) => setState(() => filter = i)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const AppCard(
              child: Text(
                'No sensors match this filter',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ...items,
        ],
      );
    },
  );

  Widget _dot(Color c) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String id,
    required String loc,
    required bool online,
    required String value,
    required Color valueColor,
    String? ago,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Opacity(
      opacity: online ? 1 : 0.6,
      child: AppCard(
        child: Row(
          children: [
            IconBox(
              online ? icon : Icons.wifi_off,
              color: iconColor,
              bg: const Color(0xFF1B222B),
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: mono.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                online
                    ? const Pill('ONLINE', AppColors.green, dot: true)
                    : const Pill('OFFLINE', AppColors.grey, dot: true),
                const SizedBox(height: 8),
                Text(
                  online ? value : (ago ?? '--'),
                  style: mono.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: online ? valueColor : AppColors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
