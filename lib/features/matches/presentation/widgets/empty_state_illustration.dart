import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared empty-state illustration sizing (Liked You, Messages, etc.).
abstract final class EmptyStateIllustrationLayout {
  static const double width = 215;
  static const double height = 184;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 50);
  static const double spacingBelow = 10;
}

class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    super.key,
    required this.assetPath,
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: EmptyStateIllustrationLayout.width,
      height: EmptyStateIllustrationLayout.height,
      fit: BoxFit.contain,
    );
  }
}
