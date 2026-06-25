/// Default relationship intent when none is saved.
const String kDefaultLookingFor = 'Friendship';

const List<String> kLookingForOptions = [
  'Marriage',
  'Relationship',
  'Friendship',
];

String _canonicalLookingFor(String? value) {
  final t = value?.trim() ?? '';
  if (t == 'Serious Relationship') return 'Relationship';
  return t;
}

/// Label for profile cards and forms; empty/null → [kDefaultLookingFor].
String displayLookingForLabel(dynamic value) {
  final t = _canonicalLookingFor(value?.toString());
  if (t.isEmpty) return kDefaultLookingFor;
  return t;
}

/// Value to persist when the user has not chosen an option.
String resolvedLookingForForSave(String? value) {
  final t = _canonicalLookingFor(value);
  if (t.isEmpty) return kDefaultLookingFor;
  return t;
}

bool isValidLookingFor(String? value) {
  final t = _canonicalLookingFor(value);
  return kLookingForOptions.contains(t);
}
