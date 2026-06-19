import 'package:flutter/material.dart';

import '../app_icons.dart';
import 'app_icon.dart';

/// Discovery app bar premium affordance: diamond in a white circle on a beige pill.
class DiscoveryPremiumPill extends StatelessWidget {
  const DiscoveryPremiumPill({
    super.key,
    this.onTap,
  });

  static const Color _pillColor = Color(0xFFF2F2F2);
  static const double _pillHeight = 36;
  static const double _pillPadding = 4;
  static const double _circleSize = _pillHeight - _pillPadding * 2;
  static const double _pillWidth = _pillPadding * 2 + _circleSize * 2;
  static const double _iconSize = 18;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: _pillWidth,
      height: _pillHeight,
      decoration: BoxDecoration(
        color: _pillColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(_pillPadding),
      alignment: Alignment.centerLeft,
      child: Container(
        width: _circleSize,
        height: _circleSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const AppIcon(
          AppIcons.premium,
          width: _iconSize,
          height: _iconSize,
        ),
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}
