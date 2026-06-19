import 'package:flutter/material.dart';

/// Bundled [assets/fonts/Manrope-Variable.ttf] (wght axis ~200–800).
///
/// Use [manrope] or the semantic helpers so [FontWeight] maps to real masters:
/// ExtraLight 200, Light 300, Regular 400, Medium 500, SemiBold 600,
/// Bold 700, ExtraBold 800.
abstract final class AppTypography {
  AppTypography._();

  static const String manropeFamily = 'Manrope';

  /// Manrope with optional overrides. Inherits [textStyle] weight when set.
  static TextStyle manrope({
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return (textStyle ?? const TextStyle()).copyWith(
      fontFamily: manropeFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  /// Applies [manropeFamily] to Material [textTheme] entries (keeps each weight).
  static TextTheme manropeTextTheme(TextTheme base) {
    return TextTheme(
      displayLarge: manrope(textStyle: base.displayLarge),
      displayMedium: manrope(textStyle: base.displayMedium),
      displaySmall: manrope(textStyle: base.displaySmall),
      headlineLarge: manrope(textStyle: base.headlineLarge),
      headlineMedium: manrope(textStyle: base.headlineMedium),
      headlineSmall: manrope(textStyle: base.headlineSmall),
      titleLarge: manrope(textStyle: base.titleLarge),
      titleMedium: manrope(textStyle: base.titleMedium),
      titleSmall: manrope(textStyle: base.titleSmall),
      bodyLarge: manrope(textStyle: base.bodyLarge),
      bodyMedium: manrope(textStyle: base.bodyMedium),
      bodySmall: manrope(textStyle: base.bodySmall),
      labelLarge: manrope(textStyle: base.labelLarge),
      labelMedium: manrope(textStyle: base.labelMedium),
      labelSmall: manrope(textStyle: base.labelSmall),
    );
  }

  // --- Semantic weights (match Figma / Google Fonts naming) ---

  static TextStyle extraLight({
    double fontSize = 14,
    Color color = Colors.black87,
    double? height,
  }) =>
      manrope(
        fontSize: fontSize,
        fontWeight: FontWeight.w200,
        color: color,
        height: height,
      );

  static TextStyle light({
    double fontSize = 14,
    Color color = Colors.black87,
    double? height,
  }) =>
      manrope(
        fontSize: fontSize,
        fontWeight: FontWeight.w300,
        color: color,
        height: height,
      );

  static TextStyle regular({
    double fontSize = 14,
    Color color = Colors.black87,
    double? height,
  }) =>
      manrope(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        height: height,
      );

  static TextStyle medium({
    double fontSize = 14,
    Color color = Colors.black87,
    double? height,
  }) =>
      manrope(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
        height: height,
      );

  static TextStyle semiBold({
    double fontSize = 14,
    Color color = Colors.black87,
    double? height,
  }) =>
      manrope(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        height: height,
      );

  static TextStyle bold({
    double fontSize = 14,
    Color color = Colors.black87,
    double? height,
  }) =>
      manrope(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        height: height,
      );

  static TextStyle extraBold({
    double fontSize = 14,
    Color color = Colors.black87,
    double? height,
  }) =>
      manrope(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: color,
        height: height,
      );

  /// Title on empty states (discovery, chats, liked you).
  static const Color emptyStateTitleColor = Color(0xFF757575);

  static TextStyle emptyStateTitle() => bold(
        fontSize: 18,
        color: emptyStateTitleColor,
        height: 1.35,
      );

  static const Color emptyStateBodyColor = Color(0xFF616161);

  static TextStyle emptyStateBody() => regular(
        fontSize: 13,
        color: emptyStateBodyColor,
        height: 1.45,
      );

  /// Times New Roman for discovery empty-state titles and similar serif UI.
  static TextStyle timesNewRomanTitle({
    double fontSize = 18,
    Color color = const Color(0xFF686868),
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.25,
  }) {
    return TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Section titles on white profile info cards (Bio, Church, My Basics, etc.).
  static const Color infoCardTitleColor = Color(0xFF7C7975);

  static TextStyle infoCardTitle() => semiBold(
        fontSize: 15,
        color: infoCardTitleColor,
      );

  // --- Text fields ---

  static const Color fieldHintColor = Color(0xFF9E9E9E);
  static const Color fieldLabelColor = Color(0xDE000000);

  /// Theme defaults for [InputDecoration] hint and label text.
  static InputDecorationTheme inputDecorationTheme() => InputDecorationTheme(
        hintStyle: fieldHint(),
        labelStyle: fieldLabel(),
        floatingLabelStyle: fieldLabel(),
      );

  static TextStyle fieldHint({
    double fontSize = 16,
    Color color = fieldHintColor,
  }) =>
      regular(fontSize: fontSize, color: color);

  static TextStyle fieldLabel({
    double fontSize = 16,
    Color color = fieldLabelColor,
  }) =>
      regular(fontSize: fontSize, color: color);

  /// Auth login / signup outlined fields.
  static TextStyle authFieldInput() =>
      regular(fontSize: 16, color: Colors.black87);

  /// Full-screen profile field editor (underline).
  static TextStyle profileFieldInput() =>
      medium(fontSize: 16, color: Colors.black87);

  /// Onboarding name / church underline fields.
  static TextStyle onboardingFieldInput() =>
      medium(fontSize: 22, color: Colors.black87);

  /// Bio, prompts, and edit-profile multiline boxes.
  static TextStyle multilineFieldInput() =>
      regular(fontSize: 16, color: Colors.black87);

  /// Chat message composer.
  static TextStyle chatComposerInput() =>
      regular(fontSize: 16, color: Colors.black87);

  /// Match list name search.
  static TextStyle searchFieldInput() =>
      regular(fontSize: 17, color: Colors.black87);

  /// Text field inside [AppDialog].
  static TextStyle dialogFieldInput() =>
      regular(fontSize: 16, color: Colors.black87);

  /// Invisible capture field behind custom birthday digits UI.
  static TextStyle hiddenCaptureField() => manrope(
        fontSize: 1,
        height: 1,
        color: Colors.transparent,
      );

  /// Prompt answer text on profile cards.
  static TextStyle promptAnswer({
    double fontSize = 22,
    Color color = Colors.black87,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.3,
    );
  }
}
