import 'package:flutter/material.dart';

import '../state/drawing_state.dart';
import 'color_palette.dart';
import 'stroke_width_selector.dart';

/// Toolbar for selecting color & stroke width (Phase P1). Undo/Redo/Export will
/// be added in later phases.
class DrawingToolbar extends StatelessWidget {
  const DrawingToolbar({super.key, required this.state});

  final DrawingState state;

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
          ],
        );
      },
    );
  }
}
