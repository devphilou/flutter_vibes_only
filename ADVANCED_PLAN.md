# Paint Vibes Only – Advanced Implementation Plan (Post‑MVP)

Companion to `PRD.md` Advanced Expansion (FR-32 → FR-54). This plan operationalizes the advanced roadmap in focused, incremental phases (A1–A8) to avoid scope shocks and preserve MVP stability.

---

## 0. Guiding Principles (Carry Over + Additions)

1. Preserve MVP stability: each advanced phase must keep existing drawing workflow functional.
2. Keep dependencies minimal; justify any new package (esp. color picker, persistence helpers, router).
3. Prefer incremental data model evolution with versioned persistence.
4. Tool & shape additions follow Strategy pattern (pluggable behavior) without premature abstraction.
5. Accessibility parity: every new control ships with semantics + keyboard nav.
6. Performance guard rails: measure (DevTools / simple counters) after each phase with sample stress data.

---

## 1. Updated / New Project Structure (Introduced Gradually)

```
lib/
  main.dart
  routing/                 # (A1) Optional: route configuration (e.g., go_router) or manual enum router
  repository/              # (A1) DrawingRepository & implementations
    drawing_repository.dart
    local_storage_adapter.dart   # shared_preferences / web localStorage (metadata)
    indexed_db_adapter_stub.dart # (web) for blobs/thumbnails (progressive enhancement)
  tools/                   # (A2) Tool strategy interfaces & concrete tools
    tool.dart
    pencil_tool.dart
    brush_tool.dart
    eraser_tool.dart
    bucket_tool.dart
    eyedropper_tool.dart
  shapes/                  # (A3) Shape helpers + preview painter
    shape_type.dart
    shape_builder.dart
    shape_preview_painter.dart
  coloring/                # (A5) Coloring gallery + page session
    coloring_page.dart
    coloring_controller.dart
  gallery/                 # (A6) Recent drawings list + thumbnail generation
    gallery_screen.dart
    gallery_controller.dart
    thumbnail_service.dart
  services/
    fill_service.dart      # (A7) Flood fill (may use isolate)
    export_service.dart    # (Existing) + scaling extension
  widgets/                 # New UI components (incremental)
    start_screen.dart
    tool_selector.dart
    shape_toolbar.dart
    color_picker_panel.dart
    theme_toggle_button.dart
    export_scale_dialog.dart
  models/
    stroke.dart            # Extended with optional fields (shapeMeta, blendMode, isEraser)
    drawing_document.dart  # (A1) for persistence bundling (id, strokes, meta, version)
  state/
    drawing_state.dart     # Enhanced to host tool + shape preview state
    tool_state.dart        # (Maybe) if decoupling from drawing core
  utils/
    persistence_version.dart
    color_utils.dart
```

Introduce only what each phase needs; do not pre-create empty folders.

---

## 2. Phase Breakdown Overview

| Phase | Focus                                                   | Key FRs                        | Primary Outputs                                                                           |
| ----- | ------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
| A1    | Start Screen + Persistence Skeleton                     | FR-32, FR-43, FR-49 (partial)  | Start screen, repository interface, document model v2, theme persistence                  |
| A2    | Multi-Tool Core (Brush/Eraser/Eyedropper)               | FR-33, FR-38, FR-37 (partial)  | Tool interface, tool selector UI, eraser via BlendMode.clear, color sampling from strokes |
| A3    | Shape Tools + Grouped Undo                              | FR-34, FR-46, FR-53            | Shape preview painter, shape commit logic, updated undo grouping                          |
| A4    | Advanced Brush + Color Picker + Recents                 | FR-35, FR-36, FR-49 (complete) | Brush variants, color picker integration, recents persistence                             |
| A5    | Coloring Mode + Progress Persistence                    | FR-40, FR-41, FR-52            | Coloring page selection, layered background, progress metric calculation                  |
| A6    | Gallery + Thumbnails + Data Resilience                  | FR-42, FR-43, FR-48, FR-51     | Gallery grid, thumbnail generator, corrupted entry handling, clear-all UI                 |
| A7    | Fill Bucket + Export Scaling + Perf Tuning              | FR-39, FR-44, FR-47            | Flood fill service, export scale option, perf instrumentation hooks                       |
| A8    | Accessibility & Polish + Shortcut Expansion + I18n Prep | FR-45, FR-50, FR-54            | Shortcut help overlay, extended semantics, import stub, string centralization audit       |

---

## 3. Detailed Phase Tasks

### Phase A1 – Start Screen & Persistence Skeleton

Objectives:

- Implement `StartScreen` with three buttons: Free Draw, Coloring (disabled placeholder), Gallery (disabled placeholder).
- Introduce `DrawingRepository` abstraction (in-memory stub first).
- Define `DrawingDocument` (id, version, createdAt, updatedAt, strokes[], metadata map).
- Add theme preference persistence (FR-49) using shared_preferences (or localStorage for web-only mode).

Tasks:

1. Create `drawing_repository.dart` interface + `in_memory_repository.dart` initial impl.
2. Add version constant `const currentDocumentVersion = 2;`.
3. Move existing free draw screen behind route /free.
4. Start screen route is `/`.
5. Theme toggle updates saved preference.

Acceptance:

- Navigating root shows start screen; pressing Free Draw loads existing canvas.
- Theme preference remembered across reload.

### Phase A2 – Core Multi-Tool (Brush, Eraser, Eyedropper)

Objectives:

- Introduce `Tool` abstract class with pointer lifecycle hooks: `onStart`, `onUpdate`, `onEnd`.
- Implement pencil (wrap current behavior), brush variant (maybe wider + alpha jitter), eraser (BlendMode.clear stroke), eyedropper (on tap sample color & revert tool).
- Tool selector UI (radio-style semantics) added to toolbar, minimal icons (reuse assets if available).

Tasks:

1. Extend `ToolType` enum; integrate into `DrawingState` to store active tool.
2. Move stroke creation to tool strategies (drawing_state delegates).
3. Add `isEraser` or `blendMode` to stroke serialization (update version migration path).
4. Eyedropper: sample last stroke whose path bounds contain tap point (initial heuristic) – or stub sample active color until advanced pixel sampling implemented.

Acceptance:

- Switching tools updates behavior (eraser clears, brush draws thicker/soft stroke variant).
- Eyedropper updates active color (announce via semantics/log).

### Phase A3 – Shape Tools & Grouped Undo

Objectives:

- Implement shape preview (not yet committed) during drag.
- On pointer up commit a stroke tagged with `ShapeMeta`.
- Adjust undo system so preview updates do not spam history (FR-46).

Tasks:

1. Add `ShapeType { rectangle, circle, line, wave }`.
2. Add `ShapeMeta(start, end, maybe controlPoints)`.
3. Painter: if shape meta present, render parametric path.
4. Preview layer: ephemeral shape painter on top using current drag coordinates.
5. Undo: treat each shape commit as single entry.

Acceptance:

- Drag draws ghost; release finalizes one stroke. Undo removes it cleanly.

### Phase A4 – Advanced Brush & Color Picker + Recents

Objectives:

- Integrate a color picker (package or custom HSV wheel). Maintain recents list (ring or strip).
- Brush variants: soft (alpha gradient), calligraphic (width influenced by direction speed) – keep simple; maybe stub second variant for future.

Tasks:

1. Add `RecentColorsController` storing list persisted through repository/preference.
2. Add brush style enum; modify painter to adjust paint for style.
3. UI: expandable panel or modal for advanced color selection.

Acceptance:

- Picking custom color adds to recents; persists reload.
- Changing brush style visibly affects stroke rendering.

### Phase A5 – Coloring Mode & Progress

Objectives:

- Display grid of line-art assets (read from `resources/assets/coloring`).
- Selecting a page opens drawing view with locked background image.
- Progress (%) computed: ratio filled area vs total drawable (approx by counting non-transparent pixels in a rendered mask or stroke-covered bounding boxes initially).

Tasks:

1. `ColoringPage` model (id, assetPath, progress, lastUpdated).
2. Add separate storage namespace for coloring strokes.
3. Compute heuristic progress after each stroke commit (approx: stroke area union / canvas area excluding blank?). Start with stroke count over threshold baseline; iterate later.

Acceptance:

- Page re-open shows previous strokes.
- Progress indicator displays and updates.

### Phase A6 – Gallery & Thumbnails

Objectives:

- List saved drawings (documents) with thumbnail + metadata.
- Open / duplicate / delete.
- Handle corrupted entries gracefully (skip + log).

Tasks:

1. Add thumbnail generation service using `toImage()` scaled to max width 200.
2. Store thumbnail bytes separate from document (lazy generate on first open if absent).
3. Gallery grid widget with accessible announcements.
4. Delete flow confirmation.

Acceptance:

- New drawing appears after save/exit.
- Corrupted (simulated) entry skipped with console warning.

### Phase A7 – Fill Bucket, Export Scaling, Performance Tuning

Objectives:

- Bucket fill algorithm (seed fill) with size guard.
- Export dialog with scale selection (1x/2x/4x). Warn on large memory estimate.
- Performance instrumentation (frame time snapshot when flood fill invoked).

Tasks:

1. Implement flood fill in isolate (`compute`) passing image byte buffer & seed.
2. Apply result as a fill stroke or add raster layer? (Simpler: convert filled region to path outline if time; else store as bitmap stroke with caching.)
3. Extend export service: optional scale param multiplies logical size.

Acceptance:

- Filling enclosed area colors region; undo removes it.
- Export 2x image dimensions exactly double 1x.

### Phase A8 – Accessibility, Shortcuts Expansion, Import Stub, I18n Prep

Objectives:

- Add full shortcut help overlay (press ? or via menu).
- Add tool hotkeys (B, E, F, I, L, R, C, etc.), numeric width shortcuts.
- Audit semantics for new controls (tool group announced, gallery items).
- Add import (JSON) stub UI that validates structure (FR-54 partial).
- Prepare for localization (wrap all new strings in central layer).

Tasks:

1. Shortcut reference dialog (`AlertDialog` listing combos).
2. Keyboard mapping service or constants file.
3. Introduce string helper methods for parameterized labels.
4. JSON import validation + error feedback (SnackBar + log).

Acceptance:

- Pressing ? shows overlay.
- Tool hotkeys switch active tool; focus preserved.
- Import invalid file shows graceful error.

---

## 4. Data Model Change Log & Migration Strategy

| Version | Changes                                                      | Migration                                                |
| ------- | ------------------------------------------------------------ | -------------------------------------------------------- |
| 1       | MVP: strokes basic                                           | N/A                                                      |
| 2       | + isEraser / blendMode / shapeMeta option                    | If absent → default (false / null)                       |
| 3       | + brushStyle, recentColors list                              | If absent → set default brushStyle=pencil, empty recents |
| 4       | + coloring page metadata, gallery doc fields (thumbnailHash) | If absent → infer on load (generate thumbnail)           |

Migration Flow:

1. Parse JSON; detect `version`.
2. If null → assume 1.
3. Apply stepwise enrichment until current.
4. On failure: log warning, mark document corrupted (skip listing but keep raw for potential recovery UI).

---

## 5. Tool Strategy Interface (Draft)

```dart
abstract class Tool {
  ToolType get type;
  void onStart(DrawingState state, Offset p);
  void onUpdate(DrawingState state, Offset p);
  void onEnd(DrawingState state);
  Widget? buildCursorPreview(BuildContext context, Offset? lastPoint) => null;
}
```

Eraser uses same stroke path but sets `isEraser=true` or `blendMode=BlendMode.clear`.
Bucket may directly mutate a bitmap layer (encapsulated so state history still works by pushing a synthetic stroke reference to filled region data).

---

## 6. Testing Strategy (Advanced Layer)

| Area           | Tests                                                                    |
| -------------- | ------------------------------------------------------------------------ |
| Repository     | Save/load roundtrip, migration v1→current, corrupted skip.               |
| Tools          | Each tool creates expected stroke flags (eraser clears, shape has meta). |
| Shapes         | Preview not added to stroke list until end. Undo removes one entry.      |
| Color Picker   | Recent colors persistence; duplicate handling (move to front).           |
| Gallery        | Thumbnail generation; deletion updates list; corrupted removal.          |
| Coloring       | Progress calculation stable across reloads.                              |
| Fill           | Flood fill returns bounded region; cancel on oversize input.             |
| Export Scaling | 2x / 4x image dimension assertions.                                      |
| Shortcuts      | Key combos trigger correct tool or undo/redo (widget tests).             |

Performance Micro Benchmarks (Optional): Path build time for large stroke sets; flood fill execution duration.

---

## 7. Performance Guard Rails

| Concern              | Target               | Mitigation                                                    |
| -------------------- | -------------------- | ------------------------------------------------------------- |
| Stroke list growth   | < 5k typical         | Downsample points for very long strokes; batch commit shapes. |
| Flood fill time      | < 120 ms medium area | Run isolate; bail if pixel count threshold exceeded.          |
| Thumbnail generation | < 80 ms per doc      | Cache & only regenerate on modification.                      |
| Gallery render       | < 16 ms frame        | Lazy load thumbnails with `Image.memory` + placeholders.      |

---

## 8. Accessibility Enhancements Checklist

- [ ] Tool selector: role=radio group semantics.
- [ ] Shape preview semantics: announce “Preview: Rectangle – release to place.”
- [ ] Gallery tiles: label "Drawing <n> of <total>, <progress>% complete, last edited <time>."
- [ ] Color picker: focus order inside dialog logical; recents list announces color + “recent”.
- [ ] Shortcut overlay accessible description and dismiss via Esc.

---

## 9. Risk Register (Advanced)

| Risk                          | Phase | Mitigation                                                            |
| ----------------------------- | ----- | --------------------------------------------------------------------- |
| Over-complex tool abstraction | A2    | Keep interface minimal; evolve only if needed in later phases.        |
| Flood fill memory spike       | A7    | Pre-calc area size; limit recursion; isolate compute.                 |
| Persistence corruption        | A6    | Version + validation + skip with user notice.                         |
| Gallery scale degrade         | A6    | Throttle thumbnail generation; schedule with `scheduleFrameCallback`. |
| Shortcuts conflicts           | A8    | Document & allow user to reset defaults (future).                     |

---

## 10. Phase Exit Criteria Summary

| Phase | Exit Snapshot                                                       |
| ----- | ------------------------------------------------------------------- |
| A1    | Start screen navigation functional; repository stub; theme persists |
| A2    | Tool switching works; eraser + eyedropper functional                |
| A3    | Shape drawing + grouped undo stable                                 |
| A4    | Custom color + brush variants; recents persist                      |
| A5    | Coloring pages selectable with progress                             |
| A6    | Gallery lists, opens, deletes documents with thumbnails             |
| A7    | Bucket fill + scaled export; perf still within targets              |
| A8    | Accessibility & shortcuts polished; import stub present             |

---

## 11. Rollout & Branching (Advanced)

| Branch Prefix       | Example           | Notes                          |
| ------------------- | ----------------- | ------------------------------ |
| `feature/a1-start`  | Adds start screen | Merge after minimal QA         |
| `feature/a2-tools`  | Tool framework    | Re-run regression drawing test |
| `feature/a3-shapes` | Shape meta        | Add migration script if needed |
| ...                 | ...               | ...                            |

Tag advanced release as `v1.1.0` after A8 completion (semver minor: new features, backwards compatible).

---

## 12. Backlog (Deferred / Candidate Ideas Post-A8)

- Pixel-perfect eyedropper (direct pixel sampling) optimization.
- Vector export (SVG) for shape + path strokes.
- Pressure input integration (PointerEvent pressure mapping).
- Offline PWA asset caching + manifest enhancements.
- Collaborative editing (CRDT / OT) exploration.

---

## 13. Definition of Done (Advanced Layer)

1. All in-scope advanced FRs (32–54 targeted subset) implemented or explicitly deferred with rationale in PR description.
2. No regression in MVP acceptance tests or performance baseline.
3. Repository migrations tested (automated + manual corrupted case).
4. Accessibility scan manual pass (keyboard traversal + screen reader label spot check).
5. New strings centralized; zero stray user-visible literals in new code.
6. Export at 2x / 4x validated on at least one complex drawing.
7. Flood fill tested on small, medium, large regions (document region thresholds recorded).

---

Prepared: 2025-09-25
Owner: (Add name)
Version: 0.1.0-advanced-plan (initial draft)
