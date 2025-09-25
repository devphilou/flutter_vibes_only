# GitHub Copilot Instructions

These scoped instructions tailor Copilot's behavior for this Flutter project. Keep responses concise, actionable, and aligned with the rules below.

## Context

- Project: Flutter multi-platform (mobile, web, desktop) drawing/painting app (creative tools, canvas interactions, theming, state management).
- User: Knows general programming; may be new to Dart/Flutter specifics.
- Priority: Clean, performant, maintainable, idiomatic Dart + Flutter.
- Null safety is mandatory; avoid `!` unless logically guaranteed.

## Core Principles

1. Favor clarity over cleverness; small focused functions (< ~20 lines).
2. Immutability for data models; widgets are immutable unless stateful for a narrow purpose.
3. Composition over inheritance; break large `build` methods into private widgets.
4. SOLID adherence; single responsibility & explicit dependencies via constructors.
5. Exhaustive handling in `switch` statements / expressions.

## State Management

- Prefer built-in solutions first: `ValueNotifier`, `ChangeNotifier`, `ListenableBuilder`, `ValueListenableBuilder`.
- Use `ChangeNotifier` for shared drawing state (strokes list, undo stack, active tool, color).
- Only suggest third‑party state libraries if explicitly requested.
- Separate ephemeral UI state (hover, focus) from app/domain state (strokes, tools, theme mode).

## Data & Models

- Define a `Stroke` model (color, width, path/points, toolType).
- Consider using records only for lightweight tuple returns (e.g., `(ui.Image image, Uint8List bytes)`).
- Avoid premature abstraction; introduce repositories/services only if external persistence is added.

## Drawing / Canvas Guidance

- Use `CustomPainter` to render ordered strokes.
- For eraser: paint with `BlendMode.clear` on a layer if/when implemented.
- Undo/redo stacks: `List<Stroke> strokes`, `List<Stroke> redoStack`; clearing `redoStack` on any new forward edit.
- Wrap canvas in `RepaintBoundary` for export with `toImage()`.

## Error Handling & Logging

- Use `try/catch` with meaningful exceptions; never swallow errors silently.
- Use `dart:developer` `log()` for structured logging — not `print()`.
- Validate assumptions early (e.g., non-empty stroke paths) with asserts in debug builds.

## Coding Style

- Follow Effective Dart and flutter_lints.
- Line length target: ≤ 80 chars where practical; wrap thoughtfully.
- Naming: PascalCase (types), camelCase (vars, funcs), snake_case (files).
- Prefer expression-bodied members for one-liners.
- Do not duplicate obvious comments; document rationale, not restatement.
- Provide `///` doc comments for all public APIs (classes, methods, top-level funcs, extensions) — first sentence a summary line.

## Theming & UI

- Use Material 3: `ColorScheme.fromSeed` for light & dark themes.
- Centralize theme in `main.dart` (or a `theme/` module if extended later).
- Encourage `const` constructors wherever possible for rebuild efficiency.
- Use accessible color contrast (≥ 4.5:1 normal text, 3:1 large text).
- Factor reusable stylings into Theme extensions if non-standard.

## Layout & Performance

- Avoid layout thrash: reuse painters & keys where appropriate.
- Use `LayoutBuilder` / `MediaQuery` for responsive sizing (especially web/desktop canvas sizing).
- Defer expensive operations off the UI thread via `compute()` if they become heavy (e.g., future flood fill, image processing).

## Dependencies

- Default to zero new packages unless a user explicitly requests (e.g., `go_router`, `google_fonts`).
- When suggesting a package: justify briefly (why & benefit). Avoid over‑engineering.

## Navigation

- For multi-screen expansion, recommend `go_router` with declarative routes and deep-link support.
- For the MVP single screen, keep a simple `MaterialApp(home: ...)`.

## Testing Guidance

- Encourage unit tests for undo/redo logic & stroke serialization/export.
- Widget tests: ensure canvas gestures produce strokes & undo updates UI.
- Use AAA (Arrange-Act-Assert) structure in examples.
- Avoid mocking if fakes suffice.

## Accessibility

- Provide semantic labels for tool buttons (Undo, Redo, Save, Clear, Color Picker).
- Ensure tappable areas are at least 48x48 logical pixels.
- Respect text scaling; avoid hardcoded font sizes without referencing `Theme.of(context).textTheme`.

## Security & Safety

- No dynamic code execution or network calls unless requested.
- Do not embed secrets; assets declared in `pubspec.yaml` only.

## Response Style (For Copilot Suggestions)

- Provide concise, directly usable code blocks (complete widget/class definitions when helpful).
- Include brief inline comments only where intent is non-obvious.
- When asked "how" or "why", add a short rationale paragraph before code.
- If ambiguity exists, list 1–2 reasonable assumptions and proceed.
- If a request violates guidelines (e.g., add heavy dependency unnecessarily), gently suggest a lighter alternative.

## Prioritized Heuristics (In Order)

1. Correctness (null safety, logic, ordering).
2. Clarity & maintainability.
3. Performance (only optimize after correctness & clarity).
4. Extensibility (light future-proofing without over-abstraction).
5. Brevity (remove noise, keep meaningful structure).

## Common Code Patterns

### ChangeNotifier Skeleton

```dart
class DrawingState extends ChangeNotifier {
  DrawingState();

  final List<Stroke> _strokes = [];
  final List<Stroke> _redo = [];

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void addStroke(Stroke stroke) {
    _strokes.add(stroke);
    _redo.clear();
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(_strokes.removeLast());
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _strokes.add(_redo.removeLast());
    notifyListeners();
  }

  void clear() {
    if (_strokes.isEmpty && _redo.isEmpty) return;
    _strokes.clear();
    _redo.clear();
    notifyListeners();
  }
}
```

### CustomPainter Loop

```dart
class StrokesPainter extends CustomPainter {
  const StrokesPainter(this.strokes, this.inProgressStroke);

  final List<Stroke> strokes;
  final Stroke? inProgressStroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      canvas.drawPath(s.path, s.paint);
    }
    final ip = inProgressStroke;
    if (ip != null) canvas.drawPath(ip.path, ip.paint);
  }

  @override
  bool shouldRepaint(covariant StrokesPainter old) =>
      old.strokes != strokes || old.inProgressStroke != inProgressStroke;
}
```

## What NOT To Do

- Don't introduce heavy architecture (Bloc, Redux, etc.) unprompted.
- Don't add packages for trivial utilities available in SDK.
- Don't output partial code that cannot compile when full context is reasonable.
- Don't ignore accessibility, null safety, or error paths.

## When Unsure

- Present 2 concise options with trade-offs; recommend one.
- Ask a single clarifying question only if a critical blocker prevents progress.

## Expansion Hooks (Future Features)

- Coloring book mode: separate feature folder (`coloring/`) with persistence.
- Export/share: add repository layer if saving beyond in-memory/gallery.
- Shape tools: parametric stroke generation (rect/circle/wave) sharing Stroke model.

---

End of Copilot custom instructions.
