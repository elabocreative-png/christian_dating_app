import 'dart:math';

import 'package:flutter/material.dart';

import 'church_attendance_options.dart';
import 'denomination_options.dart';
import 'faith_options.dart';
import 'gender_options.dart';
import 'relationship_intent.dart';

/// Resolved profile fields for cards — fills missing values with stable
/// placeholders so mandatory sections always render.
class ProfileDisplayValues {
  const ProfileDisplayValues({
    required this.lookingFor,
    required this.faithLevel,
    required this.gender,
    required this.churchAttendance,
    required this.denomination,
    required this.heroDistanceKm,
    this.distanceKm,
  });

  final String lookingFor;
  final String faithLevel;
  final String gender;
  final String churchAttendance;
  final String denomination;
  /// Always resolved for the hero distance pill.
  final double heroDistanceKm;
  /// Location section — only when device location is available.
  final double? distanceKm;
}

abstract final class ProfileDisplayResolver {
  static ProfileDisplayValues resolve({
    required Map<String, dynamic> user,
    String? profileUserId,
    required bool locationServicesEnabled,
  }) {
    final random = Random(_seedForUser(user, profileUserId));
    final heroDistanceKm = _resolveHeroDistanceKm(user, random);

    return ProfileDisplayValues(
      lookingFor: _resolveLookingFor(user, random),
      faithLevel: _resolveFaithLevel(user, random),
      gender: _resolveGender(user, random),
      churchAttendance: _resolveChurchAttendance(user, random),
      denomination: _resolveDenomination(user, random),
      heroDistanceKm: heroDistanceKm,
      distanceKm: locationServicesEnabled ? heroDistanceKm : null,
    );
  }

  static int _seedForUser(Map<String, dynamic> user, String? profileUserId) {
    if (profileUserId != null && profileUserId.isNotEmpty) {
      return profileUserId.hashCode;
    }
    final name = user['name']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    return Object.hash(name, email);
  }

  static String _resolveLookingFor(Map<String, dynamic> user, Random random) {
    final raw = user['lookingFor']?.toString();
    if (isValidLookingFor(raw)) return displayLookingForLabel(raw);
    return kLookingForOptions[random.nextInt(kLookingForOptions.length)];
  }

  static String _resolveFaithLevel(Map<String, dynamic> user, Random random) {
    final label = canonicalFaithLevel(user['faithLevel']?.toString());
    if (label != null) return label;
    return kFaithLevelOptions[random.nextInt(kFaithLevelOptions.length)];
  }

  static String _resolveGender(Map<String, dynamic> user, Random random) {
    final label = canonicalGender(user['gender']?.toString());
    if (label != null) return label;
    return kGenderOptions[random.nextInt(kGenderOptions.length)];
  }

  static String _resolveChurchAttendance(
    Map<String, dynamic> user,
    Random random,
  ) {
    final canonical =
        canonicalChurchAttendance(user['churchAttendance']?.toString());
    if (canonical != null) return canonical;
    return kChurchAttendanceOptions[
        random.nextInt(kChurchAttendanceOptions.length)];
  }

  static String _resolveDenomination(Map<String, dynamic> user, Random random) {
    final raw = user['denomination']?.toString().trim() ?? '';
    if (raw.isNotEmpty) return displayDenominationLabel(raw);
    return kDenominationOptions[random.nextInt(kDenominationOptions.length)];
  }

  static double _resolveHeroDistanceKm(Map<String, dynamic> user, Random random) {
    final rawDistance = user['distanceKm'];
    if (rawDistance is num) return rawDistance.toDouble();

    // Placeholder distance until profile coordinates exist.
    return 2 + random.nextInt(29).toDouble();
  }
}

String genderDisplayLabel(String gender) {
  return gender == kGenderFemale ? 'Woman' : 'Man';
}

String genderDisplayEmoji(String gender) {
  return gender == kGenderFemale ? '👩' : '👨';
}

IconData genderDisplayIcon(String gender) {
  return gender == kGenderFemale ? Icons.face_3 : Icons.face_6;
}
