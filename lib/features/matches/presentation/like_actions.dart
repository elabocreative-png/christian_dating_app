import 'package:flutter/material.dart';

import 'package:christian_dating_app/features/matches/data/like_result.dart';
import 'package:christian_dating_app/features/matches/data/matches_repository.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/match_popup_screen.dart';

/// Sends a like via [repository], then shows error snackbars and the match popup.
Future<LikeResult> sendLikeWithUiFeedback({
  required BuildContext context,
  required MatchesRepository repository,
  required String fromUserId,
  required String targetUserId,
  required String type,
  required String content,
  required String answer,
  required String message,
  String? discoveryMode,
  MatchPopupDismissDestination matchDismissDestination =
      MatchPopupDismissDestination.discovery,
  VoidCallback? onAlreadyLiked,
}) async {
  final result = await repository.sendLike(
    fromUserId: fromUserId,
    targetUserId: targetUserId,
    type: type,
    content: content,
    answer: answer,
    message: message,
    discoveryMode: discoveryMode,
  );

  if (!context.mounted) return result;

  if (result.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not complete like: ${result.errorMessage}'),
      ),
    );
    return result;
  }

  if (result.alreadyLiked) {
    onAlreadyLiked?.call();
  }

  if (result.isNewMatch && result.matchId != null) {
    await showMatchPopup(
      context,
      matchId: result.matchId!,
      matchedUserId: targetUserId,
      dismissDestination: matchDismissDestination,
    );
  }

  return result;
}
