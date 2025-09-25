import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/stroke.dart';

/// Manages the collection of finalized strokes and an in‑progress stroke.
class DrawingState extends ChangeNotifier {
  DrawingState();

  final List<Stroke> _strokes = [];
  Stroke? _inProgress;

  /// Finalized strokes (immutable outward view).
  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get inProgress => _inProgress;

  // For P0 we store temp mutable points for current stroke.
  final List<Offset> _currentPoints = [];

  /// Begins a new stroke with current pointer position.
  void startStroke(
    Offset point, {
    Color color = const Color(0xFF000000),
    double width = 2.0,
  }) {
    _currentPoints
      ..clear()
      ..add(point);
    _inProgress = Stroke(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      color: color,
      width: width,
      points: List.of(_currentPoints),
      toolType: ToolType.pencil,
      timestamp: DateTime.now(),
    );
    notifyListeners();
  }

  /// Appends a point if sufficiently distant to reduce noise.
  void appendPoint(Offset point, {double minDistance = 0.5}) {
    if (_inProgress == null) return;
    final last = _currentPoints.isNotEmpty ? _currentPoints.last : null;
    if (last != null) {
      final d = (point - last).distance;
      if (d < minDistance) {
        return; // Skip micro movement.
      }
    }
    _currentPoints.add(point);
    // Recreate stroke with updated points (immutability outward).
    final s = _inProgress!;
    _inProgress = Stroke(
      id: s.id,
      color: s.color,
      width: s.width,
      points: List.of(_currentPoints),
      toolType: s.toolType,
      timestamp: s.timestamp,
    );
    notifyListeners();
  }

  /// Finalizes the in-progress stroke (or creates a dot stroke if tiny).
  void endStroke() {
    final stroke = _inProgress;
    if (stroke == null) return;

    // If movement was negligible treat as a dot by ensuring at least 1 point.
    if (stroke.points.length == 1) {
      // Duplicate the point to make rendering a short segment (dot).
      final p = stroke.points.first;
      _currentPoints.add(p + const Offset(0.01, 0.01));
    }

    _strokes.add(
      Stroke(
        id: stroke.id,
        color: stroke.color,
        width: stroke.width,
        points: List.of(_currentPoints),
        toolType: stroke.toolType,
        timestamp: stroke.timestamp,
      ),
    );
    _inProgress = null;
    _currentPoints.clear();
    notifyListeners();
  }
}
