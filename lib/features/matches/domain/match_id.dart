/// Stable Firestore document id for a pair of users.
String matchIdForUsers(String uidA, String uidB) {
  final sortedIds = [uidA, uidB]..sort();
  return sortedIds.join('_');
}
