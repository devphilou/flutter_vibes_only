import 'dart:ui';

import '../models/stroke.dart';
import '../state/drawing_state.dart';
import 'tool.dart';

/// Eraser tool uses same stroke mechanics; A2 minimal placeholder clearing
/// visually implemented later via blend mode extension (A2+).
class EraserTool implements Tool {
  const EraserTool();

  @override
  ToolType get type => ToolType.eraser;

  @override
  void onStart(DrawingState state, Offset p) => state.startStroke(p);

  @override
  void onUpdate(DrawingState state, Offset p) => state.appendPoint(p);

  @override
  void onEnd(DrawingState state) => state.endStroke();
}
