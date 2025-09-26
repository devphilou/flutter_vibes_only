import '../models/drawing_document.dart';

/// Summary metadata for lightweight listing without loading full strokes.
class DrawingSummary {
  DrawingSummary({
    required this.id,
    required this.updatedAt,
    required this.strokeCount,
  });
  final String id;
  final DateTime updatedAt;
  final int strokeCount;
}

/// Abstraction for persisting and retrieving drawings.
abstract class DrawingRepository {
  Future<List<DrawingSummary>> list();
  Future<DrawingDocument?> load(String id);
  Future<void> save(DrawingDocument doc);
  Future<String> createEmpty();
  Future<void> delete(String id);
  Future<void> clearAll();
}
