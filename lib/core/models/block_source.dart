/// Where the viewer was when they blocked someone (used to restore on unblock).
enum BlockSource {
  discovery,
  matches,
  likedYou,
  messages,
}

extension BlockSourceFirestore on BlockSource {
  String get firestoreValue => switch (this) {
        BlockSource.discovery => 'discovery',
        BlockSource.matches => 'matches',
        BlockSource.likedYou => 'liked_you',
        BlockSource.messages => 'messages',
      };
}

BlockSource? blockSourceFromFirestore(String? raw) {
  return switch (raw) {
    'discovery' => BlockSource.discovery,
    'matches' => BlockSource.matches,
    'liked_you' => BlockSource.likedYou,
    'messages' => BlockSource.messages,
    _ => null,
  };
}
