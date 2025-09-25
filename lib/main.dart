import 'package:flutter/material.dart';

import 'state/drawing_state.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/toolbar.dart';

/// Entry point for the Paint Vibes Only app.
void main() {
  runApp(const PaintVibesApp());
}

/// Root widget configuring theme & home screen.
class PaintVibesApp extends StatelessWidget {
  const PaintVibesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paint Vibes Only',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _DrawingScreen(),
    );
  }
}

/// Temporary home screen hosting the drawing canvas (Phase P0).
class _DrawingScreen extends StatefulWidget {
  const _DrawingScreen();

  @override
  State<_DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<_DrawingScreen> {
  late final DrawingState _drawingState;

  @override
  void initState() {
    super.initState();
    _drawingState = DrawingState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paint Vibes Only')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DrawingToolbar(state: _drawingState),
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
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: DrawingCanvas(state: _drawingState),
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
    );
  }
}
