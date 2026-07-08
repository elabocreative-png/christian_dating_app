/// Parses Firestore [Timestamp] values (or plain [DateTime]) without importing
/// `cloud_firestore` outside the data layer.
DateTime? firestoreDateTimeFrom(dynamic value) {
  if (value is DateTime) return value;
  try {
    return (value as dynamic)?.toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}

/// Epoch milliseconds for sorting; returns 0 when [value] is missing or unparsable.
int firestoreMillisFrom(dynamic value) {
  return firestoreDateTimeFrom(value)?.millisecondsSinceEpoch ?? 0;
}
