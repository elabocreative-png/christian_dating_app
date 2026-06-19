import 'package:flutter/material.dart';

import '../app_icons.dart';
import 'app_icon.dart';

/// Orange pill shown on the discovery hero, directly below the location row.
class HeroInlineSnackBar extends StatelessWidget {
  const HeroInlineSnackBar({
    super.key,
    this.message = 'You already liked this',
    this.iconAsset = AppIcons.heartSolid,
  });

  final String message;
  final String iconAsset;

  static const Color backgroundColor = Color(0xFFED865E);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 46,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    iconAsset,
                    size: 16,
                    colorMapper: const SvgBlackReplacementMapper(
                      replacement: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
