const String kKidsHaveKids = 'Have Kids';
const String kKidsDontHaveKids = "Don't have kids";

const List<String> kKidsOptions = [kKidsHaveKids, kKidsDontHaveKids];

const List<String> kBodyTypeOptions = [
  'Slim',
  'Average',
  'Curvy',
  'Chubby',
  'Fit',
];

String? canonicalKids(String? raw) {
  final t = raw?.trim() ?? '';
  if (t == kKidsHaveKids) return kKidsHaveKids;
  if (t == kKidsDontHaveKids ||
      t == 'Dont have kids' ||
      t == "Don't have kids") {
    return kKidsDontHaveKids;
  }
  return null;
}

String? canonicalBodyType(String? raw) {
  final t = raw?.trim() ?? '';
  if (kBodyTypeOptions.contains(t)) return t;
  return null;
}

const List<String> kPersonalityOptions = [
  'Introvert',
  'Extrovert',
  'Ambivert',
];

String? canonicalPersonality(String? raw) {
  final t = raw?.trim() ?? '';
  if (kPersonalityOptions.contains(t)) return t;
  return null;
}

const List<String> kTattoosOptions = [
  'None',
  'Many',
  'Some',
];

String? canonicalTattoos(String? raw) {
  final t = raw?.trim() ?? '';
  if (kTattoosOptions.contains(t)) return t;
  return null;
}
