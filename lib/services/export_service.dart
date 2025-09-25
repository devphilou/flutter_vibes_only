import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Captures the widget referenced by [boundaryKey] to PNG bytes (FR-18, FR-19).
Future<Uint8List> exportPng(GlobalKey boundaryKey) async {
  final context = boundaryKey.currentContext;
  if (context == null) {
    throw StateError('Canvas boundary context is not available');
  }
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError('RenderObject is not a RepaintBoundary');
  }
  final ui.Image image = await renderObject.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('Failed to encode image');
  return data.buffer.asUint8List();
}
