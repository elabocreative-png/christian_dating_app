import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/liked_you_filters.dart';

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
        _doc('a', {'message': 'Hi'}),
        _doc('b', {'message': ''}),
      ];
      expect(likedYouIncomingIntros(docs).map((d) => d.id), ['a']);
    });
  });

  group('likedYouOutgoingLikes', () {
    test('dedupes by target user keeping newest', () {
      final docs = [
        _doc(
          'old',
          {
            'toUserId': 'u2',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
          },
        ),
        _doc(
          'new',
          {
            'toUserId': 'u2',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(2000),
          },
        ),
        _doc(
          'other',
          {
            'toUserId': 'u3',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(500),
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
        _doc(
          'like1',
          {
            'toUserId': 'matched',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000),
          },
        ),
        _doc(
          'like2',
          {
            'toUserId': 'pending',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(2000),
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
        _doc('m1', {'users': ['me', 'u2']}),
        _doc('m2', {'users': ['u3', 'me']}),
      ];

      expect(
        matchedUserIdsFromMatches(matches, 'me'),
        {'u2', 'u3'},
      );
    });
  });
}

QueryDocumentSnapshot<Map<String, dynamic>> _doc(
  String id,
  Map<String, dynamic> data,
) {
  return _FakeLikeDoc(id, data);
}

class _FakeLikeDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeLikeDoc(this.id, this._data);

  @override
  final String id;

  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
