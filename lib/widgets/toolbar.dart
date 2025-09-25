import 'package:flutter/material.dart';

import '../services/download_helper_stub.dart'
    if (dart.library.html) '../services/download_helper_web.dart';
import '../services/export_service.dart';
import '../state/drawing_state.dart';
import '../utils/date_time_format.dart';
import 'color_palette.dart';
import 'confirm_clear_dialog.dart';
import 'stroke_width_selector.dart';

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
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 16,
          children: [
            ColorPalette(
              colors: _palette,
              selected: state.currentColor,
              onSelected: state.setColor,
            ),
            StrokeWidthSelector(
              widths: _widths,
              selectedWidth: state.currentWidth,
              onChanged: state.setWidth,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Undo',
                  onPressed: state.canUndo ? state.undo : null,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: 'Redo',
                  onPressed: state.canRedo ? state.redo : null,
                  icon: const Icon(Icons.redo),
                ),
                IconButton(
                  tooltip: 'Clear',
                  onPressed: state.canUndo
                      ? () async {
                          final confirmed = await showConfirmClearDialog(
                            context,
                          );
                          if (confirmed == true) state.clear();
                        }
                      : null,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: 'Save',
                  onPressed: state.strokes.isEmpty && state.inProgress == null
                      ? null
                      : () async {
                          try {
                            final bytes = await exportPng(canvasBoundaryKey);
                            final filename = timestampFileName(DateTime.now());
                            await triggerDownload(bytes, filename);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Saved $filename'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Export failed: $e'),
                                action: SnackBarAction(
                                  label: 'Retry',
                                  onPressed: () async {
                                    try {
                                      final bytes =
                                          await exportPng(canvasBoundaryKey);
                                      final filename =
                                          timestampFileName(DateTime.now());
                                      await triggerDownload(bytes, filename);
                                    } catch (_) {}
                                  },
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.download),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
