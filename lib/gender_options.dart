const String kGenderMale = 'Male';
const String kGenderFemale = 'Female';

const List<String> kGenderOptions = [kGenderMale, kGenderFemale];

String? canonicalGender(String? raw) {
  final t = raw?.trim() ?? '';
  if (t == kGenderMale || t == kGenderFemale) return t;
  return null;
}
