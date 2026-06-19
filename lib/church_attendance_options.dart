const List<String> kChurchAttendanceOptions = [
  'Attend weekly',
  'Once a month',
  'Twice a month',
  'Attend online',
  'Few times a year',
  'Not churched',
];

const Map<String, String> _legacyChurchAttendanceLabels = {
  'Weekly': 'Attend weekly',
  'Occasionally': 'Twice a month',
  'Rarely': 'Few times a year',
};

String? canonicalChurchAttendance(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  if (kChurchAttendanceOptions.contains(t)) return t;
  return _legacyChurchAttendanceLabels[t];
}
