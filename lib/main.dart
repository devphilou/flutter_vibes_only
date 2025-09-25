import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routing/app_router.dart';
import 'strings/app_strings.dart';

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
  late final GoRouter _router;
  final _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _router = createRouter(navigatorKey: _navKey);
  }

  void _cycleTheme() {
    setState(() {
      _mode = switch (_mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeController(
      mode: _mode,
      cycle: _cycleTheme,
      child: MaterialApp.router(
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
        routerConfig: _router,
        builder: (context, child) {
          final controller = _ThemeController.of(context);
          return Scaffold(
            body: child,
            floatingActionButton: FloatingActionButton(
              tooltip: 'Cycle Theme',
              onPressed: controller.cycle,
              child: const Icon(Icons.brightness_6),
            ),
          );
        },
      ),
    );
  }
}

/// Inherited controller giving descendants access to theme toggling while a
/// more persistent settings system is prepared in A1 persistence work.
class _ThemeController extends InheritedWidget {
  const _ThemeController({
    required this.mode,
    required this.cycle,
    required super.child,
  });

  final ThemeMode mode;
  final VoidCallback cycle;

  static _ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ThemeController>()!;

  @override
  bool updateShouldNotify(covariant _ThemeController oldWidget) =>
      oldWidget.mode != mode;
}
