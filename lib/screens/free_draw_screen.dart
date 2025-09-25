import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/drawing_state.dart';
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

  @override
  void initState() {
    super.initState();
    _drawingState = DrawingState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Draw'),
      ),
      body: Shortcuts(
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
          },
          child: Focus(
            autofocus: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
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
                                  color: Theme.of(context).colorScheme.surface,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}
