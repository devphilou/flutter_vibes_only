import 'dart:ui';

import 'stroke.dart';

/// Current persisted document format version.
const int currentDocumentVersion = 2; // A1: adds basic expansion hooks.

/// A persisted drawing composed of strokes and metadata.
class DrawingDocument {
  DrawingDocument({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.strokes,
    this.metadata = const {},
    this.version = currentDocumentVersion,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Stroke> strokes;
  final Map<String, Object?> metadata;
  final int version;

  DrawingDocument copyWith({
    List<Stroke>? strokes,
    Map<String, Object?>? metadata,
    DateTime? updatedAt,
  }) =>
      DrawingDocument(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        strokes: strokes ?? this.strokes,
        metadata: metadata ?? this.metadata,
        version: version,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'version': version,
        'metadata': metadata,
        'strokes': strokes
            .map((s) => {
                  'id': s.id,
                  'color': s.color.value,
                  'width': s.width,
                  'tool': s.toolType.name,
                  'timestamp': s.timestamp.toIso8601String(),
                  'points': s.points
                      .map((p) =>
                          [p.dx.toStringAsFixed(2), p.dy.toStringAsFixed(2)])
                      .toList(),
                  if (s.shapeMeta != null)
                    'shape': {
                      'type': s.shapeMeta!.type.name,
                      'start': [
                        s.shapeMeta!.start.dx.toStringAsFixed(2),
                        s.shapeMeta!.start.dy.toStringAsFixed(2),
                      ],
                      'end': [
                        s.shapeMeta!.end.dx.toStringAsFixed(2),
                        s.shapeMeta!.end.dy.toStringAsFixed(2),
                      ],
                    },
                  if (s.blendMode != null) 'blendMode': s.blendMode!.index,
                })
            .toList(),
      };

  static DrawingDocument fromJson(Map<String, dynamic> json) {
    final version = (json['version'] as int?) ?? 1;
    // Future: migration steps based on version.
    final strokesJson = json['strokes'] as List<dynamic>? ?? [];
    return DrawingDocument(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: version,
      metadata: (json['metadata'] as Map?)?.cast<String, Object?>() ?? const {},
      strokes: strokesJson.map((s) {
        final pts = (s['points'] as List<dynamic>).map((pair) {
          final list = pair as List<dynamic>;
          return Offset(double.parse(list[0]), double.parse(list[1]));
        }).toList();
        return Stroke(
          id: s['id'] as String,
          color: Color(s['color'] as int),
          width: (s['width'] as num).toDouble(),
          points: pts,
          toolType: ToolType.values.firstWhere(
            (t) => t.name == (s['tool'] as String? ?? 'pencil'),
            orElse: () => ToolType.pencil,
          ),
          timestamp: DateTime.parse(s['timestamp'] as String),
          shapeMeta: _parseShapeMeta(s['shape']),
          blendMode: _parseBlendMode(s['blendMode']),
        );
      }).toList(),
    );
  }

  static ShapeMeta? _parseShapeMeta(dynamic json) {
    if (json == null) return null;
    try {
      final map = json as Map<String, dynamic>;
      final typeStr = map['type'] as String?;
      if (typeStr == null) return null;
      final type = ShapeType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => ShapeType.line,
      );
      Offset _toOffset(List<dynamic> arr) => Offset(
          double.parse(arr[0].toString()), double.parse(arr[1].toString()));
      final start = _toOffset(map['start'] as List<dynamic>);
      final end = _toOffset(map['end'] as List<dynamic>);
      return ShapeMeta(type: type, start: start, end: end);
    } catch (_) {
      return null; // Corrupted shape meta gracefully ignored.
    }
  }

  static BlendMode? _parseBlendMode(dynamic raw) {
    if (raw == null) return null;
    if (raw is int && raw >= 0 && raw < BlendMode.values.length) {
      return BlendMode.values[raw];
    }
    return null;
  }
}
