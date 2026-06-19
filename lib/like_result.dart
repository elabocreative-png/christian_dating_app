/// Outcome of [LikesService.likeUser].
class LikeResult {
  const LikeResult({
    required this.liked,
    this.isNewMatch = false,
    this.matchId,
    this.alreadyLiked = false,
    this.errorMessage,
  });

  /// A new outgoing like was written (not a duplicate).
  final bool liked;

  /// A new mutual match was created.
  final bool isNewMatch;

  /// User already sent this like (duplicate content).
  final bool alreadyLiked;

  /// Set when a Firestore or network error blocked the like flow.
  final String? errorMessage;

  final String? matchId;
}
