/// Height stored as total inches (e.g. 67 → 5' 7").
const int kMinHeightInches = 48; // 4'0"
const int kMaxHeightInches = 96; // 8'0"
const int kDefaultHeightInches = 67; // 5'7"

String formatHeightInches(int inches) {
  final clamped = inches.clamp(kMinHeightInches, kMaxHeightInches);
  final feet = clamped ~/ 12;
  final remainder = clamped % 12;
  return "$feet' $remainder\"";
}

int? parseHeightInches(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    final n = value.round();
    if (n >= kMinHeightInches && n <= kMaxHeightInches) return n;
    return null;
  }
  return null;
}
