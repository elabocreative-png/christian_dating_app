import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/discovery/presentation/discovery_screen.dart';
import 'package:christian_dating_app/features/matches/data/like_result.dart';
import 'package:christian_dating_app/features/matches/data/matches_repository.dart';
import 'package:christian_dating_app/core/services/push_notification_service.dart';
import 'package:christian_dating_app/core/widgets/app_dialog.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/match_popup_screen.dart';
import 'package:christian_dating_app/features/discovery/presentation/widgets/user_profile_discovery_card.dart';

/// Same full-profile preview as [ProfileScreen] (scrollable discovery card).
///
/// When [connectionMatchId] and [connectionUserId] are set (New Connections /
/// Chats preview), floating **Not for me** dismisses the match and returns them
/// to Discover; **Message** opens the chat thread.
void showUserProfileBottomSheet(
  BuildContext context, {
  required Map<String, dynamic> user,
  String title = 'Profile',
  String? profileUserId,
  String? incomingLikeDocumentId,
  String? likerUserId,
  String? sentProfileUserId,
  String? connectionMatchId,
  String? connectionUserId,
  VoidCallback? onConnectionMessage,
  VoidCallback? onConnectionDismissed,
  VoidCallback? onEdit,
  String? matchId,
  VoidCallback? onUnmatched,
  BlockSource? blockSource,
  VoidCallback? onUserBlocked,
  String? blockedUserId,
  VoidCallback? onUserUnblocked,
  bool? showBlockReportLinks,
  bool? showHeroTopActions,
}) {
  final showBlockedPreview =
      blockedUserId != null && blockedUserId.isNotEmpty;
  final blockReport =
      showBlockReportLinks ?? (onEdit == null && !showBlockedPreview);
  final heroTopActions = showHeroTopActions ?? (onEdit == null);
  final showPassLike = incomingLikeDocumentId != null &&
      incomingLikeDocumentId.isNotEmpty &&
      likerUserId != null &&
      likerUserId.isNotEmpty;
  final showConnectionPreview = connectionMatchId != null &&
      connectionMatchId.isNotEmpty &&
      connectionUserId != null &&
      connectionUserId.isNotEmpty &&
      onEdit == null &&
      !showPassLike;
  final showUnmatch = matchId != null &&
      matchId.isNotEmpty &&
      onEdit == null &&
      !showPassLike &&
      !showConnectionPreview;
  final showSentActions = sentProfileUserId != null &&
      sentProfileUserId.isNotEmpty &&
      onEdit == null &&
      !showPassLike &&
      !showUnmatch &&
      !showConnectionPreview;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;

      VoidCallback? onPass;
      VoidCallback? onLike;
      if (showPassLike) {
        final likeDocId = incomingLikeDocumentId;
        final likerId = likerUserId;
        onPass = () async {
          final container = ProviderScope.containerOf(sheetContext);
          try {
            await container.read(matchesRepositoryProvider).deleteLike(likeDocId);
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          } catch (e) {
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(content: Text('Could not pass: $e')),
              );
            }
          }
        };
        onLike = () async {
          final container = ProviderScope.containerOf(sheetContext);
          try {
            final rootContext = Navigator.of(sheetContext, rootNavigator: true)
                .context;
            final result = await _likeUserWithPopup(
              context: rootContext,
              container: container,
              targetUserId: likerId,
              type: 'profile',
              content: 'Liked you back',
              answer: '',
              message: '',
              matchDismissDestination: MatchPopupDismissDestination.likedYou,
            );
            if (result.liked) {
              try {
                await container
                    .read(matchesRepositoryProvider)
                    .deleteLike(likeDocId);
              } catch (e) {
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text('Could not update list: $e')),
                  );
                }
              }
            }
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          } catch (e) {
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(content: Text('Could not like: $e')),
              );
            }
          }
        };
      }

      VoidCallback? onConnectionNotForMe;
      VoidCallback? onConnectionOpenMessage;
      if (showConnectionPreview) {
        final previewMatchId = connectionMatchId;
        final previewUserId = connectionUserId;
        onConnectionNotForMe = () async {
          final container = ProviderScope.containerOf(sheetContext);
          final uid = container.read(currentUserIdProvider);
          final ok = uid != null &&
              await container.read(matchesRepositoryProvider).dismissConnection(
                    uid: uid,
                    matchId: previewMatchId,
                    otherUserId: previewUserId,
                  );
          if (!sheetContext.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              const SnackBar(content: Text('Could not update connection')),
            );
            return;
          }
          discoveryScreenKey.currentState?.refreshUsers();
          Navigator.of(sheetContext).pop();
          onConnectionDismissed?.call();
        };
        onConnectionOpenMessage = () {
          Navigator.of(sheetContext).pop();
          onConnectionMessage?.call();
        };
      }

      VoidCallback? onSentDislike;
      VoidCallback? onSentMessage;
      if (showSentActions) {
        final targetUserId = sentProfileUserId;
        onSentDislike = () async {
          final container = ProviderScope.containerOf(sheetContext);
          final uid = container.read(currentUserIdProvider);
          final ok = uid != null &&
              await container
                  .read(matchesRepositoryProvider)
                  .revokeOutgoingLikes(uid: uid, targetUserId: targetUserId);
          if (!sheetContext.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              const SnackBar(content: Text('Could not remove like')),
            );
            return;
          }
          discoveryScreenKey.currentState?.refreshUsers();
          Navigator.of(sheetContext).pop();
        };
        onSentMessage = () async {
          final message = await showAppTextPromptDialog(
            sheetContext,
            title: 'Send a message',
            hintText: 'Say something meaningful...',
          );
          if (message == null || !sheetContext.mounted) return;

          final container = ProviderScope.containerOf(sheetContext);
          final uid = container.read(currentUserIdProvider);
          if (uid == null) return;

          final matchId = await container
              .read(matchesRepositoryProvider)
              .sendDirectMessage(
                fromUserId: uid,
                targetUserId: targetUserId,
                message: message,
              );
          if (!sheetContext.mounted) return;
          if (matchId == null) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              const SnackBar(content: Text('Could not send message')),
            );
            return;
          }

          Navigator.of(sheetContext).pop();
          PushNotificationService.openChat(matchId);
        };
      }

      return SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Material(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const outerPadding = EdgeInsets.fromLTRB(8, 8, 8, 0);
                    final cardHeight =
                        constraints.maxHeight - outerPadding.vertical;

                    return Padding(
                      padding: outerPadding,
                      child: UserProfileDiscoveryCard(
                        user: Map<String, dynamic>.from(user),
                        profileUserId: profileUserId ?? blockedUserId,
                        mediaContext: sheetContext,
                        cardHeight: cardHeight,
                        showOuterShadow: false,
                        heroMargin: const EdgeInsets.all(0),
                        sectionHorizontalMargin: 0,
                        showBlockReportLinks: blockReport,
                        showUnblockLink: showBlockedPreview,
                        showHeroTopActions: heroTopActions,
                        onEdit: null,
                        onPass: showPassLike ? null : onPass,
                        onLike: showPassLike ? null : onLike,
                        onPromptFavorite: null,
                        onExtraPhotoFavorite: null,
                        blockSource: blockSource,
                        onUserBlocked: () {
                          Navigator.of(sheetContext).pop();
                          onUserBlocked?.call();
                        },
                        onUserUnblocked: () {
                          Navigator.of(sheetContext).pop();
                          onUserUnblocked?.call();
                        },
                      ),
                    );
                  },
                ),
              ),
              if (showPassLike)
                _LikedYouPreviewActionBar(
                  bottomInset: bottomInset,
                  onNotForMe: onPass,
                  onMatch: onLike,
                )
              else if (showConnectionPreview)
                _ConnectionPreviewActionBar(
                  bottomInset: bottomInset,
                  onNotForMe: onConnectionNotForMe,
                  onMessage: onConnectionOpenMessage,
                )
              else if (showSentActions)
                _SentPreviewActionBar(
                  bottomInset: bottomInset,
                  onDislike: onSentDislike,
                  onMessage: onSentMessage,
                )
              else if (onEdit != null)
                _ProfileEditActionBar(
                  bottomInset: bottomInset,
                  onEdit: () {
                    Navigator.of(sheetContext).pop();
                    onEdit();
                  },
                )
              else if (showUnmatch)
                _MatchUnmatchActionBar(
                  bottomInset: bottomInset,
                  onUnmatch: () {
                    _confirmAndUnmatch(
                      sheetContext,
                      matchId: matchId,
                      onUnmatched: onUnmatched,
                    );
                  },
                )
              else
                SizedBox(height: bottomInset),
            ],
          ),
        ),
      );
    },
  );
}

Future<LikeResult> _likeUserWithPopup({
  required BuildContext context,
  required ProviderContainer container,
  required String targetUserId,
  required String type,
  required String content,
  required String answer,
  required String message,
  MatchPopupDismissDestination matchDismissDestination =
      MatchPopupDismissDestination.discovery,
}) async {
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

Future<void> _confirmAndUnmatch(
  BuildContext context, {
  required String matchId,
  VoidCallback? onUnmatched,
}) async {
  final confirmed = await showAppConfirmDialog(
    context,
    title: 'Unmatch',
    message:
        'Are you sure you want to unmatch? You will no longer be able to '
        'message each other.',
    confirmLabel: 'Unmatch',
  );
  if (confirmed != true || !context.mounted) return;

  final container = ProviderScope.containerOf(context);
  try {
    await container.read(chatRepositoryProvider).unmatch(matchId);

    if (!context.mounted) return;
    Navigator.of(context).pop();
    onUnmatched?.call();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not unmatch: $e')),
    );
  }
}

class _LikedYouPreviewActionBar extends StatelessWidget {
  const _LikedYouPreviewActionBar({
    required this.bottomInset,
    required this.onNotForMe,
    required this.onMatch,
  });

  final double bottomInset;
  final VoidCallback? onNotForMe;
  final VoidCallback? onMatch;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onNotForMe,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black87, width: 1.5),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('Not for me', style: labelStyle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onMatch,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('Match', style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPreviewActionBar extends StatelessWidget {
  const _ConnectionPreviewActionBar({
    required this.bottomInset,
    required this.onNotForMe,
    required this.onMessage,
  });

  final double bottomInset;
  final VoidCallback? onNotForMe;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onNotForMe,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black87, width: 1.5),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('Not for me', style: labelStyle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onMessage,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('Message', style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentPreviewActionBar extends StatelessWidget {
  const _SentPreviewActionBar({
    required this.bottomInset,
    required this.onDislike,
    required this.onMessage,
  });

  final double bottomInset;
  final VoidCallback? onDislike;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onDislike,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black87, width: 1.5),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('Dislike', style: labelStyle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onMessage,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('Message', style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditActionBar extends StatelessWidget {
  const _ProfileEditActionBar({
    required this.bottomInset,
    required this.onEdit,
  });

  final double bottomInset;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    final buttonWidth =
        (MediaQuery.sizeOf(context).width - 32 - 12) / 2;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: buttonWidth,
            child: FilledButton(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('Edit', style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchUnmatchActionBar extends StatelessWidget {
  const _MatchUnmatchActionBar({
    required this.bottomInset,
    required this.onUnmatch,
  });

  final double bottomInset;
  final VoidCallback onUnmatch;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    final buttonWidth =
        (MediaQuery.sizeOf(context).width - 32 - 12) / 2;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: buttonWidth,
            child: FilledButton(
              onPressed: onUnmatch,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text('Unmatch', style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}
