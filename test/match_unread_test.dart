import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/matches/domain/match_unread.dart';

void main() {
  group('MatchUnread', () {
    test('isUnopenedNewConnection when no messages and not opened', () {
      expect(
        MatchUnread.isUnopenedNewConnection(const {}, 'user_a'),
        isTrue,
      );
    });

    test('isUnopenedNewConnection false after opened', () {
      expect(
        MatchUnread.isUnopenedNewConnection(
          {'openedBy': {'user_a': true}},
          'user_a',
        ),
        isFalse,
      );
    });

    test('isUnopenedNewConnection false when conversation exists', () {
      expect(
        MatchUnread.isUnopenedNewConnection(
          {'lastMessageAt': DateTime(2026, 6, 1)},
          'user_a',
        ),
        isFalse,
      );
    });

    test('hasUnreadMessages uses unreadCountBy', () {
      expect(
        MatchUnread.hasUnreadMessages(
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'unreadCountBy': {'user_a': 2},
          },
          'user_a',
        ),
        isTrue,
      );
      expect(
        MatchUnread.hasUnreadMessages(
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'unreadCountBy': {'user_a': 0},
          },
          'user_a',
        ),
        isFalse,
      );
    });

    test('hasUnreadMessages false when lastReadAt covers last message', () {
      final msgTime = DateTime(2026, 6, 1, 12);
      final readTime = DateTime(2026, 6, 1, 13);

      expect(
        MatchUnread.hasUnreadMessages(
          {
            'lastMessageAt': msgTime,
            'lastMessageSenderId': 'other',
            'lastReadAt': {'user_a': readTime},
          },
          'user_a',
        ),
        isFalse,
      );
    });

    test('hasUnreadMessages true when new message after lastReadAt', () {
      final msgTime = DateTime(2026, 6, 1, 14);
      final readTime = DateTime(2026, 6, 1, 13);

      expect(
        MatchUnread.hasUnreadMessages(
          {
            'lastMessageAt': msgTime,
            'lastMessageSenderId': 'other',
            'lastReadAt': {'user_a': readTime},
          },
          'user_a',
        ),
        isTrue,
      );
    });

    test('countForUser returns 0 for legacy thread after opened', () {
      expect(
        MatchUnread.countForUser(
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'lastMessageSenderId': 'other',
            'openedBy': {'user_a': true},
          },
          'user_a',
        ),
        0,
      );
    });

    test('isYourMoveThread false when unread dot would show', () {
      expect(
        MatchUnread.isYourMoveThread(
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'lastMessageSenderId': 'other',
          },
          'user_a',
        ),
        isFalse,
      );
    });

    test('isYourMoveThread true when opened and awaiting reply', () {
      expect(
        MatchUnread.isYourMoveThread(
          {
            'lastMessageAt': DateTime(2026, 6, 1, 12),
            'lastMessageSenderId': 'other',
            'lastReadAt': {
              'user_a': DateTime(2026, 6, 1, 13),
            },
          },
          'user_a',
        ),
        isTrue,
      );
    });

    test('isYourMoveThread false when user sent last message', () {
      expect(
        MatchUnread.isYourMoveThread(
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'lastMessageSenderId': 'user_a',
            'openedBy': {'user_a': true},
          },
          'user_a',
        ),
        isFalse,
      );
    });

    test('unreadMessageThreadsCountFromDocs excludes session reads', () {
      final total = MatchUnread.unreadMessageThreadsCountFromDocs(
        [
          (
            id: 'm1',
            data: {
              'lastMessageAt': DateTime(2026, 6, 1),
              'lastMessageSenderId': 'other',
            },
          ),
          (
            id: 'm2',
            data: {
              'lastMessageAt': DateTime(2026, 6, 1),
              'lastMessageSenderId': 'other',
            },
          ),
        ],
        'user_a',
        sessionReadMatchIds: {'m1'},
      );
      expect(total, 1);
    });

    test('unreadMessageThreadsCount only counts message threads', () {
      final total = MatchUnread.unreadMessageThreadsCount(
        [
          const {},
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'unreadCountBy': {'user_a': 2},
          },
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'unreadCountBy': {'user_a': 0},
            'lastMessageSenderId': 'user_a',
          },
        ],
        'user_a',
      );
      expect(total, 1);
    });

    test('unopenedNewConnectionsCount only counts unopened strip matches', () {
      final total = MatchUnread.unopenedNewConnectionsCount(
        [
          const {},
          {'openedBy': {'user_a': true}},
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'unreadCountBy': {'user_a': 1},
          },
        ],
        'user_a',
      );
      expect(total, 1);
    });

    test('totalUnopenedChatsForUser counts conversations not messages', () {
      final total = MatchUnread.totalUnopenedChatsForUser(
        [
          const {},
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'unreadCountBy': {'user_a': 3},
          },
          {
            'lastMessageAt': DateTime(2026, 6, 1),
            'unreadCountBy': {'user_a': 0},
            'lastMessageSenderId': 'user_a',
          },
        ],
        'user_a',
      );
      expect(total, 2);
    });
  });
}
