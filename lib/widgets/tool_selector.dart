import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../models/stroke.dart';
import '../state/drawing_state.dart';
import 'app_asset_icon.dart';

/// Horizontal tool selector (radio-style semantics) for A2 core tools.
class ToolSelector extends StatelessWidget {
  const ToolSelector({super.key, required this.state});

  final DrawingState state;

  // Available tools now driven by DrawingState registry so selector updates
  // automatically if tools are injected differently (testing / feature flags).

  // Map to asset paths for custom icons.
  String? _assetFor(ToolType t) => switch (t) {
        ToolType.pencil => AppAssets.pencil,
        ToolType.brush => AppAssets.paintBrush,
        ToolType.eraser => AppAssets.eraser,
        ToolType.eyedropper => AppAssets.eyedropper,
        ToolType.bucket => AppAssets.bucket,
        ToolType.shape => null, // Shape tool soon can reflect selected shape.
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
                          child: _buildIcon(context, tool),
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

  Widget _buildIcon(BuildContext context, ToolType tool) {
    final asset = _assetFor(tool);
    final colorScheme = Theme.of(context).colorScheme;
    final selected = state.activeTool == tool;
    if (asset != null) {
      // Preserve original multi-color asset; adjust selection via background +
      // slight opacity only (no color tint) so the icon isn't monochrome.
      return Opacity(
        opacity: selected ? 1.0 : 0.85,
        child: AppAssetIcon(
          asset,
          size: 24,
          semanticLabel: _label(tool),
        ),
      );
    }
    // For shape tool, show a simple stacked icon group or fallback Material icon.
    return Icon(
      Icons.category_outlined,
      size: 22,
      color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
    );
  }
}
