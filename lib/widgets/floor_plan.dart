import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/risk_level.dart';

class FloorPlan extends StatelessWidget {
  final double w, h;
  final RiskLevel lvl;
  final bool flame;
  const FloorPlan(this.w, this.h, this.lvl, this.flame);

  Rect _r(double l, double t, double ww, double hh) => Rect.fromLTWH(l * w, t * h, ww * w, hh * h);

  Widget _room(Rect r, String name, Color c, {bool dashed = false, Widget? child, String? sub, Color? fill}) {
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
            if (sub != null) Text(sub, style: mono.copyWith(color: AppColors.grey, fontSize: 8)),
          ]),
          if (child != null) Center(child: child),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lab03 = lvl.color;
    final dot = (Color c) => Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
    return Stack(children: [
      _room(_r(0.02, 0.02, 0.33, 0.38), 'LAB 01', AppColors.green.withOpacity(0.7), child: dot(AppColors.green)),
      _room(_r(0.38, 0.02, 0.28, 0.38), 'LAB 03', lab03,
          fill: lvl == RiskLevel.critical ? AppColors.red.withOpacity(0.18) : lvl == RiskLevel.warning ? AppColors.yellow.withOpacity(0.10) : null,
          child: flame
              ? const Icon(Icons.local_fire_department, color: AppColors.red, size: 30)
              : dot(lab03)),
      _room(_r(0.69, 0.02, 0.29, 0.38), 'RM 101', AppColors.green.withOpacity(0.7), child: dot(AppColors.green)),
      Positioned.fromRect(
        rect: _r(0.02, 0.44, 0.96, 0.12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF1A212A), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Text('CORRIDOR A', style: mono.copyWith(color: AppColors.grey, fontSize: 10)),
        ),
      ),
      _room(_r(0.02, 0.60, 0.30, 0.37), 'STAIRS 1', AppColors.border),
      _room(_r(0.35, 0.60, 0.30, 0.37), 'OFFICE 02', AppColors.green.withOpacity(0.7), child: dot(AppColors.green)),
      _room(_r(0.68, 0.60, 0.30, 0.37), 'STORAGE', AppColors.grey, dashed: true, sub: 'NO SENSOR'),
      Positioned.fromRect(
        rect: _r(0.0, 0.70, 0.03, 0.16),
        child: Container(color: AppColors.green.withOpacity(0.5)),
      ),
      if (lvl == RiskLevel.critical)
        Positioned.fill(
          child: CustomPaint(
            painter: _RoutePainter([
              Offset(0.52 * w, 0.30 * h),
              Offset(0.52 * w, 0.50 * h),
              Offset(0.15 * w, 0.50 * h),
              Offset(0.15 * w, 0.78 * h),
              Offset(0.02 * w, 0.78 * h),
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
