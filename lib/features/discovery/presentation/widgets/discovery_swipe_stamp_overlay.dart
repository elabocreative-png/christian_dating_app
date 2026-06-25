import 'package:flutter/material.dart';

import 'package:christian_dating_app/widgets/app_icon.dart';
import 'package:christian_dating_app/app_icons.dart';

/// Bumble-style like / pass icons while dragging a discovery card.
class DiscoverySwipeStampOverlay extends StatelessWidget {
  const DiscoverySwipeStampOverlay({
    super.key,
    required this.dragX,
    required this.commitThreshold,
    this.isSocialMode = false,
  });

  final double dragX;
  final double commitThreshold;
  final bool isSocialMode;

  static const double _fadeStart = 20;
  static const Color _datingLikeCircleColor = Color(0xFFED865E);
  static const Color _passCircleColor = Color(0xFF3C3C3C);

  Color get _likeCircleColor =>
      isSocialMode ? kBrandAccent : _datingLikeCircleColor;

  double get _intensity {
    final abs = dragX.abs();
    if (abs < _fadeStart) return 0;
    return ((abs - _fadeStart) / (commitThreshold - _fadeStart))
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final intensity = _intensity;
    if (intensity <= 0) return const SizedBox.shrink();

    final isLike = dragX > 0;
    final eased = Curves.easeOut.transform(intensity);
    final scale = 0.42 + 0.58 * eased;
    final opacity = (intensity * 1.15).clamp(0.0, 1.0);
    final dragNudge = Offset(dragX * 0.14, 0);
    const badgeSize = 64.0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isLike)
            Positioned(
              top: 56,
              left: 20,
              child: Transform.translate(
                offset: dragNudge,
                child: _SwipeActionBadge(
                  svgAsset: isSocialMode
                      ? AppIcons.handWaveSolid
                      : AppIcons.heartSolid,
                  backgroundColor: _likeCircleColor,
                  iconColor: Colors.white,
                  opacity: opacity,
                  scale: scale,
                  size: badgeSize,
                  boxShadow: [
                    BoxShadow(
                      color: _likeCircleColor.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              top: 56,
              right: 20,
              child: Transform.translate(
                offset: dragNudge,
                child: _SwipeActionBadge(
                  svgAsset: AppIcons.closeSolid,
                  backgroundColor: _passCircleColor,
                  iconColor: Colors.white,
                  opacity: opacity,
                  scale: scale,
                  size: badgeSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeActionBadge extends StatelessWidget {
  const _SwipeActionBadge({
    required this.svgAsset,
    required this.backgroundColor,
    required this.iconColor,
    required this.opacity,
    required this.scale,
    required this.size,
    this.boxShadow,
  });

  final String svgAsset;
  final Color backgroundColor;
  final Color iconColor;
  final double opacity;
  final double scale;
  final double size;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: boxShadow,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: AppIcon(
                svgAsset,
                size: size * 0.46,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
