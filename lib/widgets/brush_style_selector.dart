import 'package:flutter/material.dart';

import '../state/drawing_state.dart';

/// Selector for brush style variants (A4).
class BrushStyleSelector extends StatelessWidget {
  const BrushStyleSelector({super.key, required this.state});

  final DrawingState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final style in BrushStyle.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _BrushStyleChip(
                  style: style,
                  selected: state.brushStyle == style,
                  onTap: () => state.setBrushStyle(style),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BrushStyleChip extends StatelessWidget {
  const _BrushStyleChip({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final BrushStyle style;
  final bool selected;
  final VoidCallback onTap;

  String get _label => switch (style) {
        BrushStyle.standard => 'Std',
        BrushStyle.soft => 'Soft',
        BrushStyle.calligraphic => 'Calli',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = 'Brush style ${_label}${selected ? ' (selected)' : ''}';
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Center(
            child: Text(
              _label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
