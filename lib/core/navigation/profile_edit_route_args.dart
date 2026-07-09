import 'package:flutter/services.dart';

/// Route arguments for [ProfileTextFieldScreen] via GoRouter `extra`.
final class ProfileTextFieldRouteArgs {
  const ProfileTextFieldRouteArgs({
    required this.title,
    required this.initial,
    this.hint,
    this.subtitle,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });

  final String title;
  final String initial;
  final String? hint;
  final String? subtitle;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
}

/// Route arguments for [ProfileOptionPickerScreen] via GoRouter `extra`.
final class ProfileOptionPickerRouteArgs {
  const ProfileOptionPickerRouteArgs({
    required this.title,
    required this.options,
    this.selected,
  });

  final String title;
  final List<String> options;
  final String? selected;
}

/// Route arguments for [OnboardingPromptAnswerScreen] via GoRouter `extra`.
final class ProfilePromptAnswerRouteArgs {
  const ProfilePromptAnswerRouteArgs({
    required this.question,
    this.initialAnswer = '',
    this.showRemove = false,
  });

  final String question;
  final String initialAnswer;
  final bool showRemove;
}
