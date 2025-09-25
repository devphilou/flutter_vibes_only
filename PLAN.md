# Paint Vibes Only – Implementation Plan (MVP)

This plan operationalizes the MVP requirements defined in `PRD.md`. It breaks delivery into small, verifiable steps mapped to Functional Requirements (FR) and includes a final consolidated checklist.

---

## 1. Architecture & File Structure Blueprint

Planned structure (add as needed, keep lean):

```
lib/
  main.dart                // App entry, theme, scaffold wiring
  models/
    stroke.dart            // Stroke model + enum ToolType (FR-04)
  state/
    drawing_state.dart     // ChangeNotifier managing strokes & history (FR-05–07)
  painting/
    strokes_painter.dart   // CustomPainter rendering strokes (FR-02, FR-13)
  widgets/
    drawing_canvas.dart    // Gesture + in-progress stroke handling (FR-01, FR-03, FR-12)
    color_palette.dart     // Color selection UI (FR-08, FR-09)
    stroke_width_selector.dart // Width presets (FR-10)
    toolbar.dart           // Composes controls (undo/redo/clear/save) (FR-14–19)
    confirm_clear_dialog.dart // Clear confirmation (FR-16, FR-17)
  services/
    export_service.dart    // RepaintBoundary→Image→PNG bytes (FR-18–19, FR-24)
  utils/
    date_time_format.dart  // Filename formatting helper
  accessibility/
    semantics_labels.dart  // Central semantic label constants (FR-21)

test/
  unit/
    drawing_state_test.dart      // Undo/redo/core logic
  widget/
    drawing_canvas_test.dart     // Gesture adds stroke
    export_button_test.dart      // Export triggers download (may be mock/web skip)
```

Keep folders flat for MVP; avoid over-abstraction.

---

## 2. Phase-by-Phase Implementation

### Phase P0 – Foundation (FR-01, FR-02, FR-04, FR-12, FR-13)

1. Create `Stroke` model & `ToolType` enum.
2. Implement `DrawingState` with stroke lists (no undo yet) + add stroke API.
3. Implement `StrokesPainter` drawing ordered strokes.
4. Create `DrawingCanvas` widget:
   - Wrap with `RepaintBoundary`.
   - Capture pointer events: start / update / end stroke.
   - Ignore micro-movement strokes unless tap (FR-03 logic placeholder).
5. Integrate into `main.dart` with a bare scaffold.

Validation: Draw lines appear; hot reload safe; no crashes.

### Phase P1 – Interactivity (FR-08, FR-09, FR-10)

1. Implement `ColorPalette` with fixed list + selection highlight.
2. Implement `StrokeWidthSelector` (3 presets, maintain selected state).
3. Wire selections to `DrawingState` or local state (ephemeral UI state in widget) that influences new stroke creation.
4. Display current color & width in toolbar for clarity.

Validation: New strokes use chosen color & width.

### Phase P2 – History (FR-05–07, FR-14)

1. Extend `DrawingState` with `_redo` stack and `undo()`, `redo()` following provided pattern.
2. Add undo/redo buttons with disabled states.
3. Ensure new stroke clears redo stack.
4. Optional keyboard shortcuts (defer to stretch Phase P5).

Validation: Undo removes last stroke, redo restores order precisely.

### Phase P3 – Export & Clear (FR-16–19, FR-24, FR-25, FR-17)

1. Build `export_service.dart` with a function: `Future<Uint8List> exportPng(GlobalKey boundaryKey)`.
2. Add Save button triggering export → browser download (web: `AnchorElement` hack guarded by `kIsWeb`).
3. Add Clear button launching `ConfirmClearDialog`.
4. On confirm: clear both lists & disable history buttons.
5. Error handling: try/catch export, show `SnackBar` on failure (FR-24).
6. Guard disposed boundary / null images (FR-25).

Validation: Downloaded PNG visually matches canvas; clear flow safe.

### Phase P4 – Polish & Responsiveness (FR-21–23, FR-26–27, FR-29–30)

1. Add semantic labels & tooltips (centralize strings).
2. Ensure tap targets ≥ 48×48 (padding or sized boxes).
3. Responsive layout: toolbar row wraps or scrolls on narrow widths (< 800 px).
4. Performance tune:
   - Coalesce high-frequency pointer events (optional micro-throttle or only add point if distance > epsilon).
   - Avoid rebuilding painter parent unnecessarily – isolate repaint area.
5. Add basic focus traversal & visible focus highlight (default Material focus okay).

Validation: Accessible navigation via keyboard; no jank in manual stress test.

### Phase P5 – Stretch (Optional) (FR-11, FR-15, FR-28, FR-31)

1. Width slider replacing presets or as advanced panel.
2. Keyboard shortcuts (Cmd/Ctrl+Z, Shift+Cmd/Ctrl+Z) using `Shortcuts` + `Actions`.
3. Theme toggle (light/dark) or system-based dynamic theme.
4. Logging instrumentation (stroke count, undo count) with `log()` calls.

Validation: Shortcuts function; theme persists for session (optional).

---

## 3. Detailed Task Breakdown

### 3.1 Data Model & Utilities

- Implement `stroke.dart` with immutable class (no setters).
- Add conversion helper `Path buildPath(List<Offset>)` inside painter or extension.
- Add `semantics_labels.dart` constants.
- Add filename formatter in `date_time_format.dart`.

### 3.2 State (`drawing_state.dart`)

- Fields: `_strokes`, `_redo`, `currentColor`, `currentWidth`, `inProgressStroke`.
- Methods:
  - `startStroke(Offset point)` – initialize `inProgressStroke`.
  - `appendPoint(Offset point)` – push to mutable points list.
  - `endStroke()` – validate length / create dot if needed; push to list; clear `inProgressStroke`; clear `_redo`.
  - `undo()`, `redo()`, `clear()`, `setColor(Color)`, `setWidth(double)`.
  - Consider `notifyListeners()` sparingly (only structural or finalization changes; allow painter to rebuild by referencing lists – may require ValueNotifier for `inProgress`).

### 3.3 Painter

- `StrokesPainter(List<Stroke> strokes, Stroke? inProgress)`.
- `shouldRepaint` compares list identities + inProgress reference.
- Draw with `Paint()..color=... ..strokeCap=round ..style=stroke ..strokeWidth=...`.

### 3.4 Gesture / Canvas Widget

- Use `Listener` or `GestureDetector` (`onPanStart`, `onPanUpdate`, `onPanEnd`).
- Convert `DragUpdateDetails.localPosition` into points.
- Distance filter to avoid noise: if lastPoint distance < 0.5 px, skip.
- Single tap (pan start + immediate end) becomes small dot (two points or circle path).

### 3.5 Toolbar Composition

- `Row` / `Wrap`: ColorPalette | WidthSelector | Undo | Redo | Clear | Save.
- Disable buttons via state conditions.

### 3.6 Export Logic

- GlobalKey on `RepaintBoundary`.
- `RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;`
- `ui.Image image = await boundary.toImage();`
- `ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);`
- Browser download (web):
  - `final blob = html.Blob([data.buffer.asUint8List()]);`
  - `final url = html.Url.createObjectUrlFromBlob(blob);`
  - Anchor element with `download` attr; `click();` then revoke URL.
- Filename via timestamp formatter.

### 3.7 Clear Confirmation

- `showDialog` with `AlertDialog` (title + message + Cancel / Clear). ESC dismiss fine.

### 3.8 Accessibility

- Add `Semantics(label: kSemUndoLabel, button: true, enabled: canUndo, child: IconButton(...))`.
- Ensure color buttons have labels like `Color: Red (selected)`.
- Focus order natural left→right; for wrapped layout ensure logical order via widget ordering.

### 3.9 Performance Considerations

- Potential optimization: store Path inside Stroke built lazily (cache after first build).
- If stroke point count > N (e.g., 2k) consider thinning (deferred unless needed).
- Avoid rebuilding entire scaffold: restrict `AnimatedBuilder` to canvas.

### 3.10 Testing

- Unit: `drawing_state_test.dart`
  - Add stroke; undo; redo; clear resets history.
  - Dot stroke (tap) stored with >=1 point.
- Widget: simulate drag on `DrawingCanvas` adds stroke (Finder for painter via semantics or state), count strokes before/after.
- Export test (optional): mock boundary with minimal size; ensure bytes non-empty (skip on web CI nuances if complexity arises).

### 3.11 Error Handling

- Wrap export in try/catch; on error: log + snackbar "Export failed. Retry?" with action.
- Defensive null checks around boundary context.

### 3.12 Theming (Stretch)

- Use `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`.
- Add Theme toggle button toggling `ThemeMode.system / light / dark` (persist ephemeral with `ValueNotifier`).

### 3.13 Logging (Stretch)

- `log('stroke_added', name: 'drawing');`
- Provide counts in a simple debug overlay if desired (defer).

---

## 4. Risk Mitigation Implementation Hooks

| Risk                      | Hook                                                                 |
| ------------------------- | -------------------------------------------------------------------- |
| Performance (many points) | Distance filtering + optional downsample.                            |
| Accidental clear          | Confirmation dialog required path.                                   |
| Export failure            | Graceful catch + snackbar retry.                                     |
| Scope creep               | Keep stretch code in separate commit / feature flags.                |
| Accessibility gaps        | Central semantics constants + manual keyboard test early (Phase P4). |

---

## 5. Stretch Feature Isolation Strategy

- Implement stretch features AFTER MVP stable commit.
- Guard experimental code with clear comments `// STRETCH:` to simplify diff review.
- Keep keyboard shortcut registration in a distinct widget (`AppShortcuts`).

---

## 6. Definition of Done Alignment

- Each FR mapped to at least one implemented artifact.
- Lints pass (`flutter analyze`).
- All unit tests green.
- Manual acceptance scenarios executed & documented in PR description.

---

## 7. Rollout / Branching

1. Work on feature branches: `feature/p0-foundation`, etc.
2. Merge sequentially after review to `fluttercon_europe_2025` branch.
3. Tag MVP release `v1.0.0-mvp` after passing checklist.

---

## 8. Final Consolidated Checklist

### P0 Foundation

- [ ] Stroke model (`stroke.dart`) (FR-04)
- [ ] DrawingState basic add stroke (FR-05)
- [ ] StrokesPainter renders order (FR-02)
- [ ] DrawingCanvas gesture capture (FR-01)
- [ ] RepaintBoundary wrap (FR-13)
- [ ] Micro-stroke filtering / dot logic placeholder (FR-03)

### P1 Interactivity

- [ ] ColorPalette with highlight (FR-08, FR-09)
- [ ] Width selector presets (FR-10)
- [ ] State wiring for color/width (FR-05 linkage)
- [ ] Toolbar integration

### P2 History

- [ ] Redo stack + methods (FR-06, FR-07)
- [ ] Undo/Redo buttons with disabled state (FR-14)
- [ ] New stroke clears redo stack (FR-06)

### P3 Export & Clear

- [ ] Export service PNG creation (FR-18, FR-19)
- [ ] Download trigger (web) (FR-18)
- [ ] Clear confirmation dialog (FR-16, FR-17)
- [ ] Error handling export (FR-24, FR-25)

### P4 Polish & Responsiveness

- [ ] Semantic labels & tooltips (FR-21)
- [ ] Min touch target sizing (FR-22)
- [ ] Logical focus order (FR-23)
- [ ] Responsive toolbar (FR-29)
- [ ] Canvas sizing behavior (FR-12, FR-30)
- [ ] Performance point coalescing (FR-26, FR-27)

### P5 Stretch (Optional)

- [ ] Width slider (FR-11)
- [ ] Keyboard shortcuts (FR-15)
- [ ] Theme toggle / system theme (FR-28)
- [ ] Logging instrumentation (FR-31)

### Testing & Quality

- [ ] Unit tests for DrawingState (undo/redo/clear) (FR-05–07, FR-14, FR-17)
- [ ] Widget test for drawing gesture → stroke count increment (FR-01)
- [ ] Export test or manual validation (FR-18)
- [ ] Lints & analyze clean
- [ ] Manual accessibility keyboard sweep (FR-21–23)
- [ ] Manual performance scribble test (FR-26)

### Release

- [ ] README updated with usage/export notes
- [ ] Tag release `v1.0.0-mvp`
- [ ] Post checklist archived

---

## 9. Backlog (Hold Until Post-MVP)

- Eyedropper (needs read from canvas → offscreen readback or color tracking)
- Eraser (BlendMode.clear layer)
- Shape tools (parametric stroke factory)
- Flood fill (isolate / compute heavy region fill)
- Local persistence (hydrated strokes via `shared_preferences` or indexedDB)
- Gallery + coloring mode

---

Prepared: 2025-09-25
Owner: (Add name)
Version: 1.0.0-plan
