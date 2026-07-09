import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/matches/presentation/match_read_providers.dart';
import 'package:christian_dating_app/features/matches/presentation/matches_providers.dart';
import 'package:christian_dating_app/features/matches/presentation/nav_badge_providers.dart';

void main() {
  const uid = 'user-1';

  group('likedYouCountProvider', () {
    test('excludes message intros from badge count', () {
      final container = ProviderContainer.test(
        overrides: [
          incomingLikesProvider(uid).overrideWithValue(
            AsyncData([
              (
                id: 'like-1',
                data: {'content': 'Photo 1', 'message': ''},
              ),
              (
                id: 'like-2',
                data: {'content': '', 'message': 'Hello'},
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(likedYouCountProvider(uid)), 1);
    });

    test('returns zero when only message intros exist', () {
      final container = ProviderContainer.test(
        overrides: [
          incomingLikesProvider(uid).overrideWithValue(
            AsyncData([
              (
                id: 'like-1',
                data: {'content': 'Profile message', 'message': ''},
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(likedYouCountProvider(uid)), 0);
    });
  });

  group('unreadMessageThreadsProvider', () {
    test('counts threads with unread messages', () {
      final container = ProviderContainer.test(
        overrides: [
          matchesStreamProvider(uid).overrideWithValue(
            AsyncData([
              (
                id: 'match-1',
                data: {
                  'users': [uid, 'user-2'],
                  'lastMessageAt': DateTime(2026, 6, 1),
                  'unreadCountBy': {uid: 2},
                },
              ),
              (
                id: 'match-2',
                data: {
                  'users': [uid, 'user-3'],
                  'lastMessageAt': DateTime(2026, 6, 2),
                  'unreadCountBy': {uid: 0},
                },
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(unreadMessageThreadsProvider(uid)), 1);
    });

    test('excludes session-read threads from badge count', () {
      final container = ProviderContainer.test(
        overrides: [
          matchesStreamProvider(uid).overrideWithValue(
            AsyncData([
              (
                id: 'match-1',
                data: {
                  'users': [uid, 'user-2'],
                  'lastMessageAt': DateTime(2026, 6, 1),
                  'unreadCountBy': {uid: 1},
                },
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(matchReadStateProvider.notifier).markRead('match-1');
      expect(container.read(unreadMessageThreadsProvider(uid)), 0);
    });
  });
}
