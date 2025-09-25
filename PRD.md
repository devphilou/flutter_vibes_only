# Paint Vibes Only – MVP Product Requirements Document (PRD)

## 1. Overview

Paint Vibes Only is a lightweight, browser‑based Flutter drawing app focused on creativity, approachability, and fast iteration. The MVP targets hackathon usability and future extensibility for multi‑platform (web first, later mobile/desktop). This PRD captures scope, success criteria, and guardrails for the initial public MVP.

## 2. Goals (MVP)

1. Let users freely draw with a basic tool on a blank canvas in the browser.
2. Provide intuitive color selection (predefined palette) and stroke width that “just works.”
3. Support undo/redo (at least 1 step each direction, ideally full history for the session).
4. Allow clearing the canvas with a confirmation pattern that prevents accidental loss.
5. Enable saving/exporting the current drawing (download as PNG) using in‑memory operations only.
6. Keep UI friction low: no authentication, no backend.
7. Maintain solid performance (smooth strokes) on typical laptops and tablets.

## 3. Non‑Goals (MVP)

- No persistent cloud storage or user accounts.
- No advanced editing (layers, selection tools, transforms).
- No custom color picker beyond fixed palette in first drop.
- No multi‑page project/gallery persistence (may come next).
- No shape tools, eraser blending, flood fill, or eyedropper (future roadmap).
- No collaboration / multiplayer.

## 4. Target Users & Personas

| Persona                     | Description                         | Key Needs                                          |
| --------------------------- | ----------------------------------- | -------------------------------------------------- |
| Casual Creator              | Wants to doodle quickly in browser. | Instant draw, undo mistakes, save a result.        |
| Workshop Participant        | Following guided session.           | Clear affordances, predictable behavior.           |
| Future Extender (Developer) | Might fork project.                 | Clean architecture, simple models, easy extension. |

## 5. Core User Stories (MVP)

1. As a user, I can draw continuous strokes with my mouse (or touch) so I can sketch ideas.
2. As a user, I can pick a color from a palette so I can vary my drawing.
3. As a user, I can adjust stroke width (basic small/medium/large) to emphasize parts of my drawing. (Optional stretch if time: simple slider.)
4. As a user, I can undo my last stroke so I can correct errors.
5. As a user, I can redo an undone stroke in case I change my mind.
6. As a user, I can clear the whole canvas (with a confirm step) so I can start over.
7. As a user, I can save/export my drawing as a PNG so I can share it.
8. As a user, I always see tool state (current color, width) so I feel in control.

## 6. Functional Requirements

### 6.1 Drawing

- FR-01: Pointer down starts a stroke; pointer move appends points; pointer up finalizes stroke.
- FR-02: Strokes render in the order they were completed.
- FR-03: Ignore extremely tiny strokes (< 2 px total movement) to avoid noise unless intentional dot (tap) — treat simple tap as a dot stroke.

### 6.2 Stroke Model

- FR-04: Stroke stores: color, width, list of points (or Path), timestamp, id (UUID or increment), toolType (enum: pencil for now).

### 6.3 State Management

- FR-05: Use a `ChangeNotifier` (`DrawingState`) with `List<Stroke>` and `redoStack`.
- FR-06: Adding a new stroke clears `redoStack`.
- FR-07: Undo moves last stroke to `redoStack`; redo moves last from `redoStack` back to strokes list.

### 6.4 Color Palette

- FR-08: Provide a fixed list (e.g., 8–10) accessible colors with sufficient contrast for UI swatches.
- FR-09: Active color visually highlighted (outline or selection ring, accessible label e.g., “Selected color red”).

### 6.5 Stroke Width

- FR-10: Provide 3 discrete presets (e.g., 2, 5, 10 px) with selected state.
- FR-11 (Stretch): Optional slider (min 1– max 24 px). If implemented, maintain last chosen width across session.

### 6.6 Canvas

- FR-12: Canvas resizes responsively; preserves strokes without distortion (no scaling on resize — fixed logical coordinate system based on current size at draw time). If resizing causes mismatch, future enhancement: scaling transform.
- FR-13: Wrapped in a `RepaintBoundary` for export.

### 6.7 Undo / Redo

- FR-14: Disable (visually) undo button when no strokes exist; disable redo when redo stack empty.
- FR-15: Keyboard shortcuts (web): `Ctrl+Z` / `Cmd+Z` undo; `Shift+Ctrl+Z` / `Shift+Cmd+Z` redo (if time permits). Non-blocking stretch.

### 6.8 Clear Canvas

- FR-16: Clear action triggers a confirm modal/snackbar (“Clear all? Undo history will be lost”).
- FR-17: On confirm: both stacks emptied.

### 6.9 Export / Save

- FR-18: Export current canvas to PNG using `toImage()`; trigger browser download (`<a download>`). Filename pattern: `vibes_<yyyyMMdd_HHmmss>.png`.
- FR-19: Only include visible strokes; no hidden layers.
- FR-20 (Stretch): Provide resolution scaling multiplier (1x default). Not required for MVP.

### 6.10 Accessibility & Semantics

- FR-21: All interactive controls have semantic labels (Undo, Redo, Save, Color: Red, etc.).
- FR-22: Buttons minimum 48×48 logical pixels.
- FR-23: Focus order logical; visible focus highlight.

### 6.11 Error Handling

- FR-24: If export fails (exception), show non-blocking error snackbar with retry option.
- FR-25: Guard against null pointer or disposed state in asynchronous export.

### 6.12 Performance

- FR-26: Maintain > 50 FPS while drawing up to 500 strokes (each ≤ 200 points) on a typical laptop (approx; manual spot check).
- FR-27: Debounce rebuilds: only repaint on pointer events / state changes; avoid setState in deep widget tree when `CustomPainter` suffices.

### 6.13 Theming

- FR-28: Support light & dark theme toggle (optional stretch) else auto theme based on system brightness.

### 6.14 Layout / Responsiveness

- FR-29: Toolbar adapts: horizontal top (desktop width ≥ 800 px), collapsible or scrollable row on narrow screens.
- FR-30: Content centers; canvas grows to available remainder with safe minimum (e.g., 300×300).

### 6.15 Instrumentation (Internal Only – Optional Stretch)

- FR-31: Basic counters (strokes drawn, undos performed) logged with `dart:developer log` for debugging.

## 7. Acceptance Criteria (Representative)

| Story         | Criteria                                                                                               |
| ------------- | ------------------------------------------------------------------------------------------------------ |
| Draw stroke   | Press+drag draws continuous line with selected color & width; releasing finalizes it; undo removes it. |
| Undo/Redo     | After drawing 2 strokes: undo once hides 2nd, redo restores it. Buttons correct enabled states.        |
| Clear         | After confirm, canvas blank; undo disabled.                                                            |
| Export        | Downloaded PNG opens and visually matches canvas contents.                                             |
| Performance   | Drawing remains smooth with rapid scribbles; no jank > ~150ms frame spikes (observed manually).        |
| Accessibility | All buttons reachable via Tab; active focus ring visible; screen reader reads labels.                  |

## 8. UX Flow (High-Level)

1. Load app → initial canvas + toolbar.
2. User selects a color (default preselected).
3. User optionally chooses stroke width.
4. User draws multiple strokes.
5. User undoes mistakes (and redoes if needed).
6. User saves export (browser download starts).
7. User may clear canvas and continue.

## 9. Information Architecture / UI Components

- App Scaffold
  - Top AppBar (logo/title optional) + actions row OR side panel (future)
  - Toolbar Row: ColorPalette, StrokeWidthSelector, UndoBtn, RedoBtn, ClearBtn, SaveBtn
  - CanvasArea (GestureDetector + RepaintBoundary + CustomPaint)
  - Optional: Theme toggle (stretch)

## 10. Data Model (Initial)

```dart
enum ToolType { pencil }

class Stroke {
  Stroke({
    required this.id,
    required this.color,
    required this.width,
    required this.points,
    required this.toolType,
    required this.timestamp,
  });
  final String id; // uuid
  final Color color;
  final double width;
  final List<Offset> points; // sequential path points
  final ToolType toolType;
  final DateTime timestamp;
}
```

### Future Model Hooks

- Add `blendMode` (for eraser) later.
- Add `fill` or `shapeMeta` for shape tools.

## 11. State Management Approach

- Single `DrawingState extends ChangeNotifier` providing:
  - `List<Stroke> _strokes; List<Stroke> _redo; Stroke? inProgress;`
  - Methods: `startStroke()`, `appendPoint()`, `endStroke()`, `undo()`, `redo()`, `clear()`, `exportImage()`.
- UI subscribes via `AnimatedBuilder` / `ListenableBuilder` or `ValueListenableBuilder` pattern.
- Keep export logic inside a helper function, returning `(ui.Image, Uint8List)` pair for potential reuse.

## 12. Technical Architecture

| Layer                     | Responsibility                                               |
| ------------------------- | ------------------------------------------------------------ |
| Widgets                   | Present controls / capture gestures.                         |
| State (ChangeNotifier)    | Business logic: stroke lifecycle, undo/redo.                 |
| Painter (`CustomPainter`) | Efficient rendering.                                         |
| Export Utility            | Convert `RepaintBoundary` to PNG bytes and trigger download. |

## 13. Non-Functional Requirements

| Category        | Requirement                                                  |
| --------------- | ------------------------------------------------------------ |
| Performance     | 50+ FPS typical drawing.                                     |
| Accessibility   | WCAG-ish focus + semantic labels.                            |
| Reliability     | No unhandled exceptions in normal flows.                     |
| Maintainability | < 300 LOC per major file; functions < 20 LOC when practical. |
| Compatibility   | Latest Chrome, Edge (desktop) at minimum 1024×600.           |
| Security        | No external network calls; no user data stored remotely.     |

## 14. Telemetry / Metrics (Manual for MVP)

- Manual inspection (DevTools performance) for frame timing.
- Log counts: strokes created, undos, exports.
- (Future) Add analytics opt-in if productized.

## 15. Risks & Mitigations

| Risk                                     | Impact      | Mitigation                                                      |
| ---------------------------------------- | ----------- | --------------------------------------------------------------- |
| Performance degradation with many points | Laggy UI    | Segment points (optionally downsample high-frequency moves).    |
| Export memory issues on huge canvas      | Crash/hang  | Limit max logical canvas size or show warning beyond threshold. |
| Accidental clear                         | Frustration | Confirmation UI + ESC to dismiss.                               |
| Accessibility overlooked                 | Exclusion   | Include focus + semantic labels early.                          |
| Scope creep                              | Delay       | Enforce strict MVP; backlog extras.                             |

## 16. Open Questions

1. Should we persist strokes to `localStorage` for session restore? (Currently NO for MVP.)
2. Minimum supported viewport size? (Assume 320 px width still workable.)
3. Provide a dark theme toggle or rely on system? (Leaning system for speed.)
4. Do we need PWA install prompt in MVP? (Deferred.)

## 17. Release Plan

| Phase                 | Scope                                        | Exit Criteria                  |
| --------------------- | -------------------------------------------- | ------------------------------ |
| P0 Foundation         | Drawing engine, stroke model, rendering      | Can draw & see strokes.        |
| P1 Interactivity      | Color palette, stroke widths                 | Can vary style.                |
| P2 History            | Undo/redo stacks                             | Undo/redo functional & stable. |
| P3 Export & Clear     | PNG export + clear confirm                   | File downloads; clearing safe. |
| P4 Polish             | Accessibility, responsive layout, minor perf | No critical usability gaps.    |
| P5 Stretch (Optional) | Theme toggle, keyboard shortcuts             | Added if time remains.         |

## 18. Out-of-Scope Backlog (Future Roadmap)

- Eyedropper tool
- Eraser (BlendMode.clear layer approach)
- Bucket fill (flood fill algorithm, maybe offloaded via `compute()`)
- Shape tools (circle, rectangle, wave, line)
- Recent drawings gallery (local persistence)
- Coloring book mode + progress tracking
- Multi-tab sync or collaboration
- Custom color picker + recent colors
- Layer management
- PWA offline-first mode

## 19. Definition of Done (MVP)

- All FR-01 through FR-19, FR-21–FR-24, FR-26, FR-29, FR-30 implemented (others marked stretch or deferred).
- No known crashers during normal usage (draw/undo/redo/clear/export) after manual test session.
- Lints pass using `flutter_lints` / project rules.
- README updated with run + export instructions.
- Basic widget test: drawing gesture adds stroke; undo removes it.

## 20. Success Metrics (Qualitative for MVP)

- Subjective: Users can learn features without guidance within 30 seconds.
- Exported image fidelity visually matches on-screen rendering.
- No noticeable input latency for standard doodling use case.

---

Prepared for: Flutter Web MVP build cycle
Maintainer: (Add name)
Date: 2025-09-25
Version: 1.0.0-MVP
