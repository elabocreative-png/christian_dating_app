import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/matches/domain/liked_you_filters.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';

void main() {
  group('isLikedYouMessageIntro', () {
    test('returns true for profile message content', () {
      expect(
        isLikedYouMessageIntro({'content': 'Profile message'}),
        isTrue,
      );
    });

    test('returns true when message field is non-empty', () {
      expect(
        isLikedYouMessageIntro({
          'content': 'Extra Photo',
          'message': 'Nice photo!',
        }),
        isTrue,
      );
    });

    test('returns false for silent likes', () {
      expect(
        isLikedYouMessageIntro({
          'content': 'Swipe Like',
          'message': '',
        }),
        isFalse,
      );
    });
  });

  group('likedYouIncomingIntros', () {
    test('returns only message intros', () {
      final docs = [
        _like('a', {'message': 'Hi'}),
        _like('b', {'message': ''}),
      ];
      expect(likedYouIncomingIntros(docs).map((d) => d.id), ['a']);
    });
  });

  group('likedYouOutgoingLikes', () {
    test('dedupes by target user keeping newest', () {
      final docs = [
        _like(
          'old',
          {
            'toUserId': 'u2',
            'createdAt': DateTime.fromMillisecondsSinceEpoch(1000),
          },
        ),
        _like(
          'new',
          {
            'toUserId': 'u2',
            'createdAt': DateTime.fromMillisecondsSinceEpoch(2000),
          },
        ),
        _like(
          'other',
          {
            'toUserId': 'u3',
            'createdAt': DateTime.fromMillisecondsSinceEpoch(500),
          },
        ),
      ];

      final result = likedYouOutgoingLikes(docs);
      expect(result.map((d) => d.id).toSet(), {'new', 'other'});
    });
  });

  group('likedYouOutgoingUnmatchedLikes', () {
    test('excludes outgoing likes that already have a match', () {
      final docs = [
        _like(
          'like1',
          {
            'toUserId': 'matched',
            'createdAt': DateTime.fromMillisecondsSinceEpoch(1000),
          },
        ),
        _like(
          'like2',
          {
            'toUserId': 'pending',
            'createdAt': DateTime.fromMillisecondsSinceEpoch(2000),
          },
        ),
      ];

      final result = likedYouOutgoingUnmatchedLikes(docs, {'matched'});
      expect(result.map((d) => d.id), ['like2']);
    });
  });

  group('matchedUserIdsFromMatches', () {
    test('returns other user ids from match docs', () {
      final matches = [
        _match('m1', {'users': ['me', 'u2']}),
        _match('m2', {'users': ['u3', 'me']}),
      ];

      expect(
        matchedUserIdsFromMatches(matches, 'me'),
        {'u2', 'u3'},
      );
    });
  });
}

LikeEntry _like(String id, Map<String, dynamic> data) => (id: id, data: data);

MatchEntry _match(String id, Map<String, dynamic> data) => (id: id, data: data);
