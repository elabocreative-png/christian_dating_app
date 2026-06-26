import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/core/widgets/profile_avatar.dart';

/// First item in the Chats tab “New Connections” row — opens Liked You.
class LikesStripChip extends StatelessWidget {
  const LikesStripChip({
    super.key,
    required this.likesCount,
    required this.onTap,
    this.userData,
  });

  final int likesCount;
  final Map<String, dynamic>? userData;
  final VoidCallback onTap;

  static const double _avatarRadius = 36;
  static const double _strokeWidth = 1.575;
  static const double _avatarGap = 2.925;
  static const double _ringSize =
      _avatarRadius * 2 + _strokeWidth * 2 + _avatarGap * 2;
  static const double _countBadgeSize = 30;

  Widget _buildCountBadge(String countLabel) {
    final compact = countLabel.length > 2;

    return Container(
      height: _countBadgeSize,
      constraints: const BoxConstraints(minWidth: _countBadgeSize),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFED865E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            AppIcons.heartSolid,
            size: compact ? 10 : 12,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            countLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 13,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countLabel = likesCount > 99 ? '99+' : '$likesCount';
    final placeholderIconSize = 38 * (_avatarRadius / 36);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _ringSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _ringSize,
                height: _ringSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: _ringSize,
                      height: _ringSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFFED865E),
                          width: _strokeWidth,
                        ),
                      ),
                      child: Center(
                        child: userData == null
                            ? CircleAvatar(
                                radius: _avatarRadius,
                                backgroundColor: Colors.grey.shade300,
                                child: Icon(
                                  Icons.person,
                                  size: placeholderIconSize,
                                  color: Colors.grey.shade500,
                                ),
                              )
                            : ClipOval(
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 6,
                                    sigmaY: 6,
                                  ),
                                  child: ProfileAvatar(
                                    userData: userData!,
                                    radius: _avatarRadius,
                                    backgroundColor: Colors.grey.shade300,
                                    iconColor: Colors.grey.shade600,
                                    iconSize: placeholderIconSize,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (likesCount > 0) _buildCountBadge(countLabel),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Likes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
