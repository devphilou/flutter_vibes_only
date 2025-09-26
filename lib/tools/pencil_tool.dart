import 'dart:ui';

import '../models/stroke.dart';
import '../state/drawing_state.dart';
import 'tool.dart';

/// Pencil replicates current MVP drawing behavior.
class PencilTool implements Tool {
  const PencilTool();

  @override
  ToolType get type => ToolType.pencil;

  @override
  void onStart(DrawingState state, Offset p) => state.startStroke(p);

  @override
  void onUpdate(DrawingState state, Offset p) => state.appendPoint(p);

  @override
  void onEnd(DrawingState state) => state.endStroke();
}
