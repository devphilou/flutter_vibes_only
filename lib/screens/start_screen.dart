import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../strings/app_strings.dart';

/// Start screen offering navigation to modes.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavButton(
                icon: Icons.gesture,
                label: 'Free Draw',
                onTap: () => context.go(AppRoute.freeDraw),
                color: scheme.primary,
              ),
              const SizedBox(height: 12),
              _NavButton(
                icon: Icons.color_lens,
                label: 'Coloring Pages (Coming Soon)',
                onTap: null,
                color: scheme.secondary,
              ),
              const SizedBox(height: 12),
              _NavButton(
                icon: Icons.photo_library,
                label: 'Gallery (Coming Soon)',
                onTap: null,
                color: scheme.tertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? color.withOpacity(0.4) : color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(64),
        ),
        icon: Icon(icon, size: 32),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
