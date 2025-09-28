import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../assets/app_assets.dart';
import '../main.dart' show ThemeController; // Theme controller access.
import '../routing/app_router.dart';
import '../strings/app_strings.dart';

/// Start screen with background image and navigation buttons.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeController = ThemeController.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: AppStrings.themeToggle,
            onPressed: themeController.cycle,
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.autumn,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.45)
                    : Colors.white.withOpacity(0.20),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Image.asset(
                      AppAssets.logo,
                      width: 140,
                      height: 140,
                      filterQuality: FilterQuality.medium,
                      semanticLabel: AppStrings.appTitle,
                    ),
                  ),
                  _NavButton(
                    iconAsset: AppAssets.paintBrush,
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
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.onTap,
    required this.color,
    this.icon,
    this.iconAsset,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final String? iconAsset;

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
          backgroundColor: disabled ? color.withOpacity(0.45) : color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(64),
        ),
        icon: iconAsset != null
            ? Image.asset(
                iconAsset!,
                width: 36,
                height: 36,
                filterQuality: FilterQuality.medium,
              )
            : Icon(icon, size: 32),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
