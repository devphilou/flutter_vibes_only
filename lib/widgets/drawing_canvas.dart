import 'package:flutter/material.dart';

import '../models/stroke.dart';
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
            switch (state.activeTool) {
              case ToolType.pencil:
              case ToolType.brush:
                state.startStroke(details.localPosition);
                break;
              case ToolType.eraser:
                // Placeholder: treat eraser as drawing with background color.
                state.startStroke(details.localPosition,
                    color: const Color(0xFFFFFFFF));
                break;
              case ToolType.eyedropper:
                // Eyedropper: would sample pixel color under pointer (needs
                // rendered image capture). For now no-op / future hook.
                break;
              case ToolType.bucket:
                // Future: flood fill.
                break;
            }
          },
          onPanUpdate: (details) {
            switch (state.activeTool) {
              case ToolType.pencil:
              case ToolType.brush:
              case ToolType.eraser:
                state.appendPoint(details.localPosition);
                break;
              case ToolType.eyedropper:
              case ToolType.bucket:
                break;
            }
          },
          onPanEnd: (_) {
            switch (state.activeTool) {
              case ToolType.pencil:
              case ToolType.brush:
              case ToolType.eraser:
                state.endStroke();
                break;
              case ToolType.eyedropper:
              case ToolType.bucket:
                break;
            }
          },
          onPanCancel: () {
            switch (state.activeTool) {
              case ToolType.pencil:
              case ToolType.brush:
              case ToolType.eraser:
                state.endStroke();
                break;
              case ToolType.eyedropper:
              case ToolType.bucket:
                break;
            }
          },
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
