/// Pentecostal-only profile field: whether the user speaks in tongues.
const String kDenominationPentecostal = 'Pentecostal';

const String kTonguesSpeaksInTongues = 'Speaks in tongues';
const String kTonguesDoesNotSpeakInTongues = "Don't speak in tongues";

const List<String> kTonguesOptions = [
  kTonguesSpeaksInTongues,
  kTonguesDoesNotSpeakInTongues,
];

bool isPentecostalDenomination(String? denomination) {
  return denomination?.trim() == kDenominationPentecostal;
}

String? canonicalTongues(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  if (kTonguesOptions.contains(t)) return t;
  return null;
}

/// Firestore value: set when Pentecostal, otherwise omit / null.
String? tonguesForFirestore(String? denomination, String? tongues) {
  if (!isPentecostalDenomination(denomination)) return null;
  return canonicalTongues(tongues);
}
