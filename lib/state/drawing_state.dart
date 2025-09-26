import 'dart:developer' as dev;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../models/stroke.dart';
import '../tools/brush_tool.dart';
import '../tools/bucket_tool.dart';
import '../tools/eraser_tool.dart';
import '../tools/eyedropper_tool.dart';
import '../tools/pencil_tool.dart';
import '../tools/tool.dart';

/// Manages the collection of finalized strokes and an in‑progress stroke.
class DrawingState extends ChangeNotifier {
  DrawingState({List<Tool>? tools}) {
    // Initialize registry with provided tools or default set.
    final defaultTools = tools ??
        const [
          PencilTool(),
          BrushTool(),
          EraserTool(),
          EyedropperTool(),
          BucketTool(),
        ];
    for (final t in defaultTools) {
      _toolRegistry[t.type] = t;
    }
  }

  final List<Stroke> _strokes = [];
  final List<Stroke> _redo = [];
  Stroke? _inProgress;

  // Active drawing attributes (FR-08, FR-10)
  Color _currentColor = const Color(0xFF000000);
  double _currentWidth = 2.0;
  ToolType _activeTool = ToolType.pencil;
  final Map<ToolType, Tool> _toolRegistry = {};
  ToolType? _previousToolBeforeEyedropper; // For auto-revert after pick.
  // Pixel sampling (eyedropper) cache fields.
  GlobalKey? _canvasBoundaryKey;
  Uint8List? _cachedRgba; // RGBA byte buffer
  int _cachedWidth = 0;
  int _cachedHeight = 0;
  DateTime? _cachedAt;
  bool _samplingInProgress = false;
  // Stretch instrumentation counters
  int _strokeCount = 0;
  int _undoCount = 0;
  int _redoCount = 0;

  int get strokeCount => _strokeCount;
  int get undoCount => _undoCount;
  int get redoCount => _redoCount;

  Color get currentColor => _currentColor;
  double get currentWidth => _currentWidth;
  ToolType get activeTool => _activeTool;
  Tool? get activeToolInstance => _toolRegistry[_activeTool];
  List<ToolType> get availableTools =>
      _toolRegistry.keys.toList(growable: false);

  /// Finalized strokes (immutable outward view).
  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get inProgress => _inProgress;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  // For P0 we store temp mutable points for current stroke.
  final List<Offset> _currentPoints = [];

  /// Begins a new stroke with current pointer position.
  void startStroke(
    Offset point, {
    Color? color,
    double? width,
  }) {
    // For eraser strokes we still store a color (ignored) and rely on
    // toolType in the painter to apply BlendMode.clear. Keeping model simple.
    _currentPoints
      ..clear()
      ..add(point);
    _inProgress = Stroke(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      color: color ?? _currentColor,
      width: width ?? _currentWidth,
      points: List.of(_currentPoints),
      toolType: _activeTool,
      timestamp: DateTime.now(),
    );
    notifyListeners();
  }

  // --- Tool dispatch convenience wrappers (A2 refactor) ---
  void handlePointerStart(Offset p) {
    final tool = activeToolInstance;
    tool?.onStart(this, p);
  }

  void handlePointerUpdate(Offset p) {
    final tool = activeToolInstance;
    tool?.onUpdate(this, p);
  }

  void handlePointerEnd() {
    final tool = activeToolInstance;
    tool?.onEnd(this);
  }

  /// Attach the canvas boundary key so pixel sampling can snapshot.
  void attachCanvasBoundaryKey(GlobalKey key) {
    if (_canvasBoundaryKey != key) {
      _canvasBoundaryKey = key;
      _invalidateSampleCache();
    }
  }

  void _invalidateSampleCache() {
    _cachedRgba = null;
    _cachedAt = null;
  }

  /// Samples a pixel color at the given logical canvas coordinate.
  /// Uses a short-lived cached snapshot (default max age 500ms) to avoid
  /// repeated expensive `toImage()` calls while user is sampling.
  Future<Color?> samplePixel(Offset logicalPoint,
      {Duration cacheMaxAge = const Duration(milliseconds: 500)}) async {
    final key = _canvasBoundaryKey;
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    if (_samplingInProgress) {
      // If capture in progress, wait a tick and try using existing cache.
      await Future.delayed(const Duration(milliseconds: 16));
    }
    final now = DateTime.now();
    final cacheValid = _cachedRgba != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) <= cacheMaxAge;
    if (!cacheValid) {
      final ro = ctx.findRenderObject();
      if (ro is! RenderRepaintBoundary) return null;
      try {
        _samplingInProgress = true;
        // pixelRatio 1 ensures logical coordinates map 1:1 to pixels.
        final image = await ro.toImage(pixelRatio: 1.0);
        final byteData =
            await image.toByteData(format: ImageByteFormat.rawRgba);
        if (byteData == null) return null;
        _cachedRgba = byteData.buffer.asUint8List();
        _cachedWidth = image.width;
        _cachedHeight = image.height;
        _cachedAt = now;
      } finally {
        _samplingInProgress = false;
      }
    }
    final data = _cachedRgba;
    if (data == null) return null;
    final x = logicalPoint.dx.round();
    final y = logicalPoint.dy.round();
    if (x < 0 || y < 0 || x >= _cachedWidth || y >= _cachedHeight) return null;
    final index = (y * _cachedWidth + x) * 4;
    if (index + 3 >= data.length) return null;
    final r = data[index];
    final g = data[index + 1];
    final b = data[index + 2];
    final a = data[index + 3];
    // Ignore fully transparent pixels (treat as no color hit for eyedropper).
    if (a == 0) {
      dev.log('samplePixel transparent at ($x,$y)', name: 'eyedropper');
      return null;
    }
    final color = Color.fromARGB(a, r, g, b);
    dev.log(
      'samplePixel hit (${color.value.toRadixString(16)}) at ($x,$y) a=$a',
      name: 'eyedropper',
    );
    return color;
  }

  /// Appends a point if sufficiently distant to reduce noise.
  void appendPoint(Offset point, {double minDistance = 0.75}) {
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
    // New forward edit invalidates redo history (FR-06).
    _redo.clear();
    _inProgress = null;
    _currentPoints.clear();
    _strokeCount++;
    dev.log('stroke_added total=$_strokeCount', name: 'drawing');
    _invalidateSampleCache();
    notifyListeners();
  }

  /// Moves the most recent stroke to the redo stack (FR-07).
  void undo() {
    if (!canUndo) return;
    _redo.add(_strokes.removeLast());
    _undoCount++;
    dev.log('undo count=$_undoCount', name: 'drawing');
    _invalidateSampleCache();
    notifyListeners();
  }

  /// Clears all strokes and history (FR-17).
  void clear() {
    if (_strokes.isEmpty && _redo.isEmpty && _inProgress == null) return;
    _strokes.clear();
    _redo.clear();
    _currentPoints.clear();
    _inProgress = null;
    dev.log(
        'clear_all strokesCleared; totals strokes=$_strokeCount undo=$_undoCount redo=$_redoCount',
        name: 'drawing');
    _invalidateSampleCache();
    notifyListeners();
  }

  /// Restores the most recently undone stroke (FR-07).
  void redo() {
    if (!canRedo) return;
    _strokes.add(_redo.removeLast());
    _redoCount++;
    dev.log('redo count=$_redoCount', name: 'drawing');
    _invalidateSampleCache();
    notifyListeners();
  }

  /// Sets current drawing color.
  void setColor(Color color) {
    if (color == _currentColor) return;
    _currentColor = color;
    dev.log('color_changed value=${color.value.toRadixString(16)}',
        name: 'drawing');
    notifyListeners();
  }

  /// Sets current stroke width.
  void setWidth(double width) {
    if (width == _currentWidth) return;
    _currentWidth = width;
    dev.log('width_changed value=$width', name: 'drawing');
    notifyListeners();
  }

  /// Sets the active tool (A2 multi-tool support).
  void setActiveTool(ToolType tool) {
    if (tool == _activeTool) return;
    if (tool == ToolType.eyedropper && _activeTool != ToolType.eyedropper) {
      _previousToolBeforeEyedropper = _activeTool;
    }
    _activeTool = tool;
    dev.log('tool_changed value=${tool.name}', name: 'drawing');
    notifyListeners();
  }

  /// Reverts back to the previous non‑eyedropper tool after a color pick.
  void completeEyedropperSelection() {
    if (_activeTool == ToolType.eyedropper &&
        _previousToolBeforeEyedropper != null) {
      final revert = _previousToolBeforeEyedropper!;
      _previousToolBeforeEyedropper = null;
      _activeTool = revert;
      dev.log('tool_reverted_after_pick value=${revert.name}', name: 'drawing');
      notifyListeners();
    }
  }
}
