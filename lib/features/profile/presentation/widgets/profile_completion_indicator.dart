import 'package:flutter/material.dart';

import 'package:christian_dating_app/app_typography.dart';

/// Edit-profile card showing % complete and a horizontal progress bar.
class ProfileCompletionIndicator extends StatelessWidget {
  const ProfileCompletionIndicator({
    super.key,
    required this.completion,
  });

  final double completion;

  static const Color _cardColor = Color(0xFFF0F0F2);
  static const Color _trackColor = Color(0xFFE3E3E3);
  static const Color _fillColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    final clamped = completion.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$percent%',
            style: AppTypography.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile to get more likes!',
            style: AppTypography.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A8A8A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 4,
              backgroundColor: _trackColor,
              color: _fillColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bumble-style profile strength header + tappable completion row.
class ProfileStrengthSection extends StatelessWidget {
  const ProfileStrengthSection({
    super.key,
    required this.completion,
    this.onTap,
  });

  final double completion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = completion.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile strength',
          style: AppTypography.extraBold(
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$percent% complete',
                      style: AppTypography.bold(
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade500,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
