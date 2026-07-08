import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/matches/data/like_result.dart';
import 'package:christian_dating_app/features/matches/domain/liked_you_filters.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';

/// Data access for matches, likes, and like/match mutations.
///
/// Returns app types (records / plain maps) so the presentation layer never
/// touches cloud_firestore directly.
class MatchesRepository {
  MatchesRepository({
    FirebaseFirestore? firestore,
    ChatRepository? chatRepository,
    ProfileRepository? profileRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _chatRepository = chatRepository ?? ChatRepository(firestore: firestore),
        _profileRepository =
            profileRepository ?? ProfileRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final ChatRepository _chatRepository;
  final ProfileRepository _profileRepository;

  CollectionReference<Map<String, dynamic>> get _likesRef =>
      _firestore.collection('likes');

  DocumentReference<Map<String, dynamic>> _matchRef(String matchId) =>
      _firestore.collection('matches').doc(matchId);

  String matchIdFor(String uidA, String uidB) {
    final sortedIds = [uidA, uidB]..sort();
    return sortedIds.join('_');
  }

  /// Live matches the user is part of.
  Stream<List<MatchEntry>> watchMatches(String uid) {
    return _firestore
        .collection('matches')
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => (id: d.id, data: d.data())).toList());
  }

  /// Live incoming likes addressed to the user.
  Stream<List<LikeEntry>> watchIncomingLikes(String uid) {
    return _likesRef
        .where('toUserId', isEqualTo: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => (id: d.id, data: d.data())).toList());
  }

  /// Live outgoing likes sent by the user.
  Stream<List<LikeEntry>> watchOutgoingLikes(String uid) {
    return _likesRef
        .where('fromUserId', isEqualTo: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => (id: d.id, data: d.data())).toList());
  }

  /// Removes an incoming/outgoing like document (e.g. pass on Liked You preview).
  Future<void> deleteLike(String likeDocumentId) async {
    await _likesRef.doc(likeDocumentId).delete();
  }

  Future<String> _resolveDiscoveryMode(String uid, String? mode) async {
    if (mode != null) return mode;
    final data = await _profileRepository.fetchProfile(uid);
    return data?['discoveryMode']?.toString() == kDiscoveryModeSocial
        ? kDiscoveryModeSocial
        : kDiscoveryModeDating;
  }

  Future<void> _ensureMatchExists({
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

  Future<void> _deleteOutgoingLikes(String uid, String targetUserId) async {
    final docs = await _likesRef
        .where('fromUserId', isEqualTo: uid)
        .where('toUserId', isEqualTo: targetUserId)
        .get();

    if (docs.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Writes an outgoing like and creates a match thread when mutual or messaged.
  Future<LikeResult> sendLike({
    required String fromUserId,
    required String targetUserId,
    required String type,
    required String content,
    required String answer,
    required String message,
    String? discoveryMode,
  }) async {
    try {
      final existingLike = await _likesRef
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: targetUserId)
          .where('content', isEqualTo: content)
          .get();

      if (existingLike.docs.isNotEmpty) {
        return const LikeResult(liked: false, alreadyLiked: true);
      }

      final mode = await _resolveDiscoveryMode(fromUserId, discoveryMode);

      await _likesRef.add({
        'fromUserId': fromUserId,
        'toUserId': targetUserId,
        'type': type,
        'content': content,
        'answer': answer,
        'message': message,
        'discoveryMode': mode,
        'createdAt': Timestamp.now(),
      });

      final reverseLike = await _likesRef
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: fromUserId)
          .get();

      final sortedIds = [fromUserId, targetUserId]..sort();
      final matchId = sortedIds.join('_');
      final matchRef = _matchRef(matchId);
      final matchDoc = await matchRef.get();
      final matchExistedBefore = matchDoc.exists;
      final trimmedMessage = message.trim();
      final hasMessage = trimmedMessage.isNotEmpty;
      final isMutual = reverseLike.docs.isNotEmpty;

      if (!matchExistedBefore && (isMutual || hasMessage)) {
        await _ensureMatchExists(
          matchRef: matchRef,
          sortedIds: sortedIds,
          mutualMatch: isMutual,
          matchedByUserId: isMutual ? fromUserId : null,
        );
      }

      if (hasMessage) {
        await _chatRepository.sendMessage(
          matchId: matchId,
          senderId: fromUserId,
          text: trimmedMessage,
          likedContent: content,
        );
      }

      if (isMutual) {
        return LikeResult(
          liked: true,
          isNewMatch: !matchExistedBefore,
          matchId: matchId,
        );
      }

      return const LikeResult(liked: true);
    } on FirebaseException catch (e) {
      return LikeResult(liked: false, errorMessage: e.message);
    } catch (e) {
      return LikeResult(liked: false, errorMessage: e.toString());
    }
  }

  /// Deletes a match thread and outgoing likes so [otherUserId] can reappear.
  Future<bool> dismissConnection({
    required String uid,
    required String matchId,
    required String otherUserId,
  }) async {
    if (matchId.isEmpty || otherUserId.isEmpty) return false;

    try {
      await _chatRepository.unmatch(matchId);
      await _deleteOutgoingLikes(uid, otherUserId);
      return true;
    } on FirebaseException {
      return false;
    }
  }

  /// Removes all outgoing likes to [targetUserId].
  Future<bool> revokeOutgoingLikes({
    required String uid,
    required String targetUserId,
  }) async {
    if (targetUserId.isEmpty) return false;

    try {
      await _deleteOutgoingLikes(uid, targetUserId);
      return true;
    } on FirebaseException {
      return false;
    }
  }

  /// Creates a match thread when needed and sends the first message.
  Future<String?> sendDirectMessage({
    required String fromUserId,
    required String targetUserId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;

    final sortedIds = [fromUserId, targetUserId]..sort();
    final matchId = sortedIds.join('_');
    final matchRef = _matchRef(matchId);

    try {
      await _ensureMatchExists(
        matchRef: matchRef,
        sortedIds: sortedIds,
      );

      await _chatRepository.sendMessage(
        matchId: matchId,
        senderId: fromUserId,
        text: trimmed,
        likedContent: 'Sent message',
      );

      return matchId;
    } on FirebaseException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository(
    chatRepository: ref.watch(chatRepositoryProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  );
});
