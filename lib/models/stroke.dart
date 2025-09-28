import 'dart:ui';

/// Parametric shape kinds (A3). Wave reserved for later implementation.
enum ShapeType { line, rectangle, circle, wave }

/// Metadata for a parametric shape stroke. If present, the stroke's rendered
/// appearance should be derived from these fields instead of the raw points
/// list. Points may remain empty or hold minimal anchor hints.
class ShapeMeta {
  const ShapeMeta({
    required this.type,
    required this.start,
    required this.end,
  });

  final ShapeType type;
  final Offset start;
  final Offset end;
  // Future: control points / wave frequency etc.
}

/// Supported drawing tools (A2 expanded). Some variants may be unused until
/// corresponding phases land.
enum ToolType { pencil, brush, eraser, eyedropper, bucket, shape }

/// Immutable stroke consisting of ordered points captured during a drag.
class Stroke {
  Stroke({
    required this.id,
    required this.color,
    required this.width,
    required List<Offset> points,
    required this.toolType,
    required this.timestamp,
    this.shapeMeta,
    this.blendMode,
  }) : _points = List.unmodifiable(points);

  final String id; // Could be uuid / increment.
  final Color color;
  final double width;
  final ToolType toolType;
  final DateTime timestamp;
  final List<Offset> _points;
  final ShapeMeta? shapeMeta; // Null => freehand stroke.
  final BlendMode? blendMode; // Used for eraser or future effects.

  /// Points making up the stroke path.
  List<Offset> get points => _points;

  bool get isDot => _points.length <= 1;
  bool get isShape => shapeMeta != null;
}
