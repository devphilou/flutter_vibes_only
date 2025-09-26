import 'package:flutter/material.dart';

import '../models/stroke.dart';
import '../state/drawing_state.dart';

/// Horizontal tool selector (radio-style semantics) for A2 core tools.
class ToolSelector extends StatelessWidget {
  const ToolSelector({super.key, required this.state});

  final DrawingState state;

  static const _tools = [
    ToolType.pencil,
    ToolType.brush,
    ToolType.eraser,
    ToolType.eyedropper,
  ];

  IconData _icon(ToolType t) => switch (t) {
        ToolType.pencil => Icons.edit,
        ToolType.brush => Icons.brush,
        ToolType.eraser => Icons.auto_fix_normal, // Placeholder icon
        ToolType.eyedropper => Icons.colorize,
        ToolType.bucket => Icons.format_color_fill,
      };

  String _label(ToolType t) => switch (t) {
        ToolType.pencil => 'Pencil',
        ToolType.brush => 'Brush',
        ToolType.eraser => 'Eraser',
        ToolType.eyedropper => 'Eyedropper',
        ToolType.bucket => 'Bucket',
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tool in _tools)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Semantics(
                  button: true,
                  selected: state.activeTool == tool,
                  label: _label(tool),
                  child: Tooltip(
                    message: _label(tool),
                    child: InkWell(
                      onTap: () => state.setActiveTool(tool),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: state.activeTool == tool
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: state.activeTool == tool
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _icon(tool),
                          size: 20,
                          color: state.activeTool == tool
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
