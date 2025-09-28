import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/stroke.dart';

/// Painter that renders finalized strokes and an optional in-progress stroke.
class StrokesPainter extends CustomPainter {
  const StrokesPainter({
    required this.strokes,
    this.inProgress,
    this.previewShape,
    this.previewColor,
  });

  final List<Stroke> strokes;
  final Stroke? inProgress;
  final ShapeMeta? previewShape;
  final Color? previewColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Use a saveLayer so eraser strokes (BlendMode.clear) punch holes in what
    // has already been drawn rather than in the underlying scaffold.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final s in strokes) {
      _paintStroke(canvas, s);
    }
    final ip = inProgress;
    if (ip != null) {
      _paintStroke(canvas, ip);
    }
    // Preview shape (ghost) rendered above existing strokes.
    if (previewShape != null) {
      _paintPreviewShape(canvas, previewShape!);
    }
    canvas.restore();
  }

  void _paintPreviewShape(Canvas canvas, ShapeMeta meta) {
    final base = previewColor ?? const Color(0xFF000000);
    final paint = Paint()
      ..color = base.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (meta.type) {
      case ShapeType.line:
        canvas.drawLine(meta.start, meta.end, paint);
        return;
      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromPoints(meta.start, meta.end), paint);
        return;
      case ShapeType.circle:
        final rect = Rect.fromPoints(meta.start, meta.end);
        final radius = rect.longestSide / 2;
        final center =
            Offset(rect.left + rect.width / 2, rect.top + rect.height / 2);
        canvas.drawCircle(center, radius, paint);
        return;
      case ShapeType.wave:
        final path = Path();
        final start = meta.start;
        final end = meta.end;
        final dx = end.dx - start.dx;
        final dy = end.dy - start.dy;
        const segments = 20;
        path.moveTo(start.dx, start.dy);
        for (int i = 1; i <= segments; i++) {
          final t = i / segments;
          final x = start.dx + dx * t;
          final sine = math.sin(t * math.pi * 2);
          final y = start.dy + dy * t + sine * 6;
          path.lineTo(x, y);
        }
        canvas.drawPath(path, paint);
        return;
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    final isEraser = stroke.toolType == ToolType.eraser;
    final paint = Paint()
      ..color = isEraser ? const Color(0x00000000) : stroke.color
      ..blendMode =
          stroke.blendMode ?? (isEraser ? BlendMode.clear : BlendMode.srcOver)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // If this is a parametric shape, derive path/figure from metadata.
    final meta = stroke.shapeMeta;
    if (meta != null) {
      switch (meta.type) {
        case ShapeType.line:
          canvas.drawLine(meta.start, meta.end, paint);
          return;
        case ShapeType.rectangle:
          final rect = Rect.fromPoints(meta.start, meta.end);
          canvas.drawRect(rect, paint);
          return;
        case ShapeType.circle:
          final rect = Rect.fromPoints(meta.start, meta.end);
          final radius = rect.longestSide / 2;
          final center =
              Offset(rect.left + rect.width / 2, rect.top + rect.height / 2);
          canvas.drawCircle(center, radius, paint);
          return;
        case ShapeType.wave:
          // Placeholder wave: simple sine-like polyline between start & end.
          final path = Path();
          final start = meta.start;
          final end = meta.end;
          final dx = end.dx - start.dx;
          final dy = end.dy - start.dy;
          const segments = 20;
          path.moveTo(start.dx, start.dy);
          for (int i = 1; i <= segments; i++) {
            final t = i / segments;
            final x = start.dx + dx * t;
            // Simple sine oscillation perpendicular-ish to line using dy as base.
            final sine = math.sin(t * math.pi * 2);
            final y = start.dy + dy * t + sine * 6; // amplitude 6px.
            path.lineTo(x, y);
          }
          canvas.drawPath(path, paint);
          return;
      }
    }

    // Freehand fallback: draw path from points.
    if (stroke.points.isEmpty) return;
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
    return old.strokes != strokes ||
        old.inProgress != inProgress ||
        old.previewShape != previewShape;
  }
}
