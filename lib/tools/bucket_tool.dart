import 'dart:ui';

import '../models/stroke.dart';
import '../state/drawing_state.dart';
import 'tool.dart';

/// Bucket / fill tool placeholder (A7 target). For now this is a stub that
/// performs no action; included so the registry can enumerate all core tools
/// without conditional logic. The real implementation will invoke a flood
/// fill service and push a synthetic stroke / raster layer onto history.
class BucketTool implements Tool {
  const BucketTool();

  @override
  ToolType get type => ToolType.bucket;

  @override
  void onStart(DrawingState state, Offset p) {
    // Intentionally no-op until A7 (flood fill). Left as hook.
  }

  @override
  void onUpdate(DrawingState state, Offset p) {}

  @override
  void onEnd(DrawingState state) {}
}
