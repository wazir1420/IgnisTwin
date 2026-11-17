import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/home_config.dart';
import '../models/risk_level.dart';


class FloorPlan extends StatelessWidget {
  final double w, h;
  final RiskLevel lvl;
  final bool flame;
  const FloorPlan(this.w, this.h, this.lvl, this.flame, {super.key});

  Rect _r(double l, double t, double ww, double hh) =>
      Rect.fromLTWH(l * w, t * h, ww * w, hh * h);

  Widget _room(Rect r, String name, Color c,
      {bool dashed = false, Widget? child, String? sub, Color? fill}) {
    return Positioned.fromRect(
      rect: r,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: fill ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c, width: dashed ? 1.2 : 1.6),
        ),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: mono.copyWith(color: AppColors.muted, fontSize: 10)),
            if (sub != null)
              Text(sub, style: mono.copyWith(color: AppColors.grey, fontSize: 8)),
          ]),
          if (child != null) Center(child: child),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomCol = lvl.color;
    Widget dot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));

    return Stack(children: [

      _room(
        _r(0.03, 0.03, 0.46, 0.44),
        kMonitoredRoom,
        roomCol,
        fill: lvl == RiskLevel.critical
            ? AppColors.red.withValues(alpha: 0.18)
            : lvl == RiskLevel.warning
                ? AppColors.yellow.withValues(alpha: 0.10)
                : null,
        child: flame
            ? const Icon(Icons.local_fire_department, color: AppColors.red, size: 30)
            : dot(roomCol),
      ),

      _room(_r(0.53, 0.03, 0.44, 0.44), kRoomNames[1], AppColors.grey,
          dashed: true, sub: 'Not monitored'),
      _room(_r(0.03, 0.51, 0.94, 0.42), kRoomNames[2], AppColors.grey,
          dashed: true, sub: 'Not monitored'),

      Positioned.fromRect(
        rect: _r(0.42, 0.93, 0.16, 0.03),
        child: Container(color: AppColors.green.withValues(alpha: 0.5)),
      ),
      if (lvl == RiskLevel.critical)
        Positioned.fill(
          child: CustomPaint(
            painter: _RoutePainter([
              Offset(0.26 * w, 0.25 * h),
              Offset(0.26 * w, 0.72 * h),
              Offset(0.50 * w, 0.72 * h),
              Offset(0.50 * w, 0.94 * h),
            ]),
          ),
        ),
    ]);
  }
}

class _RoutePainter extends CustomPainter {
  final List<Offset> pts;
  _RoutePainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final paint = Paint()
      ..color = AppColors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 8), paint);
        d += 14;
      }
    }
    final fill = Paint()..color = AppColors.cyan;
    canvas.drawCircle(pts.first, 6, fill);
    canvas.drawCircle(pts.last, 6, fill);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => false;
}
