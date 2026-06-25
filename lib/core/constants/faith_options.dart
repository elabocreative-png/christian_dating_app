const List<String> kFaithLevelOptions = [
  'New',
  'Growing',
  'Strong',
  'Recovering',
];

String? canonicalFaithLevel(String? raw) {
  final t = raw?.trim() ?? '';
  if (kFaithLevelOptions.contains(t)) return t;
  return null;
}
