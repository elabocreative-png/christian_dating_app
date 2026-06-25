import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/widgets/app_icon.dart';

/// First-time discovery tutorial steps for new sign-ups.
enum DiscoveryHintStep {
  message,
  swipeChoice,
}

/// Gradient hint card overlay — real profile card shows through transparent areas.
class DiscoveryHelperHintOverlay extends StatelessWidget {
  const DiscoveryHelperHintOverlay({
    super.key,
    required this.step,
    this.borderRadius = 20,
  });

  final DiscoveryHintStep step;
  final double borderRadius;

  static const Color _titleColor = Color(0xFF1B2A41);
  // Matches floating intro on [UserProfileDiscoveryCard].
  static const double _introRight = 16;
  static const double _introBottom = 18;
  static const double _introSize = 60;
  static const double _fingerSize = 72;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.90),
                  Colors.white,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 5),
                Text(
                  step == DiscoveryHintStep.message
                      ? 'Message Them'
                      : 'Make Your Choice',
                  textAlign: TextAlign.center,
                  style: AppTypography.manrope(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step == DiscoveryHintStep.message
                      ? 'Tap the chat button to start talking'
                      : 'Swipe right to like them or swipe left to pass',
                  textAlign: TextAlign.center,
                  style: AppTypography.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _titleColor.withValues(alpha: 0.82),
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 4),
                if (step == DiscoveryHintStep.swipeChoice)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: _AnimatedSwipeGestureIcon(),
                  ),
              ],
            ),
          ),
          if (step == DiscoveryHintStep.message)
            Positioned(
              right: _introRight + _introSize - 4,
              bottom: _introBottom + 2,
              child: Transform.rotate(
                angle: 0.28,
                alignment: Alignment.bottomRight,
                child: const AppIcon(
                  AppIcons.fingerTap,
                  width: _fingerSize,
                  height: _fingerSize,
                  color: _titleColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedSwipeGestureIcon extends StatefulWidget {
  const _AnimatedSwipeGestureIcon();

  @override
  State<_AnimatedSwipeGestureIcon> createState() =>
      _AnimatedSwipeGestureIconState();
}

class _AnimatedSwipeGestureIconState extends State<_AnimatedSwipeGestureIcon>
    with SingleTickerProviderStateMixin {
  static const Color _iconColor = Color(0xFF1B2A41);

  late final AnimationController _controller;
  late final Animation<double> _offsetX;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _offsetX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -52)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -52, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 52)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 52, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetX,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetX.value, 0),
          child: child,
        );
      },
      child: const AppIcon(
        AppIcons.swipeGesture,
        width: 88,
        height: 88,
        color: _iconColor,
      ),
    );
  }
}
