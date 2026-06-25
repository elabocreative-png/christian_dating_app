import 'package:flutter/material.dart';

import 'package:christian_dating_app/features/profile/domain/height_utils.dart';
import 'package:christian_dating_app/widgets/app_icon.dart';
import 'package:christian_dating_app/widgets/app_back_button.dart';

/// Full-screen height picker with slider + tooltip (Bumble-style).
class ProfileHeightScreen extends StatefulWidget {
  const ProfileHeightScreen({
    super.key,
    this.initialHeightInches,
  });

  final int? initialHeightInches;

  static const Color kAccent = kBrandAccent;
  static const Color kInactiveTrack = Color(0xFFE0E0E4);

  static Future<int?> push(
    BuildContext context, {
    int? initialHeightInches,
  }) {
    return Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileHeightScreen(
          initialHeightInches: initialHeightInches,
        ),
      ),
    );
  }

  @override
  State<ProfileHeightScreen> createState() => _ProfileHeightScreenState();
}

class _ProfileHeightScreenState extends State<ProfileHeightScreen> {
  late double _inches;

  @override
  void initState() {
    super.initState();
    _inches = (widget.initialHeightInches ?? kDefaultHeightInches).toDouble();
  }

  void _saveAndPop() {
    Navigator.pop(context, _inches.round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(onPressed: _saveAndPop),
        title: const Text(
          'Height',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const thumbRadius = 12.0;
            final trackWidth = constraints.maxWidth - thumbRadius * 2;
            final fraction = (_inches - kMinHeightInches) /
                (kMaxHeightInches - kMinHeightInches);
            final thumbCenterX = thumbRadius + fraction * trackWidth;
            const tooltipWidth = 72.0;
            final tooltipLeft =
                (thumbCenterX - tooltipWidth / 2).clamp(0.0, constraints.maxWidth - tooltipWidth);

            return SizedBox(
              height: 88,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: tooltipLeft,
                    top: 0,
                    width: tooltipWidth,
                    child: _HeightTooltip(
                      label: formatHeightInches(_inches.round()),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: ProfileHeightScreen.kAccent,
                        inactiveTrackColor: ProfileHeightScreen.kInactiveTrack,
                        thumbColor: ProfileHeightScreen.kAccent,
                        overlayColor:
                            ProfileHeightScreen.kAccent.withValues(alpha: 0.14),
                        trackHeight: 4,
                        trackShape: const RoundedRectSliderTrackShape(),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
                      ),
                      child: Slider(
                        value: _inches,
                        min: kMinHeightInches.toDouble(),
                        max: kMaxHeightInches.toDouble(),
                        divisions: kMaxHeightInches - kMinHeightInches,
                        onChanged: (v) => setState(() => _inches = v),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeightTooltip extends StatelessWidget {
  const _HeightTooltip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(14, 7),
          painter: _TooltipCaretPainter(),
        ),
      ],
    );
  }
}

class _TooltipCaretPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
