import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/widgets/app_icon.dart';

class ProfilePlansTabContent extends StatelessWidget {
  const ProfilePlansTabContent({super.key});

  void _showSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumSection(
      onGetPremium: () => _showSoon(context, 'Premium'),
      onAllFeatures: () => _showSoon(context, 'All features'),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  const _PremiumSection({
    required this.onGetPremium,
    required this.onAllFeatures,
  });

  final VoidCallback onGetPremium;
  final VoidCallback onAllFeatures;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [kBrandAccent, kBrandAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          const _ExtraPlusLabel(
            fontSize: 24,
            letterSpacing: 0.5,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onGetPremium,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF),
                foregroundColor: const Color(0xFF000000),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Get ExtraPlus (from K89 ZMW)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 11),
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
                decoration: BoxDecoration(
                  // color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const _ComparisonHeader(),
                    const SizedBox(height: 8),
                _ComparisonRow(
                  label: 'Never run out of swipes',
                  freeIncluded: false,
                  premiumIncluded: true,
                ),
                _ComparisonRow(
                  label: 'Bonus credits on credit purchases',
                  freeIncluded: false,
                  premiumIncluded: true,
                ),
                _ComparisonRow(
                  label: 'Remove ads',
                  freeIncluded: false,
                  premiumIncluded: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onAllFeatures,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'All Features',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox()),
                    const Expanded(child: Center(child: _MyPlanBadge())),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyPlanBadge extends StatelessWidget {
  const _MyPlanBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 1),
        borderRadius: BorderRadius.circular(999),
        // border: Border.all(
        //   color: Colors.white.withValues(alpha: 0.45),
        //   width: 1,
        // ),
      ),
      child: const Text(
        'My plan',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// “Extra” w700 + “plus” w400 (ExtraPlus branding).
class _ExtraPlusLabel extends StatelessWidget {
  const _ExtraPlusLabel({
    required this.fontSize,
    this.letterSpacing = 0,
  });

  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontFamily: AppTypography.manropeFamily,
      letterSpacing: letterSpacing,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Extra',
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 3, child: SizedBox.shrink()),
        const Expanded(
          child: Center(
            child: Text(
              'Free',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: _ExtraPlusLabel(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.freeIncluded,
    required this.premiumIncluded,
  });

  final String label;
  final bool freeIncluded;
  final bool premiumIncluded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                freeIncluded ? Icons.check : Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                premiumIncluded ? Icons.check : Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
