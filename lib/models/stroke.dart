import 'dart:ui';

/// Supported drawing tools (A2 expanded). Some variants may be unused until
/// corresponding phases land.
enum ToolType { pencil, brush, eraser, eyedropper, bucket }

/// Immutable stroke consisting of ordered points captured during a drag.
class Stroke {
  Stroke({
    required this.id,
    required this.color,
    required this.width,
    required List<Offset> points,
    required this.toolType,
    required this.timestamp,
  }) : _points = List.unmodifiable(points);

  final String id; // Could be uuid / increment.
  final Color color;
  final double width;
  final ToolType toolType;
  final DateTime timestamp;
  final List<Offset> _points;

  /// Points making up the stroke path.
  List<Offset> get points => _points;

  bool get isDot => _points.length <= 1;
}
