import 'dart:collection';

import '../models/drawing_document.dart';
import 'drawing_repository.dart';

/// Simple volatile repository for early A1 development.
class InMemoryDrawingRepository implements DrawingRepository {
  final _docs = HashMap<String, DrawingDocument>();

  @override
  Future<String> createEmpty() async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _docs[id] = DrawingDocument(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      strokes: const [],
    );
    return id;
  }

  @override
  Future<void> delete(String id) async {
    _docs.remove(id);
  }

  @override
  Future<DrawingDocument?> load(String id) async => _docs[id];

  @override
  Future<void> save(DrawingDocument doc) async {
    _docs[doc.id] = doc.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<List<DrawingSummary>> list() async {
    return _docs.values
        .map((d) => DrawingSummary(
              id: d.id,
              updatedAt: d.updatedAt,
              strokeCount: d.strokes.length,
            ))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> clearAll() async => _docs.clear();
}
