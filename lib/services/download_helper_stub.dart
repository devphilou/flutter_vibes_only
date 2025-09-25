// Fallback (non-web) no-op download helper.
import 'dart:typed_data';

Future<void> triggerDownload(Uint8List bytes, String filename) async {
  // On non-web platforms we could later save to gallery / filesystem.
}
