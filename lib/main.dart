import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repository/drawing_repository.dart';
import 'repository/in_memory_repository.dart';
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
  static const _themePrefKey = 'theme_mode';

  @override
  void initState() {
    super.initState();
    _router = createRouter(navigatorKey: _navKey);
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_themePrefKey);
      if (value != null) {
        setState(() {
          _mode = ThemeMode.values.firstWhere(
            (m) => m.name == value,
            orElse: () => ThemeMode.system,
          );
        });
      }
    } catch (_) {
      // Non-fatal: ignore failures.
    }
  }

  void _cycleTheme() {
    setState(() {
      _mode = switch (_mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
    // Persist asynchronously.
    SharedPreferences.getInstance()
        .then((p) => p.setString(_themePrefKey, _mode.name));
  }

  @override
  Widget build(BuildContext context) {
    final repo = InMemoryDrawingRepository();
    return ThemeController(
      mode: _mode,
      cycle: _cycleTheme,
      child: AppServices(
        repository: repo,
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
        ),
      ),
    );
  }
}

/// Inherited controller giving descendants access to theme toggling while a
/// more persistent settings system is prepared in A1 persistence work.
class ThemeController extends InheritedWidget {
  const ThemeController({
    required this.mode,
    required this.cycle,
    required super.child,
  });

  final ThemeMode mode;
  final VoidCallback cycle;

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeController>()!;

  @override
  bool updateShouldNotify(covariant ThemeController oldWidget) =>
      oldWidget.mode != mode;
}

/// Provides access to application-wide services (repository now, more later).
class AppServices extends InheritedWidget {
  const AppServices({
    required this.repository,
    required super.child,
    super.key,
  });

  final DrawingRepository repository;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServices>()!;

  @override
  bool updateShouldNotify(covariant AppServices oldWidget) => false;
}
