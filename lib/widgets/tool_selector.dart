import 'package:flutter/material.dart';

import '../models/stroke.dart';
import '../state/drawing_state.dart';

/// Horizontal tool selector (radio-style semantics) for A2 core tools.
class ToolSelector extends StatelessWidget {
  const ToolSelector({super.key, required this.state});

  final DrawingState state;

  // Available tools now driven by DrawingState registry so selector updates
  // automatically if tools are injected differently (testing / feature flags).

  IconData _icon(ToolType t) => switch (t) {
        ToolType.pencil => Icons.edit,
        ToolType.brush => Icons.brush,
        ToolType.eraser => Icons.auto_fix_normal, // Placeholder icon
        ToolType.eyedropper => Icons.colorize,
        ToolType.bucket => Icons.format_color_fill,
        ToolType.shape => Icons.crop_square,
      };

  String _label(ToolType t) => switch (t) {
        ToolType.pencil => 'Pencil',
        ToolType.brush => 'Brush',
        ToolType.eraser => 'Eraser',
        ToolType.eyedropper => 'Eyedropper',
        ToolType.bucket => 'Bucket',
        ToolType.shape => 'Shape',
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        // Temporary: bucket tool not yet implemented in free drawing.
        // If it somehow became active (e.g., programmatically), revert to pencil.
        if (state.activeTool == ToolType.bucket) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.activeTool == ToolType.bucket) {
              state.setActiveTool(ToolType.pencil);
            }
          });
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tool in state.availableTools)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Semantics(
                  button: true,
                  enabled: tool != ToolType.bucket,
                  selected: state.activeTool == tool,
                  label: tool == ToolType.bucket
                      ? '${_label(tool)} (coming soon)'
                      : _label(tool),
                  child: Tooltip(
                    message: tool == ToolType.bucket
                        ? '${_label(tool)} – coming soon'
                        : _label(tool),
                    child: InkWell(
                      onTap: tool == ToolType.bucket
                          ? null
                          : () => state.setActiveTool(tool),
                      borderRadius: BorderRadius.circular(8),
                      child: Opacity(
                        opacity: tool == ToolType.bucket ? 0.45 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: state.activeTool == tool
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: state.activeTool == tool
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _icon(tool),
                            size: 20,
                            color: state.activeTool == tool
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
