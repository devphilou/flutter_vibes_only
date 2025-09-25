/// Formats a timestamp for filenames: vibes_YYYYMMDD_HHmmss.png
String timestampFileName(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final y = dt.year.toString();
  final m = two(dt.month);
  final d = two(dt.day);
  final h = two(dt.hour);
  final min = two(dt.minute);
  final s = two(dt.second);
  return 'vibes_${y}${m}${d}_${h}${min}${s}.png';
}
