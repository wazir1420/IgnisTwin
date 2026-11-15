import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'twin_screen.dart';
import 'sensors_screen.dart';
import 'alerts_screen.dart';
import 'more_screen.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.layers_outlined, Icons.layers, 'Twin'),
    (Icons.sensors, Icons.sensors, 'Sensors'),
    (Icons.notifications_none, Icons.notifications, 'Alerts'),
    (Icons.apps, Icons.apps, 'More'),
  ];

  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
        builder: (context, st, _) {
          final i = st.tab;
          return Scaffold(
          body: SafeArea(
            child: IndexedStack(index: i, children: const [
              HomeScreen(),
              TwinScreen(),
              SensorsScreen(),
              AlertsScreen(),
              MoreScreen(),
            ]),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(children: [
                for (var k = 0; k < _tabs.length; k++)
                  Expanded(
                    child: InkWell(
                      onTap: () => st.setTab(k),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(k == i ? _tabs[k].$2 : _tabs[k].$1, color: k == i ? AppColors.cyan : AppColors.grey),
                          const SizedBox(height: 4),
                          Text(_tabs[k].$3,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: k == i ? AppColors.cyan : AppColors.grey)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        );
        },
      );
}
