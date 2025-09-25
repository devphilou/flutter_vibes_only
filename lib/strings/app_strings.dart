/// Centralized user‑visible strings & semantic labels.
/// Simple constants (no i18n framework for MVP).
class AppStrings {
  static const appTitle = 'Paint Vibes Only';
  static const drawingCanvasLabel =
      'Drawing canvas. Drag to draw. Use Undo or Clear buttons for history.';

  // Toolbar actions
  static const undo = 'Undo';
  static const redo = 'Redo';
  static const clear = 'Clear';
  static const save = 'Save';
  static const confirmClearTitle = 'Clear canvas?';
  static const confirmClearMessage =
      'This will remove all strokes. This action cannot be undone.';
  static const confirm = 'Confirm';
  static const cancel = 'Cancel';

  // Feedback
  static const exportFailed = 'Export failed';
  static const savedPrefix = 'Saved';
}
