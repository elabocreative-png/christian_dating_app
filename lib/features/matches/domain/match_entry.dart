import 'package:christian_dating_app/core/utils/firestore_value_utils.dart';

/// A match document expressed in app types: its id and raw data map.
///
/// Structurally identical to the record used by the nav-badge providers, so the
/// two are interchangeable.
typedef MatchEntry = ({String id, Map<String, dynamic> data});

/// Sort key for a match (newest activity first): last message time, falling back
/// to match creation time.
int matchSortMillis(Map<String, dynamic> data) {
  final last = firestoreMillisFrom(data['lastMessageAt']);
  if (last != 0) return last;
  return firestoreMillisFrom(data['createdAt']);
}
