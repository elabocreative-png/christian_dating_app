import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/features/profile/domain/profile_completion.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';

/// Name (and optionally ", age") with an optional verified badge inline.
class VerifiedNameAge extends StatelessWidget {
  const VerifiedNameAge({
    super.key,
    required this.userData,
    required this.textStyle,
    this.includeAge = true,
    this.iconSize,
    this.maxLines = 2,
  });

  final Map<String, dynamic> userData;
  final TextStyle textStyle;
  final bool includeAge;
  final double? iconSize;
  final int maxLines;

  List<InlineSpan> _nameAgeSpans(String displayName) {
    final spans = <InlineSpan>[
      TextSpan(
        text: displayName,
        style: textStyle.copyWith(
          fontFamily: AppTypography.manropeFamily,
          fontWeight: FontWeight.w800,
        ),
      ),
    ];

    if (includeAge) {
      final age = userData['age'];
      final ageStr = age == null ? '' : age.toString();
      if (ageStr.isNotEmpty) {
        spans.add(
          TextSpan(
            text: ', $ageStr',
            style: textStyle.copyWith(
              fontFamily: AppTypography.manropeFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final name = (userData['name'] ?? 'User').toString().trim();
    final displayName = name.isEmpty ? 'User' : name;

    final verified = isProfileFullyComplete(userData);
    final resolvedIconSize = iconSize ??
        (textStyle.fontSize != null ? textStyle.fontSize! - 1 : 17);

    final children = <InlineSpan>[
      ..._nameAgeSpans(displayName),
      if (verified)
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: AppIcon(
              AppIcons.verifiedSolid,
              size: resolvedIconSize + 1,
              colorMapper: const VerifiedBadgeColorMapper(),
            ),
          ),
        ),
    ];

    return Text.rich(
      TextSpan(style: textStyle, children: children),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
