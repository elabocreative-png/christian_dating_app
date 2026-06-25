import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/widgets/app_back_button.dart';
import 'package:christian_dating_app/widgets/app_icon.dart';

/// Onboarding step: request notification permission (black on blue).
class OnboardingNotificationsStep extends StatelessWidget {
  const OnboardingNotificationsStep({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.onBack,
    required this.onRequestNotifications,
    required this.onSkip,
    this.isLoading = false,
  });

  final int stepIndex;
  final int stepCount;
  final VoidCallback onBack;
  final VoidCallback onRequestNotifications;
  final VoidCallback onSkip;
  final bool isLoading;

  static const double _horizontalPadding = 24;

  @override
  Widget build(BuildContext context) {
    final progress = (stepIndex + 1) / stepCount;

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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: IconButton(
                    icon: AppBackIcon.icon(color: Colors.black87),
                    onPressed: isLoading ? null : onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: kBrandAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.black87,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Notify me about matches',
                      textAlign: TextAlign.center,
                      style: AppTypography.extraBold(
                        fontSize: 28,
                        color: Colors.black87,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Get notifications when you get a match or receive messages',
                      textAlign: TextAlign.center,
                      style: AppTypography.regular(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.45,
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                8,
                _horizontalPadding,
                8,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : onRequestNotifications,
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrandAccent,
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: kBrandAccent.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.black54,
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
                            color: Colors.black87,
                          ),
                        )
                      : Text(
                          'I want to be notified',
                          style: AppTypography.bold(fontSize: 15),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton(
                onPressed: isLoading ? null : onSkip,
                child: Text(
                  'Skip for now',
                  style: AppTypography.bold(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
