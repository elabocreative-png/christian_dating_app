import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/matches/data/like_result.dart';
import 'package:christian_dating_app/features/matches/data/matches_repository.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/match_popup_screen.dart';

/// Presentation orchestration for likes: delegates data work to
/// [MatchesRepository] and handles match popup + error snackbars.
class LikesService {
  LikesService._();

  static Future<LikeResult> likeUser(
    BuildContext context,
    String targetUserId,
    String type,
    String content,
    String answer,
    String message, {
    String? discoveryMode,
    MatchPopupDismissDestination matchDismissDestination =
        MatchPopupDismissDestination.discovery,
  }) async {
    final container = ProviderScope.containerOf(context);
    final uid = container.read(currentUserIdProvider);
    if (uid == null) {
      return const LikeResult(liked: false);
    }

    final result = await container.read(matchesRepositoryProvider).sendLike(
          fromUserId: uid,
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
        SnackBar(content: Text('Could not complete like: ${result.errorMessage}')),
      );
      return result;
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

  static Future<bool> dismissConnectionAndReturnToDiscovery({
    required BuildContext context,
    required String matchId,
    required String otherUserId,
  }) async {
    final container = ProviderScope.containerOf(context);
    final uid = container.read(currentUserIdProvider);
    if (uid == null) return false;

    return container.read(matchesRepositoryProvider).dismissConnection(
          uid: uid,
          matchId: matchId,
          otherUserId: otherUserId,
        );
  }

  static Future<bool> revokeOutgoingLike(
    BuildContext context,
    String targetUserId,
  ) async {
    final container = ProviderScope.containerOf(context);
    final uid = container.read(currentUserIdProvider);
    if (uid == null) return false;

    return container.read(matchesRepositoryProvider).revokeOutgoingLikes(
          uid: uid,
          targetUserId: targetUserId,
        );
  }

  static Future<String?> sendDirectMessage(
    BuildContext context,
    String targetUserId,
    String message,
  ) async {
    final container = ProviderScope.containerOf(context);
    final uid = container.read(currentUserIdProvider);
    if (uid == null) return null;

    final matchId = await container
        .read(matchesRepositoryProvider)
        .sendDirectMessage(
          fromUserId: uid,
          targetUserId: targetUserId,
          message: message,
        );

    if (matchId == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message')),
      );
    }

    return matchId;
  }
}
