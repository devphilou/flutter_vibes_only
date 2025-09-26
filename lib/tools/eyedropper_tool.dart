import 'dart:ui';

import '../models/stroke.dart';
import '../state/drawing_state.dart';
import 'tool.dart';

/// Eyedropper (stub): on tap start selects last stroke color overlapping point.
/// For now, just sets current color to last stroke's color and does not create a stroke.
class EyedropperTool implements Tool {
  const EyedropperTool();

  @override
  ToolType get type => ToolType.eyedropper;

  @override
  void onStart(DrawingState state, Offset p) {
    // Simple heuristic: sample last stroke color if any.
    if (state.strokes.isNotEmpty) {
      final color = state.strokes.last.color;
      state.setColor(color);
    }
  }

  @override
  void onUpdate(DrawingState state, Offset p) {}

  @override
  void onEnd(DrawingState state) {}
}
