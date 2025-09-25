import 'package:flutter/material.dart';

import '../strings/app_strings.dart';

/// Stretch widget: adjustable stroke width slider (FR-11).
class StrokeWidthSlider extends StatelessWidget {
  const StrokeWidthSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 24,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${AppStrings.widthSliderLabel} current ${value.toStringAsFixed(0)}',
      slider: true,
      child: SizedBox(
        width: 150,
        child: Row(
          children: [
            Expanded(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                label: value.toStringAsFixed(0),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
