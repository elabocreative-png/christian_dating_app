import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/models/profile_photo_urls.dart';
import 'package:christian_dating_app/core/widgets/profile_photo_placeholder.dart';

/// Circular avatar using [photoThumbs] when available (lists, chat header).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.userData,
    this.radius = 40,
    this.index = 0,
    this.backgroundColor,
    this.iconColor,
    this.iconSize,
  });

  final Map<String, dynamic> userData;
  final double radius;
  final int index;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final url = ProfilePhotoUrls.thumbAt(userData, index: index);
    final size = radius * 2;
    final bg = backgroundColor ?? ProfilePhotoPlaceholder.backgroundColor;
    final gender = userData['gender']?.toString();
    final placeholder = GenderSilhouettePlaceholder(
      gender: gender,
      backgroundColor: bg,
      style: GenderSilhouetteStyle.avatar,
    );

    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: ClipOval(child: SizedBox(width: size, height: size, child: placeholder)),
      );
    }

    final cacheWidth =
        (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(48, 512);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              placeholder,
              Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                filterQuality: FilterQuality.medium,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox.shrink();
                },
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
