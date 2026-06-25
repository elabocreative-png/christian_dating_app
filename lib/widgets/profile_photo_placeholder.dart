import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:christian_dating_app/core/theme/app_illustrations.dart';
import 'package:christian_dating_app/core/constants/gender_options.dart';

const Color kProfilePhotoPlaceholderBg = Color(0xFFEEEEEE);

/// How the gender silhouette fills its container.
enum GenderSilhouetteStyle {
  /// Discovery / liked-you cards: full figure visible with headroom on top.
  heroCard,
  /// Full-body silhouette cropped to fill a frame.
  fillFrame,
  /// Small circular avatars (profile tab, chat).
  avatar,
}

/// Grey card background + gender silhouette (discovery hero empty state).
class GenderSilhouettePlaceholder extends StatelessWidget {
  const GenderSilhouettePlaceholder({
    super.key,
    this.gender,
    this.backgroundColor = kProfilePhotoPlaceholderBg,
    this.style = GenderSilhouetteStyle.fillFrame,
  });

  final String? gender;
  final Color backgroundColor;
  final GenderSilhouetteStyle style;

  static const double _heroTopInsetFraction = 0.12;

  String get _assetPath {
    final canonical = canonicalGender(gender);
    final isMale = canonical == kGenderMale;
    if (style == GenderSilhouetteStyle.avatar) {
      return isMale ? AppIllustrations.avatarMale : AppIllustrations.avatarFemale;
    }
    if (isMale) {
      return AppIllustrations.maleSilhouette;
    }
    return AppIllustrations.femaleSilhouette;
  }

  @override
  Widget build(BuildContext context) {
    if (style == GenderSilhouetteStyle.heroCard) {
      return ColoredBox(
        color: backgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topInset = constraints.maxHeight * _heroTopInsetFraction;
            return Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SvgPicture.asset(
                  _assetPath,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight - topInset,
                ),
              ),
            );
          },
        ),
      );
    }

    if (style == GenderSilhouetteStyle.avatar) {
      return ColoredBox(
        color: backgroundColor,
        child: SvgPicture.asset(
          _assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return ColoredBox(
      color: backgroundColor,
      child: SvgPicture.asset(
        _assetPath,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

/// Grey background + person icon (same as profiles with no photos).
class ProfilePhotoPlaceholder extends StatelessWidget {
  const ProfilePhotoPlaceholder({
    super.key,
    this.iconSize,
    this.gender,
    this.useGenderSilhouette = false,
  });

  static const Color backgroundColor = kProfilePhotoPlaceholderBg;
  static const Color iconColor = Color(0xFFD2D2D2);

  final double? iconSize;
  final String? gender;
  final bool useGenderSilhouette;

  static double iconSizeForBox(double shortestSide) {
    if (!shortestSide.isFinite || shortestSide <= 0) return 80;
    return (shortestSide * 0.42).clamp(48.0, 350.0);
  }

  @override
  Widget build(BuildContext context) {
    if (useGenderSilhouette) {
      return GenderSilhouettePlaceholder(
        gender: gender,
        style: GenderSilhouetteStyle.fillFrame,
      );
    }

    if (iconSize != null) {
      return SizedBox.expand(
        child: ColoredBox(
          color: backgroundColor,
          child: Center(
            child: Icon(Icons.person, size: iconSize, color: iconColor),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final size = iconSizeForBox(side);
        return SizedBox.expand(
          child: ColoredBox(
            color: backgroundColor,
            child: Center(
              child: Icon(Icons.person, size: size, color: iconColor),
            ),
          ),
        );
      },
    );
  }
}

/// Network image with [ProfilePhotoPlaceholder] visible while loading or on error.
class NetworkProfileImage extends StatelessWidget {
  const NetworkProfileImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.iconSize,
    this.gender,
    this.useGenderSilhouette = false,
    this.silhouetteStyle = GenderSilhouetteStyle.fillFrame,
    this.cacheWidth,
    this.filterQuality = FilterQuality.low,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? iconSize;
  final String? gender;
  final bool useGenderSilhouette;
  final GenderSilhouetteStyle silhouetteStyle;
  final int? cacheWidth;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    Widget placeholder(double? resolvedIconSize) {
      if (useGenderSilhouette) {
        return GenderSilhouettePlaceholder(
          gender: gender,
          style: silhouetteStyle,
        );
      }
      return ProfilePhotoPlaceholder(iconSize: resolvedIconSize);
    }

    Widget stack(double? resolvedIconSize) {
      return Stack(
        fit: StackFit.expand,
        children: [
          placeholder(resolvedIconSize),
          Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: cacheWidth,
            filterQuality: filterQuality,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox.shrink();
            },
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ],
      );
    }

    if (iconSize != null) return stack(iconSize);
    return LayoutBuilder(
      builder: (context, constraints) {
        return stack(
          ProfilePhotoPlaceholder.iconSizeForBox(
            constraints.biggest.shortestSide,
          ),
        );
      },
    );
  }
}
