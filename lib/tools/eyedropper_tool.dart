import 'dart:ui';

import '../models/stroke.dart';
import '../state/drawing_state.dart';
import 'tool.dart';

/// Eyedropper tool: on tap it samples the nearest stroke color under the cursor
/// (searching from top-most / most recent). It performs a geometric distance
/// check against stroke segments and selects the first match, then automatically
/// reverts to the previous drawing tool for fluid workflow.
class EyedropperTool implements Tool {
  const EyedropperTool();

  @override
  ToolType get type => ToolType.eyedropper;

  @override
  void onStart(DrawingState state, Offset p) {
    _performPick(state, p);
  }

  @override
  void onUpdate(DrawingState state, Offset p) {}

  @override
  void onEnd(DrawingState state) {}

  Future<void> _performPick(DrawingState state, Offset p) async {
    // Try pixel sampling first.
    Color? sampled = await state.samplePixel(p);
    // Fallback heuristic if pixel sampling failed.
    sampled ??= _strokeHeuristic(state, p);
    if (sampled != null) {
      state.setColor(sampled);
      state.completeEyedropperSelection();
    }
  }

  Color? _strokeHeuristic(DrawingState state, Offset p) {
    for (var i = state.strokes.length - 1; i >= 0; i--) {
      final stroke = state.strokes[i];
      final pts = stroke.points;
      if (pts.length < 2) {
        if (pts.isNotEmpty && (pts.first - p).distance <= stroke.width) {
          return stroke.color;
        }
        continue;
      }
      for (var j = 0; j < pts.length - 1; j++) {
        final a = pts[j];
        final b = pts[j + 1];
        final dist = _distancePointToSegment(p, a, b);
        if (dist <= stroke.width * 0.75) {
          return stroke.color;
        }
      }
    }
    return null;
  }

  double _distancePointToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) return (p - a).distance;
    var t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLen2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }
}
