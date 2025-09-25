import 'package:flutter/material.dart';

/// Fixed color palette for MVP (FR-08, FR-09).
class ColorPalette extends StatelessWidget {
  const ColorPalette({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in colors)
          _ColorSwatch(
            color: c,
            selected: c.value == selected.value,
            onTap: () => onSelected(c),
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).dividerColor;
    final label = 'Color: ${_semanticName(color)}'
        '${selected ? ' (selected)' : ''}';
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: FocusableActionDetector(
        onShowHoverHighlight: (_) {},
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticName(Color c) {
    if (c == Colors.black) return 'Black';
    if (c == Colors.white) return 'White';
    if (c == Colors.red) return 'Red';
    if (c == Colors.green) return 'Green';
    if (c == Colors.blue) return 'Blue';
    if (c == Colors.yellow) return 'Yellow';
    if (c == Colors.orange) return 'Orange';
    if (c == Colors.purple) return 'Purple';
    return 'Color';
  }
}
