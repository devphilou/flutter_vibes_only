import 'package:flutter/material.dart';

/// Reusable asset icon widget that shows a fallback [Icon] if the asset
/// fails to load (e.g., asset manifest not rebuilt yet). This prevents noisy
/// red error boxes in the UI while diagnosing asset configuration issues.
class AppAssetIcon extends StatelessWidget {
  const AppAssetIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stack) => Icon(
        Icons.image_not_supported_outlined,
        size: size,
        color: color ?? Theme.of(context).colorScheme.error,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
