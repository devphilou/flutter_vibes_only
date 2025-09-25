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
          onPanStart: (details) {
            state.startStroke(details.localPosition);
          },
          onPanUpdate: (details) {
            state.appendPoint(details.localPosition);
          },
          onPanEnd: (_) {
            state.endStroke();
          },
          onPanCancel: () => state.endStroke(),
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
