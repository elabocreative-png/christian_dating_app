import 'package:flutter/material.dart';

import 'app_icon.dart';

/// Full-width pill choice used across onboarding steps.
class OnboardingPillButton extends StatelessWidget {
  const OnboardingPillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _border = Color(0xFFE0E0E4);
  static const Color _selectedBorder = kBrandAccent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? _selectedBorder : _border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: selected ? _selectedBorder : const Color(0xFFB0B0B8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
