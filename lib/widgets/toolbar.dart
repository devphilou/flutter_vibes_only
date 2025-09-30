import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../services/download_helper_stub.dart'
    if (dart.library.html) '../services/download_helper_web.dart';
import '../services/export_service.dart';
import '../state/drawing_state.dart';
import '../strings/app_strings.dart';
import '../utils/date_time_format.dart';
import 'app_asset_icon.dart';
import 'color_palette.dart';
import 'confirm_clear_dialog.dart';
import 'stroke_width_selector.dart';
import 'stroke_width_slider.dart';
import 'tool_selector.dart';

/// Toolbar for selecting color & stroke width (Phase P1). Undo/Redo/Export will
/// be added in later phases.
class DrawingToolbar extends StatelessWidget {
  const DrawingToolbar({
    super.key,
    required this.state,
    required this.canvasBoundaryKey,
  });

  final DrawingState state;
  final GlobalKey canvasBoundaryKey;

  static const _palette = <Color>[
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.white,
  ];

  static const _widths = <double>[2, 5, 10];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        // Responsive grouping: palette + widths wrap, action buttons stay in a row.
        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              // Tool selector (A2)
              ToolSelector(state: state),
              const SizedBox(width: 8),
              ColorPalette(
                colors: _palette,
                selected: state.currentColor,
                onSelected: state.setColor,
                recentColors: state.recentColors,
                onPickCustom: () async {
                  final c =
                      await _showSimpleColorDialog(context, state.currentColor);
                  if (c != null) state.setColor(c);
                },
              ),
              StrokeWidthSelector(
                widths: _widths,
                selectedWidth: state.currentWidth,
                onChanged: state.setWidth,
              ),
              // Stretch width slider (optional advanced control)
              StrokeWidthSlider(
                value: state.currentWidth,
                onChanged: state.setWidth,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconActionButton(
                    label: AppStrings.undo,
                    asset: AppAssets.undo,
                    enabled: state.canUndo,
                    onPressed: state.canUndo ? state.undo : null,
                  ),
                  _IconActionButton(
                    label: AppStrings.redo,
                    asset: AppAssets.redo,
                    enabled: state.canRedo,
                    onPressed: state.canRedo ? state.redo : null,
                  ),
                  _IconActionButton(
                    label: AppStrings.clear,
                    asset: AppAssets.clear,
                    enabled: state.canUndo,
                    onPressed: state.canUndo
                        ? () async {
                            final confirmed = await showConfirmClearDialog(
                              context,
                            );
                            if (confirmed == true) state.clear();
                          }
                        : null,
                  ),
                  Semantics(
                    label: AppStrings.save,
                    button: true,
                    enabled:
                        !(state.strokes.isEmpty && state.inProgress == null),
                    child: IconButton(
                      tooltip: AppStrings.save,
                      onPressed: state.strokes.isEmpty &&
                              state.inProgress == null
                          ? null
                          : () async {
                              try {
                                final bytes =
                                    await exportPng(canvasBoundaryKey);
                                final filename =
                                    timestampFileName(DateTime.now());
                                await triggerDownload(bytes, filename);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${AppStrings.savedPrefix} $filename'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                                debugPrint('export_success $filename');
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${AppStrings.exportFailed}: $e'),
                                    action: SnackBarAction(
                                      label: 'Retry',
                                      onPressed: () async {
                                        try {
                                          final bytes = await exportPng(
                                              canvasBoundaryKey);
                                          final filename =
                                              timestampFileName(DateTime.now());
                                          await triggerDownload(
                                              bytes, filename);
                                        } catch (_) {}
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.download,
                          semanticLabel: AppStrings.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<Color?> _showSimpleColorDialog(
    BuildContext context, Color initial) async {
  Color temp = initial;
  return showDialog<Color>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pick Color'),
        content: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: temp.red.toDouble(),
                max: 255,
                label: 'R ${temp.red}',
                onChanged: (v) {
                  temp = temp.withRed(v.toInt());
                  (context as Element).markNeedsBuild();
                },
              ),
              Slider(
                value: temp.green.toDouble(),
                max: 255,
                label: 'G ${temp.green}',
                onChanged: (v) {
                  temp = temp.withGreen(v.toInt());
                  (context as Element).markNeedsBuild();
                },
              ),
              Slider(
                value: temp.blue.toDouble(),
                max: 255,
                label: 'B ${temp.blue}',
                onChanged: (v) {
                  temp = temp.withBlue(v.toInt());
                  (context as Element).markNeedsBuild();
                },
              ),
              Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: temp,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(temp),
            child: const Text('Select'),
          ),
        ],
      );
    },
  );
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.label,
    required this.asset,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String asset;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: IconButton(
        tooltip: label,
        onPressed: enabled ? onPressed : null,
        icon: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: AppAssetIcon(
            asset,
            size: 24,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}
