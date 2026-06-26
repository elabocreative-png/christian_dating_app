import 'package:flutter/material.dart';

import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';

/// Dating / Social pill toggle for the discovery app bar.
class DiscoveryModeToggle extends StatelessWidget {
  const DiscoveryModeToggle({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  static const Color _pillColor = Color(0xFFF2F2F2);
  static const Color datingSelectedFill = Color(0xFFED865E);
  static const Color socialSelectedFill = kBrandAccent;
  static const Color unselectedText = Color(0xFF8E8E93);
  static const Duration _animDuration = Duration(milliseconds: 280);

  static const double _segmentWidth = 78;
  static const double _segmentHeight = 28;

  final String mode;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDating = mode == kDiscoveryModeDating;
    final fillColor = isDating ? datingSelectedFill : socialSelectedFill;

    return Container(
      decoration: BoxDecoration(
        color: _pillColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: _segmentWidth * 2,
        height: _segmentHeight,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: _animDuration,
              curve: Curves.easeInOutCubic,
              alignment:
                  isDating ? Alignment.centerLeft : Alignment.centerRight,
              child: AnimatedContainer(
                duration: _animDuration,
                curve: Curves.easeInOutCubic,
                width: _segmentWidth,
                height: _segmentHeight,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(999),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withValues(alpha: 0.04),
                  //     blurRadius: 2,
                  //     offset: const Offset(0, 1),
                  //   ),
                  // ],
                ),
              ),
            ),
            Row(
              children: [
                _segment(
                  label: 'Dating',
                  selected: isDating,
                  onTap: () => onModeChanged(kDiscoveryModeDating),
                ),
                _segment(
                  label: 'Social',
                  selected: !isDating,
                  onTap: () => onModeChanged(kDiscoveryModeSocial),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: _segmentWidth,
      height: _segmentHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: _animDuration,
              curve: Curves.easeInOutCubic,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: selected ? Colors.white : unselectedText,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
