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
    // Temporarily increase width (simple variant) while drawing.
    final original = state.currentWidth;
    state.startStroke(p, width: original * 2);
  }

  @override
  void onUpdate(DrawingState state, Offset p) => state.appendPoint(p);

  @override
  void onEnd(DrawingState state) => state.endStroke();
}
