import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:christian_dating_app/core/theme/app_icons.dart';

/// Brand teal used across the app (buttons, accents, progress, etc.).
const Color kBrandAccent = Color(0xFF29B8D8);

/// Android OEM 3-button navigation bar icon color.
const Color kSystemNavigationBarIconColor = Color(0xFF404040);

/// Android OEM 3-button navigation bar background (Bumble-style subtle grey).
const Color kSystemNavigationBarBackground = Color(0xFFF2F2F2);

/// Match celebration / like accent orange.
const Color kMatchOrange = Color(0xFFED865E);

/// OEM nav bar fill painted in [MaterialApp.builder]; screens may override temporarily.
final ValueNotifier<Color> systemNavigationBarBackground =
    ValueNotifier<Color>(kSystemNavigationBarBackground);

/// Default edge-to-edge system chrome (transparent nav; grey/orange fill painted in builder).
const SystemUiOverlayStyle kAppSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.white,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);

/// Match popup: orange OEM nav bar with light icons.
const SystemUiOverlayStyle kMatchSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: kMatchOrange,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);

final ValueNotifier<SystemUiOverlayStyle> systemNavigationBarOverlayStyle =
    ValueNotifier<SystemUiOverlayStyle>(kAppSystemUiOverlayStyle);

void applyMatchSystemNavigationBar() {
  systemNavigationBarBackground.value = kMatchOrange;
  systemNavigationBarOverlayStyle.value = kMatchSystemUiOverlayStyle;
  SystemChrome.setSystemUIOverlayStyle(kMatchSystemUiOverlayStyle);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setSystemUIOverlayStyle(kMatchSystemUiOverlayStyle);
  });
}

void restoreAppSystemNavigationBar() {
  systemNavigationBarBackground.value = kSystemNavigationBarBackground;
  systemNavigationBarOverlayStyle.value = kAppSystemUiOverlayStyle;
  SystemChrome.setSystemUIOverlayStyle(kAppSystemUiOverlayStyle);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setSystemUIOverlayStyle(kAppSystemUiOverlayStyle);
  });
}

/// Bottom navigation bar active tab icon color.
const Color kBottomNavActiveColor = Color(0xFF444444);

/// Bottom navigation bar inactive tab icon color.
const Color kBottomNavInactiveColor = Color(0xFF838383);

/// Renders a Figma-exported SVG from [assets/icons/].
///
/// Use [AppIcons] constants for paths, or pass [assetPath] directly.
/// Tint with [color] (solid-fill SVGs from Figma export best).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.width,
    this.height,
    this.color,
    this.colorMapper,
    this.semanticLabel,
    this.fit = BoxFit.contain,
  });

  /// Shorthand: `AppIcon.named(AppIcons.heartFilled, ...)`.
  factory AppIcon.named(
    String assetPath, {
    Key? key,
    double size = 24,
    double? width,
    double? height,
    Color? color,
    String? semanticLabel,
    BoxFit fit = BoxFit.contain,
  }) {
    return AppIcon(
      assetPath,
      key: key,
      size: size,
      width: width,
      height: height,
      color: color,
      semanticLabel: semanticLabel,
      fit: fit,
    );
  }

  /// Builds path from file name: `heart_filled` → `assets/icons/heart_filled.svg`.
  factory AppIcon.file(
    String fileName, {
    Key? key,
    double size = 24,
    double? width,
    double? height,
    Color? color,
    String? semanticLabel,
    BoxFit fit = BoxFit.contain,
  }) {
    return AppIcon(
      AppIcons.pathFor(fileName),
      key: key,
      size: size,
      width: width,
      height: height,
      color: color,
      semanticLabel: semanticLabel,
      fit: fit,
    );
  }

  final String assetPath;
  final double size;
  final double? width;
  final double? height;
  final Color? color;
  final ColorMapper? colorMapper;
  final String? semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;

    final picture = SvgPicture.asset(
      assetPath,
      width: w,
      height: h,
      fit: fit,
      colorMapper: colorMapper,
      colorFilter: colorMapper != null || color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );

    if (semanticLabel == null) return picture;

    return Semantics(
      label: semanticLabel,
      child: picture,
    );
  }
}

/// [IconButton] that uses an SVG asset instead of [Icon].
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.assetPath,
    required this.onPressed,
    this.iconSize = 24,
    this.color,
    this.padding,
    this.tooltip,
  });

  final String assetPath;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final icon = AppIcon(
      assetPath,
      size: iconSize,
      color: color ?? IconTheme.of(context).color,
    );

    final button = IconButton(
      onPressed: onPressed,
      padding: padding ?? const EdgeInsets.all(8),
      icon: icon,
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Maps black SVG fills/strokes to [replacement]; keeps white as-is.
class SvgBlackReplacementMapper extends ColorMapper {
  const SvgBlackReplacementMapper({required this.replacement});

  final Color replacement;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color.a == 0) return color;
    if (_isWhite(color)) return color;
    if (_isBlack(color)) return replacement;
    return color;
  }

  static bool _isWhite(Color color) {
    final r = (color.r * 255.0).round();
    final g = (color.g * 255.0).round();
    final b = (color.b * 255.0).round();
    return r >= 240 && g >= 240 && b >= 240;
  }

  static bool _isBlack(Color color) {
    final r = (color.r * 255.0).round();
    final g = (color.g * 255.0).round();
    final b = (color.b * 255.0).round();
    return r <= 20 && g <= 20 && b <= 20;
  }
}

/// Bottom-nav unselected grey; maps black SVG fills/strokes, keeps white as-is.
class UnselectedNavColorMapper extends SvgBlackReplacementMapper {
  const UnselectedNavColorMapper({
    super.replacement = kBottomNavInactiveColor,
  });
}

/// Bottom-nav selected tab; maps black only, keeps white as-is.
class SelectedNavColorMapper extends SvgBlackReplacementMapper {
  const SelectedNavColorMapper({
    super.replacement = kBottomNavActiveColor,
  });
}

/// Verified badge (orange); maps black only, keeps white as-is.
class VerifiedBadgeColorMapper extends SvgBlackReplacementMapper {
  const VerifiedBadgeColorMapper({
    super.replacement = const Color(0xFFED865E),
  });
}
