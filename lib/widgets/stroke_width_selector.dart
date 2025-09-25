import 'package:flutter/material.dart';

/// Selects among a few preset stroke widths (FR-10).
class StrokeWidthSelector extends StatelessWidget {
  const StrokeWidthSelector({
    super.key,
    required this.widths,
    required this.selectedWidth,
    required this.onChanged,
  });

  final List<double> widths;
  final double selectedWidth;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final w in widths)
          _WidthChip(
            width: w,
            selected: w == selectedWidth,
            onTap: () => onChanged(w),
          ),
      ],
    );
  }
}

class _WidthChip extends StatelessWidget {
  const _WidthChip({
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label:
          'Stroke width ${width.toStringAsFixed(0)}${selected ? ' (selected)' : ''}',
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? color : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Container(
                width: width,
                height: width,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
