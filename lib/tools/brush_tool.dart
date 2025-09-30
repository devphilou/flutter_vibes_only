import 'dart:math' as math;
import 'dart:ui';

import '../models/stroke.dart';
import '../state/drawing_state.dart';
import 'tool.dart';

/// Basic brush variant: currently identical to pencil except thicker default.
class BrushTool implements Tool {
  const BrushTool();

  @override
  ToolType get type => ToolType.brush;

  @override
  void onStart(DrawingState state, Offset p) {
    final base = state.currentWidth;
    final style = state.brushStyle;
    double width = base * 2;
    if (style == BrushStyle.soft) {
      width = base * 2.2;
    } else if (style == BrushStyle.calligraphic) {
      width = base * 2.4; // initial broad stroke
    }
    state.startStroke(p, width: width);
  }

  @override
  void onUpdate(DrawingState state, Offset p) {
    if (state.brushStyle == BrushStyle.calligraphic) {
      // Dynamically vary width based on instantaneous direction delta.
      final ip = state.inProgress;
      if (ip != null && ip.points.length >= 2) {
        final last = ip.points[ip.points.length - 1];
        final prev = ip.points[ip.points.length - 2];
        final v = last - prev;
        final angle = v.direction; // radians
        // Use cosine of angle to bias width (simulate nib orientation).
        final bias = (math.cos(angle)).abs();
        final base = state.currentWidth * 2.4;
        final varied = base * (0.55 + 0.45 * bias); // keep > 0
        // Recreate stroke with adjusted width (keeping points as-is).
        state.replaceInProgress(width: varied);
      }
    }
    state.appendPoint(p);
  }

  @override
  void onEnd(DrawingState state) => state.endStroke();
}
