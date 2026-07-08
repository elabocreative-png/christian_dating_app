import 'package:cloud_firestore/cloud_firestore.dart';

/// A match document expressed in app types: its id and raw data map.
///
/// Structurally identical to the record used by the nav-badge providers, so the
/// two are interchangeable.
typedef MatchEntry = ({String id, Map<String, dynamic> data});

/// Sort key for a match (newest activity first): last message time, falling back
/// to match creation time. Keeps Timestamp handling out of the presentation layer.
int matchSortMillis(Map<String, dynamic> data) {
  final last = data['lastMessageAt'];
  final created = data['createdAt'];
  final t = last is Timestamp
      ? last
      : (created is Timestamp ? created : null);
  return t?.millisecondsSinceEpoch ?? 0;
}
