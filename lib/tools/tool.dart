import 'package:flutter/material.dart';

import '../models/stroke.dart';
import '../state/drawing_state.dart';

/// Base contract for pluggable tools.
abstract class Tool {
  ToolType get type;
  void onStart(DrawingState state, Offset p);
  void onUpdate(DrawingState state, Offset p);
  void onEnd(DrawingState state);
}
