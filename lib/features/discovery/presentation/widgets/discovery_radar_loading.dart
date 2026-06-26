import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/core/widgets/profile_avatar.dart';

/// Centered profile avatar with outward-pulsing radar rings (discovery load state).
class DiscoveryRadarLoading extends StatefulWidget {
  const DiscoveryRadarLoading({
    super.key,
    required this.userData,
    this.avatarRadius = 54,
  });

  final Map<String, dynamic> userData;
  final double avatarRadius;

  @override
  State<DiscoveryRadarLoading> createState() => _DiscoveryRadarLoadingState();
}
//LikeDiscovery Loading State Radar Animation
class _DiscoveryRadarLoadingState extends State<DiscoveryRadarLoading>
    with SingleTickerProviderStateMixin {
  static const int _ringCount = 3;
  static const double _avatarBorderWidth = 6;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarDiameter = widget.avatarRadius * 2;
    final radarExtent = avatarDiameter * 2.8;

    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: radarExtent,
          height: radarExtent,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < _ringCount; i++)
                    _buildRadarRing(
                      phase: (_controller.value + i / _ringCount) % 1.0,
                      maxDiameter: radarExtent,
                    ),
                  child!,
                ],
              );
            },
            child: Container(
              width: avatarDiameter + _avatarBorderWidth * 2,
              height: avatarDiameter + _avatarBorderWidth * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: kMatchOrange,
                  width: _avatarBorderWidth,
                ),
              ),
              child: ClipOval(
                child: ProfileAvatar(
                  userData: widget.userData,
                  radius: widget.avatarRadius,
                  backgroundColor: const Color(0xFFF2F2F2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadarRing({
    required double phase,
    required double maxDiameter,
  }) {
    final scale = 0.55 + phase * 0.95;
    final fade = (1 - phase).clamp(0.0, 1.0);
    final diameter = maxDiameter * scale;

    return Opacity(
      opacity: fade * 0.55,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kMatchOrange.withValues(alpha: 0.12 * fade),
          border: Border.all(
            color: kMatchOrange.withValues(alpha: 0.55 * fade),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
