import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:christian_dating_app/features/matches/data/like_result.dart';
import 'package:christian_dating_app/features/matches/domain/match_unread.dart';
import 'package:christian_dating_app/discovery_preferences.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/match_popup_screen.dart';

/// Firestore like + match flow shared by discovery and other surfaces.
class LikesService {
  LikesService._();

  static Future<void> _ensureMatchExists({
    required DocumentReference<Map<String, dynamic>> matchRef,
    required List<String> sortedIds,
    bool mutualMatch = false,
    String? matchedByUserId,
  }) async {
    final matchDoc = await matchRef.get();
    if (matchDoc.exists) return;

    await matchRef.set({
      'users': sortedIds,
      'createdAt': Timestamp.now(),
      if (mutualMatch) 'mutualMatch': true,
      if (mutualMatch && matchedByUserId != null) 'matchedBy': matchedByUserId,
    });
  }

  static Future<void> _deliverLikeMessage({
    required DocumentReference<Map<String, dynamic>> matchRef,
    required String matchId,
    required String senderId,
    required List<String> userIds,
    required String message,
    required String content,
  }) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': message,
      'content': content,
      'createdAt': Timestamp.now(),
    });

    await matchRef.set(
      {
        'lastMessage': message,
        'lastMessageAt': Timestamp.now(),
        'lastMessageSenderId': senderId,
      },
      SetOptions(merge: true),
    );

    await MatchUnread.incrementForRecipient(
      matchRef: matchRef,
      senderId: senderId,
      userIds: userIds,
    );
  }

  /// Same behavior as the former [DiscoveryScreen.likeUser].
  ///
  /// Returns whether a new outgoing like was written; [LikeResult.isNewMatch]
  /// is set when a mutual match was created.
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LikeResult(liked: false);
    }

    final currentUserId = user.uid;

    final likesRef = FirebaseFirestore.instance.collection('likes');
    final matchesRef = FirebaseFirestore.instance.collection('matches');

    try {
    final existingLike = await likesRef
        .where('fromUserId', isEqualTo: currentUserId)
        .where('toUserId', isEqualTo: targetUserId)
        .where('content', isEqualTo: content)
        .get();

    if (!context.mounted) return const LikeResult(liked: false);

    if (existingLike.docs.isNotEmpty) {
      return const LikeResult(liked: false, alreadyLiked: true);
    }

    var mode = discoveryMode;
    if (mode == null) {
      final meDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      mode = meDoc.data()?['discoveryMode']?.toString() == kDiscoveryModeSocial
          ? kDiscoveryModeSocial
          : kDiscoveryModeDating;
    }

    await likesRef.add({
      'fromUserId': currentUserId,
      'toUserId': targetUserId,
      'type': type,
      'content': content,
      'answer': answer,
      'message': message,
      'discoveryMode': mode,
      'createdAt': Timestamp.now(),
    });

    final reverseLike = await likesRef
        .where('fromUserId', isEqualTo: targetUserId)
        .where('toUserId', isEqualTo: currentUserId)
        .get();

    final sortedIds = [currentUserId, targetUserId]..sort();
    final matchId = sortedIds.join('_');

    final matchRef = matchesRef.doc(matchId);
    final matchDoc = await matchRef.get();
    final matchExistedBefore = matchDoc.exists;
    final trimmedMessage = message.trim();
    final hasMessage = trimmedMessage.isNotEmpty;
    final isMutual = reverseLike.docs.isNotEmpty;

    if (!context.mounted) return const LikeResult(liked: true);

    if (!matchExistedBefore && (isMutual || hasMessage)) {
      await _ensureMatchExists(
        matchRef: matchRef,
        sortedIds: sortedIds,
        mutualMatch: isMutual,
        matchedByUserId: isMutual ? currentUserId : null,
      );
    }

    if (!context.mounted) return const LikeResult(liked: true);

    if (hasMessage) {
      await _deliverLikeMessage(
        matchRef: matchRef,
        matchId: matchId,
        senderId: currentUserId,
        userIds: sortedIds,
        message: trimmedMessage,
        content: content,
      );
    }

    if (!context.mounted) return const LikeResult(liked: true);

    if (isMutual) {
      final isNewMatch = !matchExistedBefore;

      if (!context.mounted) {
        return LikeResult(liked: true, isNewMatch: isNewMatch, matchId: matchId);
      }

      await showMatchPopup(
        context,
        matchId: matchId,
        matchedUserId: targetUserId,
        dismissDestination: matchDismissDestination,
      );

      return LikeResult(liked: true, isNewMatch: isNewMatch, matchId: matchId);
    }

    return const LikeResult(liked: true);
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not complete like: ${e.message}')),
        );
      }
      return LikeResult(liked: false, errorMessage: e.message);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not complete like: $e')),
        );
      }
      return LikeResult(liked: false, errorMessage: e.toString());
    }
  }

  /// Deletes a match thread and your outgoing likes so [otherUserId] can reappear
  /// on Discover.
  static Future<bool> dismissConnectionAndReturnToDiscovery({
    required String matchId,
    required String otherUserId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || matchId.isEmpty || otherUserId.isEmpty) return false;

    try {
      final matchRef =
          FirebaseFirestore.instance.collection('matches').doc(matchId);
      final messages = await matchRef.collection('messages').get();
      final outgoingLikes = await FirebaseFirestore.instance
          .collection('likes')
          .where('fromUserId', isEqualTo: user.uid)
          .where('toUserId', isEqualTo: otherUserId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(matchRef);
      for (final doc in outgoingLikes.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } on FirebaseException {
      return false;
    }
  }

  /// Removes all outgoing likes to [targetUserId] so they return to Discover.
  static Future<bool> revokeOutgoingLike(String targetUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || targetUserId.isEmpty) return false;

    try {
      final docs = await FirebaseFirestore.instance
          .collection('likes')
          .where('fromUserId', isEqualTo: user.uid)
          .where('toUserId', isEqualTo: targetUserId)
          .get();

      if (docs.docs.isEmpty) return true;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } on FirebaseException {
      return false;
    }
  }

  /// Sends a chat message to someone you already liked (Sent tab).
  ///
  /// Creates the match thread when needed and returns [matchId] on success.
  static Future<String?> sendDirectMessage(
    BuildContext context,
    String targetUserId,
    String message,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;

    final currentUserId = user.uid;
    final sortedIds = [currentUserId, targetUserId]..sort();
    final matchId = sortedIds.join('_');
    final matchRef =
        FirebaseFirestore.instance.collection('matches').doc(matchId);

    try {
      await _ensureMatchExists(
        matchRef: matchRef,
        sortedIds: sortedIds,
      );

      if (!context.mounted) return null;

      await _deliverLikeMessage(
        matchRef: matchRef,
        matchId: matchId,
        senderId: currentUserId,
        userIds: sortedIds,
        message: trimmed,
        content: 'Sent message',
      );

      return matchId;
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $e')),
        );
      }
      return null;
    }
  }
}
