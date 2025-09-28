import 'package:flutter/material.dart';

import '../models/stroke.dart';
import '../state/drawing_state.dart';
import 'tool.dart';

/// Shape tool: uses DrawingState shape preview helpers to manage a parametric
/// shape lifecycle (preview during drag, commit on release).
class ShapeTool implements Tool {
  const ShapeTool();

  @override
  ToolType get type => ToolType.shape;

  @override
  void onStart(DrawingState state, Offset p) {
    state.beginShape(p);
  }

  @override
  void onUpdate(DrawingState state, Offset p) {
    // TODO: pass constrainProportions=true if Shift currently pressed. Requires
    // wiring from gesture layer with hardware keyboard events.
    state.updateShape(p);
  }

  @override
  void onEnd(DrawingState state) {
    state.commitShape();
  }
}
