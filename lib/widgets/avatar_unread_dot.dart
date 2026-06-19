import 'package:flutter/material.dart';

/// Small red indicator for unopened chats, centered on the avatar circle edge.
class AvatarUnreadDot extends StatelessWidget {
  const AvatarUnreadDot({
    super.key,
    required this.child,
    required this.avatarRadius,
    this.show = false,
    this.size = 15,
    this.borderWidth = 1.8,
  });

  final Widget child;
  final double avatarRadius;
  final bool show;
  final double size;
  final double borderWidth;

  static const Color dotColor = Color(0xFFED865E);
  static const double _sqrtHalf = 0.7071067811865476;

  @override
  Widget build(BuildContext context) {
    // Place dot center on the circle perimeter at ~45° (top-right).
    final edgeX = avatarRadius + avatarRadius * _sqrtHalf;
    final edgeY = avatarRadius - avatarRadius * _sqrtHalf;

    return SizedBox(
      width: avatarRadius * 2,
      height: avatarRadius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          child,
          if (show)
            Positioned(
              left: edgeX - size / 2,
              top: edgeY - size / 2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: borderWidth),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
