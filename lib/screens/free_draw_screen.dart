import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets/app_assets.dart';
import '../main.dart';
import '../models/drawing_document.dart';
import '../models/stroke.dart';
import '../repository/drawing_repository.dart';
import '../state/drawing_state.dart';
import '../widgets/app_asset_icon.dart';
import '../widgets/brush_style_selector.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/toolbar.dart';

/// Free draw screen hosting canvas + toolbar.
class FreeDrawScreen extends StatefulWidget {
  const FreeDrawScreen({super.key});

  @override
  State<FreeDrawScreen> createState() => _FreeDrawScreenState();
}

class _FreeDrawScreenState extends State<FreeDrawScreen> {
  late final DrawingState _drawingState;
  final GlobalKey _canvasKey = GlobalKey();
  DrawingDocument? _document;
  late final DrawingRepository _repo; // Assigned in didChangeDependencies.
  bool _loading = true;
  bool _repoInitialized = false;
  bool _shiftDown = false; // Track Shift for shape constraints.

  @override
  void initState() {
    super.initState();
    _drawingState = DrawingState();
    // Listen for stroke finalization to auto-save.
    _drawingState.addListener(_maybePersist);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repoInitialized) return;
    _repoInitialized = true;
    _repo = AppServices.of(context).repository;
    // Async load/create after dependencies are available.
    () async {
      final id = await _repo.createEmpty();
      final doc = await _repo.load(id);
      if (!mounted) return;
      setState(() {
        _document = doc;
        _loading = false;
      });
      // If user already drew strokes before doc ready, persist them now.
      _maybePersist();
    }();
  }

  void _maybePersist() {
    // Simple heuristic: whenever no inProgress and strokes length changed vs doc.
    final doc = _document;
    if (doc == null) return;
    if (_drawingState.inProgress != null) return;
    if (doc.strokes.length == _drawingState.strokes.length) return;
    final updated = doc.copyWith(strokes: _drawingState.strokes);
    _repo.save(updated);
    _document = updated; // Keep in memory.
  }

  @override
  void dispose() {
    _drawingState.removeListener(_maybePersist);
    _maybePersist();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Free Draw'),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          final isShift = event.isShiftPressed;
          if (isShift != _shiftDown) {
            _shiftDown = isShift;
            _drawingState.setConstrainShape(isShift);
          }
        },
        child: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ):
                const _UndoIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
                const _UndoIntent(),
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift,
                LogicalKeyboardKey.keyZ): const _RedoIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
                LogicalKeyboardKey.keyZ): const _RedoIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
                const _RedoIntent(),
            // Shape tool switching (L=line, R=rectangle, C=circle, W=wave)
            LogicalKeySet(LogicalKeyboardKey.keyL):
                const _ShapeTypeIntent(ShapeType.line),
            LogicalKeySet(LogicalKeyboardKey.keyR):
                const _ShapeTypeIntent(ShapeType.rectangle),
            LogicalKeySet(LogicalKeyboardKey.keyC):
                const _ShapeTypeIntent(ShapeType.circle),
            LogicalKeySet(LogicalKeyboardKey.keyW):
                const _ShapeTypeIntent(ShapeType.wave),
            // Escape cancels preview shape.
            LogicalKeySet(LogicalKeyboardKey.escape):
                const _CancelShapeIntent(),
            LogicalKeySet(LogicalKeyboardKey.tab): const _CycleShapeIntent(),
          },
          child: Actions(
            actions: {
              _UndoIntent: CallbackAction<_UndoIntent>(
                onInvoke: (intent) {
                  if (_drawingState.canUndo) _drawingState.undo();
                  return null;
                },
              ),
              _RedoIntent: CallbackAction<_RedoIntent>(
                onInvoke: (intent) {
                  if (_drawingState.canRedo) _drawingState.redo();
                  return null;
                },
              ),
              _ShapeTypeIntent: CallbackAction<_ShapeTypeIntent>(
                onInvoke: (intent) {
                  _drawingState.setActiveTool(ToolType.shape);
                  if (intent.type != null) {
                    _drawingState.setSelectedShapeType(intent.type!);
                  }
                  return null;
                },
              ),
              _CancelShapeIntent: CallbackAction<_CancelShapeIntent>(
                onInvoke: (intent) {
                  _drawingState.cancelShape();
                  return null;
                },
              ),
              _CycleShapeIntent: CallbackAction<_CycleShapeIntent>(
                onInvoke: (intent) {
                  if (_drawingState.activeTool != ToolType.shape) {
                    _drawingState.setActiveTool(ToolType.shape);
                  }
                  final values = ShapeType.values;
                  final idx = values.indexOf(_drawingState.selectedShapeType);
                  final next = values[(idx + 1) % values.length];
                  _drawingState.setSelectedShapeType(next);
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return AnimatedBuilder(
                    animation: _drawingState,
                    builder: (context, _) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DrawingToolbar(
                                state: _drawingState,
                                canvasBoundaryKey: _canvasKey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Fixed-height option bar to avoid canvas resize jumps
                            SizedBox(
                              height:
                                  56, // aligns with 48 min control + padding
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                layoutBuilder:
                                    (currentChild, previousChildren) {
                                  return Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  );
                                },
                                child: _buildOptionsBarContent(_drawingState),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 300,
                                    minHeight: 300,
                                    maxWidth: 1200,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant,
                                        ),
                                      ),
                                      child: DrawingCanvas(
                                        state: _drawingState,
                                        boundaryKey: _canvasKey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsBarContent(DrawingState state) {
    // Show appropriate secondary option controls; keep empty box otherwise.
    if (state.activeTool == ToolType.shape) {
      return Align(
        alignment: Alignment.centerLeft,
        key: const ValueKey('shape-options'),
        child: _ShapeTypeOptions(state: state),
      );
    }
    if (state.activeTool == ToolType.brush) {
      return Align(
        alignment: Alignment.centerLeft,
        key: const ValueKey('brush-options'),
        child: BrushStyleSelector(state: state),
      );
    }
    return const SizedBox(key: ValueKey('empty-options'));
  }
}

// Intents for keyboard shape selection and cancel.
class _ShapeTypeIntent extends Intent {
  const _ShapeTypeIntent(this.type);
  final ShapeType? type; // null could mean cycle in future.
}

class _CancelShapeIntent extends Intent {
  const _CancelShapeIntent();
}

class _CycleShapeIntent extends Intent {
  const _CycleShapeIntent();
}

// Shape type options row (used in reserved secondary bar)
class _ShapeTypeOptions extends StatelessWidget {
  const _ShapeTypeOptions({required this.state});
  final DrawingState state;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final s in ShapeType.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ShapeTypeChip(
                type: s,
                selected: state.selectedShapeType == s,
                onTap: () {
                  state.setActiveTool(ToolType.shape);
                  state.setSelectedShapeType(s);
                },
              ),
            ),
        ],
      );
}

class _ShapeTypeChip extends StatelessWidget {
  const _ShapeTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ShapeType type;
  final bool selected;
  final VoidCallback onTap;

  String get _label => switch (type) {
        ShapeType.line => 'Line',
        ShapeType.rectangle => 'Rectangle',
        ShapeType.circle => 'Circle',
        ShapeType.wave => 'Wave',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primaryContainer : cs.surfaceVariant;
    final borderColor = selected ? cs.primary : cs.outlineVariant;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    final semanticsLabel = 'Shape ${_label}${selected ? ' (selected)' : ''}';
    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Center(child: _icon(context, fg)),
        ),
      ),
    );
  }

  Widget _icon(BuildContext context, Color fg) {
    switch (type) {
      case ShapeType.rectangle:
        return AppAssetIcon(AppAssets.squareShape,
            size: 24, semanticLabel: _label);
      case ShapeType.circle:
        return AppAssetIcon(AppAssets.circleShape,
            size: 24, semanticLabel: _label);
      case ShapeType.wave:
        return AppAssetIcon(AppAssets.waveShape,
            size: 24, semanticLabel: _label);
      case ShapeType.line:
        // Simple drawn line since we have no asset for it.
        return SizedBox(
          width: 32,
          height: 24,
          child: CustomPaint(
            painter: _LineIconPainter(color: fg),
          ),
        );
    }
  }
}

class _LineIconPainter extends CustomPainter {
  const _LineIconPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(2, size.height - 2), Offset(size.width - 2, 2), paint);
  }

  @override
  bool shouldRepaint(covariant _LineIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}
