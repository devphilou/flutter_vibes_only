import 'package:flutter/material.dart';

import '../painting/strokes_painter.dart';
import '../state/drawing_state.dart';
import '../strings/app_strings.dart';

/// Widget capturing pointer gestures and delegating rendering to [StrokesPainter].
class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({
    super.key,
    required this.state,
    required this.boundaryKey,
  });

  final DrawingState state;
  final GlobalKey boundaryKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.drawingCanvasLabel,
      container: true,
      child: Listener(
        // Listener provides more granular pointer events if needed later.
        child: GestureDetector(
          onTapDown: (details) {
            state.attachCanvasBoundaryKey(boundaryKey);
            // Ensure tools that act on single tap (eyedropper, future bucket) get start event.
            state.handlePointerStart(details.localPosition);
            state.handlePointerEnd();
          },
          onPanStart: (details) =>
              state.handlePointerStart(details.localPosition),
          onPanUpdate: (details) =>
              state.handlePointerUpdate(details.localPosition),
          onPanEnd: (_) => state.handlePointerEnd(),
          onPanCancel: () => state.handlePointerEnd(),
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: state,
            builder: (context, _) {
              return RepaintBoundary(
                key: boundaryKey,
                child: CustomPaint(
                  painter: StrokesPainter(
                    strokes: state.strokes,
                    inProgress: state.inProgress,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
