import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_illustrations.dart';
import 'app_icon.dart';

/// Tap-and-hold cross for the faith declaration onboarding step.
class OnboardingFaithDeclarationContent extends StatefulWidget {
  const OnboardingFaithDeclarationContent({
    super.key,
    required this.userName,
    required this.onHoldComplete,
  });

  final String userName;
  final VoidCallback onHoldComplete;

  static const double _circleMin = 150;
  static const double _circleMax = 230;
  static const Duration _holdDuration = Duration(seconds: 3);

  @override
  State<OnboardingFaithDeclarationContent> createState() =>
      _OnboardingFaithDeclarationContentState();
}

class _OnboardingFaithDeclarationContentState
    extends State<OnboardingFaithDeclarationContent>
    with TickerProviderStateMixin {
  late final AnimationController _holdController;
  late final AnimationController _pulseController;
  bool _holding = false;
  bool _completed = false;
  double _pulsePrev = 0;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: OnboardingFaithDeclarationContent._holdDuration,
    )..addStatusListener(_onHoldStatus);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onPulseHaptic);
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _completed = true;
      _holding = false;
      _pulseController.stop();
      HapticFeedback.mediumImpact();
      widget.onHoldComplete();
    }
  }

  void _onPulseHaptic() {
    if (!_holding || _completed) return;
    final v = _pulseController.value;
    if (_pulsePrev > 0.88 && v < 0.12) {
      HapticFeedback.lightImpact();
    }
    _pulsePrev = v;
  }

  void _startHold() {
    if (_completed) return;
    HapticFeedback.selectionClick();
    setState(() => _holding = true);
    _pulsePrev = 0;
    _holdController.forward(from: _holdController.value);
    _pulseController.repeat();
  }

  void _cancelHold() {
    if (_completed || !_holding) return;
    setState(() => _holding = false);
    _holdController.stop();
    _holdController.reverse();
    _pulseController.stop();
    _pulseController.reset();
    _pulsePrev = 0;
  }

  @override
  void dispose() {
    _holdController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userName.trim().isEmpty
        ? 'Friend'
        : widget.userName.trim();

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'I, $displayName,',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
                const TextSpan(
                  text:
                      '\nam a Christian, and I believe in the death, burial, '
                      'resurrection & Lordship of Jesus Christ.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    height: 1.45,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: Listenable.merge([_holdController, _pulseController]),
          builder: (context, child) {
            final holdT = _holdController.value;
            final baseSize = _holding || holdT > 0
                ? OnboardingFaithDeclarationContent._circleMin +
                    (OnboardingFaithDeclarationContent._circleMax -
                            OnboardingFaithDeclarationContent._circleMin) *
                        holdT
                : OnboardingFaithDeclarationContent._circleMin;
            final pulse = _holding
                ? 1 + 0.05 * math.sin(_pulseController.value * 2 * math.pi)
                : 1.0;
            final circleSize = baseSize * pulse;

            return SizedBox(
              width: OnboardingFaithDeclarationContent._circleMax + 24,
              height: OnboardingFaithDeclarationContent._circleMax + 24,
              child: Center(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => _startHold(),
                  onPointerUp: (_) => _cancelHold(),
                  onPointerCancel: (_) => _cancelHold(),
                  child: SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kBrandAccent.withValues(alpha: 0.18),
                          ),
                        ),
                        SvgPicture.asset(
                          AppIllustrations.faithDeclaration,
                          width: 102,
                          height: 101,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Tap and hold on the cross to commit',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kBrandAccent,
            height: 1.35,
          ),
        ),
        ],
      ),
    );
  }
}
