import 'onboarding/onboarding_requirements.dart';

/// Profile completion as fraction (0..1) using the same key fields as [ProfileScreen].
double profileCompletionFraction(Map<String, dynamic> data) {
  bool nonEmpty(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is num) return v != 0;
    if (v is List) return v.isNotEmpty;
    return true;
  }

  final checks = <dynamic>[
    data['name'],
    data['age'],
    data['city'],
    data['denomination'],
    data['photos'],
  ];

  var total = checks.length;
  var filled = checks.where(nonEmpty).length;

  final prompts = data['prompts'];
  total += 1;
  if (prompts is List && prompts.isNotEmpty) {
    final hasAnswer = prompts.any((p) {
      if (p is Map) {
        final ans = p['answer'];
        return ans is String && ans.trim().isNotEmpty;
      }
      return false;
    });
    if (hasAnswer) filled += 1;
  }

  if (total == 0) return 0;
  return filled / total;
}

/// True when [profileCompletionFraction] is 100%.
bool isProfileFullyComplete(Map<String, dynamic> data) =>
    profileCompletionFraction(data) >= 1.0 ||
    OnboardingRequirements.meetsProfileCompletionCriteria(data);
