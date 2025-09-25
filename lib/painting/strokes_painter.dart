import 'package:flutter/material.dart';

import '../models/stroke.dart';

/// Painter that renders finalized strokes and an optional in-progress stroke.
class StrokesPainter extends CustomPainter {
  const StrokesPainter({required this.strokes, this.inProgress});

  final List<Stroke> strokes;
  final Stroke? inProgress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _paintStroke(canvas, s);
    }
    final ip = inProgress;
    if (ip != null) {
      _paintStroke(canvas, ip);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    final pts = stroke.points;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokesPainter old) {
    return old.strokes != strokes || old.inProgress != inProgress;
  }
}
