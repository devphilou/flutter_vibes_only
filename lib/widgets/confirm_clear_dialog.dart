import 'package:flutter/material.dart';

/// Confirmation dialog for clearing the canvas (FR-16, FR-17).
Future<bool?> showConfirmClearDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear canvas?'),
      content: const Text('This will remove all strokes and undo history.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
}
