/// Faith identity options (aligned with onboarding reference list).
/// Includes `Adventist` for existing saved profiles that used the legacy label.
const List<String> kDenominationOptions = [
  'Agnostic',
  'Anglican',
  'Adventist',
  'Baptist',
  'Catholic',
  'Church of Christ',
  'Episcopalian',
  'Evangelical',
  'Lutheran',
  'Methodist',
  'Nazarene',
  'Non-Denominational',
  'Orthodox',
  'Pentecostal',
  'Presbyterian',
  'Other',
];

/// Empty or unset denomination reads as **Other** in profile UI.
String displayDenominationLabel(dynamic denominationField) {
  final t = denominationField?.toString().trim() ?? '';
  if (t.isEmpty) return 'Other';
  return t;
}
