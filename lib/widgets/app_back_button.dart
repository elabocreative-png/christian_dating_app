import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS-style back chevron used consistently across the app (all platforms).
abstract final class AppBackIcon {
  static const IconData data = CupertinoIcons.back;

  static Widget icon({Color? color, double? size}) {
    return Icon(data, color: color, size: size);
  }
}

/// Drop-in replacement for Material [BackButton] using [CupertinoIcons.back].
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.color, this.onPressed});

  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ??
        IconTheme.of(context).color ??
        Theme.of(context).appBarTheme.iconTheme?.color ??
        Theme.of(context).iconTheme.color;

    return IconButton(
      icon: AppBackIcon.icon(color: iconColor),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(48, 48),
        alignment: Alignment.center,
      ),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
