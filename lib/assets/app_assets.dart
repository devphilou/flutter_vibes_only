/// Centralized asset path constants to avoid typos in string literals.
/// Update here if asset paths change.
abstract final class AppAssets {
  static const root = 'resources/assets';
  static const logo = '$root/logo.png';
  static const pencil = '$root/pencil_icon.png';
  static const paintBrush = '$root/paintbrush_icon.png';
  static const eraser = '$root/eraser_icon.png';
  static const eyedropper = '$root/eyedropper_icon.png';
  static const bucket = '$root/paint_bucket_icon.png';
  static const undo = '$root/undo_icon.png';
  static const redo = '$root/redo_icon.png';
  static const clear = '$root/clear_canvas_icon.png';
  static const brushSet = '$root/brush_set_icon.png';
  static const circleShape = '$root/circle_shape_icon.png';
  static const squareShape = '$root/square_shape_icon.png';
  static const waveShape = '$root/wave_line_icon.png';
  // A simple generated line icon isn't present; we'll draw line symbol in code.
  static const autumn = '$root/autumn.png';

  // Coloring pages root (individual names may vary, keep directory accessible)
  static const coloringRoot = '$root/coloring';
}
