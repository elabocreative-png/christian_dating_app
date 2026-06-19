import '../discovery_preferences.dart';
import '../gender_options.dart';
import '../relationship_intent.dart';

/// Validation for each onboarding step and profile completion.
class OnboardingRequirements {
  OnboardingRequirements._();

  static const int minPhotos = 0;

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Enter your name';
    if (name.trim().length < 2) return 'Name is too short';
    return null;
  }

  static String? validateBirthday(int? age) {
    if (age == null || age < 18 || age > 80) {
      return 'Enter a valid birthday (you must be 18 or older)';
    }
    return null;
  }

  static String? validateGender(String? gender) {
    if (canonicalGender(gender) == null) return 'Select your gender';
    return null;
  }

  static String? validateDenomination(String? denomination) {
    if (denomination == null || denomination.trim().isEmpty) {
      return 'Select your denomination';
    }
    return null;
  }

  static String? validateLookingFor(String? lookingFor) {
    if (!isValidLookingFor(lookingFor)) {
      return 'Select what you are looking for';
    }
    return null;
  }

  static String? validatePhotos(int filledCount) {
    if (filledCount < minPhotos) {
      return 'Add at least one photo to continue';
    }
    return null;
  }

  static String? validatePrompts(List<Map<String, String>> prompts) {
    final hasAnswer = prompts.any((p) => p['answer']?.trim().isNotEmpty == true);
    if (!hasAnswer) return 'Add at least one prompt answer';
    return null;
  }

  static String? validateDiscoveryMode(String? mode) {
    if (mode != kDiscoveryModeDating && mode != kDiscoveryModeSocial) {
      return 'Choose Dating or Social';
    }
    return null;
  }

  static String? validateLocation({
    required bool hasLocation,
  }) {
    if (!hasLocation) return 'Allow location access to continue';
    return null;
  }

  /// Required before onboarding can finish (age, denomination, intent).
  static String? validateRequiredBeforeFinish({
    required int? age,
    required String? denomination,
    required String? lookingFor,
  }) {
    return validateBirthday(age) ??
        validateDenomination(denomination) ??
        validateLookingFor(lookingFor);
  }

  static bool meetsProfileCompletionCriteria(Map<String, dynamic> data) {
    bool nonEmpty(dynamic v) {
      if (v == null) return false;
      if (v is String) return v.trim().isNotEmpty;
      if (v is num) return v != 0;
      if (v is List) return v.isNotEmpty;
      return true;
    }

    if (!nonEmpty(data['name'])) return false;
    if (!nonEmpty(data['age'])) return false;
    if (!nonEmpty(data['denomination'])) return false;
    if (!isValidLookingFor(data['lookingFor']?.toString())) return false;
    if (data['latitude'] == null && !nonEmpty(data['city'])) return false;

    final prompts = data['prompts'];
    if (prompts is! List || prompts.isEmpty) return false;
    final hasAnswer = prompts.any((p) {
      if (p is Map) {
        final ans = p['answer'];
        return ans is String && ans.trim().isNotEmpty;
      }
      return false;
    });
    return hasAnswer;
  }
}
