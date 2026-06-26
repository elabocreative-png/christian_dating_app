import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/widgets/app_back_button.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';

/// Shared chrome for multi-step onboarding (Bumble-style).
class OnboardingStepShell extends StatelessWidget {
  const OnboardingStepShell({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.showBackOnFirstStep = false,
    this.primaryEnabled = true,
    this.isLoading = false,
    this.bottomHint,
    this.showPrimaryButton = true,
  });

  static const Color accent = kBrandAccent;
  static const double _horizontalPadding = 24;

  final int stepIndex;
  final int stepCount;
  final String title;
  final String? subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool showBackOnFirstStep;
  final bool primaryEnabled;
  final bool isLoading;
  final Widget? bottomHint;
  final bool showPrimaryButton;

  @override
  Widget build(BuildContext context) {
    final progress = (stepIndex + 1) / stepCount;
    final showBack =
        onBack != null && (stepIndex > 0 || showBackOnFirstStep);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                8,
                _horizontalPadding,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE8E8EA),
                  color: kBrandAccent,
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: showBack
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: IconButton(
                          icon: AppBackIcon.icon(color: Colors.black87),
                          onPressed: onBack,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  _horizontalPadding,
                  0,
                  _horizontalPadding,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    child,
                  ],
                ),
              ),
            ),
            if (bottomHint != null) bottomHint!,
            if (showPrimaryButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  _horizontalPadding,
                  8,
                  _horizontalPadding,
                  16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        primaryEnabled && !isLoading ? onPrimary : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFF3F3F3),
                      disabledForegroundColor: const Color(0xFF8D8D8D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            primaryLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              )
            else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
