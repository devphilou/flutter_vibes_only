import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/drawing_state.dart';
import 'strings/app_strings.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/toolbar.dart';

/// Entry point for the Paint Vibes Only app.
void main() {
  runApp(const PaintVibesApp());
}

/// Root widget configuring theme & home screen.
class PaintVibesApp extends StatefulWidget {
  const PaintVibesApp({super.key});

  @override
  State<PaintVibesApp> createState() => _PaintVibesAppState();
}

class _PaintVibesAppState extends State<PaintVibesApp> {
  ThemeMode _mode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _mode = switch (_mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
  }

  String _themeLabel() => switch (_mode) {
        ThemeMode.system => AppStrings.themeSystem,
        ThemeMode.light => AppStrings.themeLight,
        ThemeMode.dark => AppStrings.themeDark,
      };

  IconData _themeIcon() => switch (_mode) {
        ThemeMode.system => Icons.brightness_auto,
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: _DrawingScreen(
        onToggleTheme: _toggleTheme,
        themeIcon: _themeIcon(),
        themeLabel: _themeLabel(),
      ),
    );
  }
}

/// Temporary home screen hosting the drawing canvas (Phase P0).
class _DrawingScreen extends StatefulWidget {
  const _DrawingScreen({
    required this.onToggleTheme,
    required this.themeIcon,
    required this.themeLabel,
  });

  final VoidCallback onToggleTheme;
  final IconData themeIcon;
  final String themeLabel;

  @override
  State<_DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<_DrawingScreen> {
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
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            tooltip: '${AppStrings.themeToggle}: ${widget.themeLabel}',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.themeIcon, semanticLabel: AppStrings.themeToggle),
          ),
        ],
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
