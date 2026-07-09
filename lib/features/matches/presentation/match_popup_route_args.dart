/// Where the app should land after the match celebration is dismissed.
enum MatchPopupDismissDestination {
  discovery,
  likedYou,
}

/// Route arguments for [MatchPopupScreen] via GoRouter `extra`.
final class MatchPopupRouteArgs {
  const MatchPopupRouteArgs({
    required this.matchId,
    required this.currentUser,
    required this.matchedUser,
    this.dismissDestination = MatchPopupDismissDestination.discovery,
  });

  final String matchId;
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> matchedUser;
  final MatchPopupDismissDestination dismissDestination;
}
