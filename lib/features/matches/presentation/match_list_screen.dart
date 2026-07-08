import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/core/theme/app_illustrations.dart';
import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/features/settings/presentation/block_providers.dart';
import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/chat/presentation/chat_screen.dart';
import 'package:christian_dating_app/features/discovery/data/discovery_repository.dart';
import 'package:christian_dating_app/features/matches/domain/liked_you_filters.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';
import 'package:christian_dating_app/features/matches/presentation/matches_providers.dart';
import 'package:christian_dating_app/main_navigation.dart';
import 'package:christian_dating_app/features/matches/presentation/match_read_providers.dart';
import 'package:christian_dating_app/features/matches/domain/match_unread.dart';
import 'package:christian_dating_app/features/profile/presentation/profile_providers.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/avatar_unread_dot.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/chat_messages_sort_sheet.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/empty_state_illustration.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/likes_strip_chip.dart';
import 'package:christian_dating_app/core/widgets/profile_avatar.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/skeleton_loaders.dart';
import 'package:christian_dating_app/core/widgets/user_profile_bottom_sheet.dart';

String? otherUserIdFromMatch(
  Map<String, dynamic> matchData,
  String currentUserId,
) {
  final users = List<String>.from(matchData['users'] ?? []);
  for (final id in users) {
    if (id != currentUserId) return id;
  }
  return null;
}

String firstNameFromUserData(Map<String, dynamic>? userData) {
  final name = userData?['name']?.toString().trim() ?? '';
  if (name.isEmpty) return 'User';
  return name.split(RegExp(r'\s+')).first;
}

/// Chats tab: fixed header (title, search, your matches, messages) + scrollable list.
class MatchListScreen extends ConsumerStatefulWidget {
  const MatchListScreen({super.key});

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen> {
  bool _isSearching = false;
  ChatMessagesSort _messagesSort = ChatMessagesSort.mostRecent;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _openedMatchIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MatchEntry> _sortedMatches(List<MatchEntry> docs) {
    final list = List<MatchEntry>.from(docs);
    list.sort(
      (a, b) => matchSortMillis(b.data).compareTo(matchSortMillis(a.data)),
    );
    return list;
  }

  /// True once any message exists (match doc gets `lastMessageAt` from [ChatScreen]).
  bool _matchHasConversation(Map<String, dynamic> data) {
    return data['lastMessageAt'] != null;
  }

  /// “Your matches” strip: matches not yet in [Chats] (no overlap between sections).
  List<MatchEntry> _matchesAwaitingFirstMessage(
    List<MatchEntry> sortedMatches,
  ) {
    return sortedMatches
        .where((d) => !_matchHasConversation(d.data))
        .toList();
  }

  List<MatchEntry> _filteredChatMatches(
    List<MatchEntry> chatMatches,
    String currentUserId,
  ) {
    Iterable<MatchEntry> list = chatMatches;

    switch (_messagesSort) {
      case ChatMessagesSort.unread:
        list = chatMatches.where(
          (m) => MatchUnread.showsMessageUnreadDot(
            m.data,
            currentUserId,
            openedLocally: _openedMatchIds.contains(m.id),
          ),
        );
      case ChatMessagesSort.yourMove:
        list = chatMatches.where(
          (m) => MatchUnread.isYourMoveThread(
            m.data,
            currentUserId,
            openedLocally: _openedMatchIds.contains(m.id),
          ),
        );
      case ChatMessagesSort.mostRecent:
        break;
    }

    final result = List<MatchEntry>.from(list);
    result.sort(
      (a, b) => matchSortMillis(b.data).compareTo(matchSortMillis(a.data)),
    );
    return result;
  }

  Future<void> _pickMessagesSort() async {
    final picked = await showChatMessagesSortSheet(
      context,
      selected: _messagesSort,
    );
    if (picked == null || picked == _messagesSort) return;
    setState(() => _messagesSort = picked);
  }

  Iterable<String> _otherUserIdsFromMatches(
    List<MatchEntry> matches,
    String currentUserId,
  ) {
    return matches
        .map((m) => otherUserIdFromMatch(m.data, currentUserId))
        .whereType<String>();
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: 0,
      ),
    );
  }

  Widget _sectionTitleWithCount({
    required String text,
    required int count,
  }) {
    if (count <= 0) return _sectionTitle(text);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(text),
        const SizedBox(width: 6),
        Container(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  static const String _emptyMessagesWithMatchesTitle = 'No messages yet';
  static const String _emptyMessagesWithMatchesBody =
      'Open a match above and send a message';

  static const String _emptyNoConnectionsTitle =
      'No new connections or messages.';
  static const String _emptyNoConnectionsBody =
      "Chats appear here once a conversation from match starts.";

  Future<void> _openMatchChat(
    BuildContext context, {
    required String matchId,
    required String currentUserId,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(matchId: matchId),
      ),
    );
    if (!mounted) return;
    ref.read(matchReadStateProvider.notifier).markRead(matchId);
    await ref.read(chatRepositoryProvider).markChatOpened(
          matchId: matchId,
          userId: currentUserId,
        );
    if (!mounted) return;
    setState(() => _openedMatchIds.add(matchId));
  }

  Future<void> _openMatchPreview(
    BuildContext context, {
    required String matchId,
    required String currentUserId,
    required Map<String, dynamic> userData,
    required String otherUserId,
  }) async {
    final name = userData['name']?.toString().trim();
    final title = (name != null && name.isNotEmpty) ? name : 'Profile';
    final userWithDistance = await ref
        .read(discoveryRepositoryProvider)
        .enrichWithDistance(userData, viewerUid: currentUserId);
    if (!context.mounted) return;
    showUserProfileBottomSheet(
      context,
      user: userWithDistance,
      profileUserId: otherUserId,
      title: title,
      connectionMatchId: matchId,
      connectionUserId: otherUserId,
      blockSource: BlockSource.matches,
      onConnectionMessage: () => _openMatchChat(
        context,
        matchId: matchId,
        currentUserId: currentUserId,
      ),
    );
  }

  /// Empty state for the messages list area.
  Widget _buildMessagesEmptyState({
    String? title,
    required String message,
    String? illustrationAssetPath,
    Alignment alignment = Alignment.center,
    EdgeInsets? padding,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding ?? EmptyStateIllustrationLayout.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (illustrationAssetPath != null)
              EmptyStateIllustration(assetPath: illustrationAssetPath)
            else
              Icon(
                Icons.message_outlined,
                size: 100,
                color: Colors.grey.shade400,
              ),
            const SizedBox(height: EmptyStateIllustrationLayout.spacingBelow),
            if (title != null) ...[
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.emptyStateTitle(),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateBody(),
            ),
          ],
        ),
      ),
    );
  }

  /// Messages section title + sort control (fixed above the conversation list).
  Widget _buildChatsListSectionHeader() {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(child: _sectionTitle('Messages')),
            TextButton(
              onPressed: _pickMessagesSort,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort,
                    size: 20,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sort by',
                    style: AppTypography.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLikedYouTab() {
    mainNavigationKey.currentState?.selectLikedYouTab();
  }

  Widget _buildNewConnectionsStrip({
    required String currentUserId,
    required List<MatchEntry> stripMatches,
    required String stripWhenEmptyText,
    Map<String, Map<String, dynamic>>? userById,
    Set<String> blockedUserIds = const {},
  }) {
    final incomingLikes =
        ref.watch(incomingLikesProvider(currentUserId)).asData?.value ??
            const <LikeEntry>[];

    final likes = incomingLikes.where((entry) {
      if (isLikedYouMessageIntro(entry.data)) return false;
      final fromUserId = entry.data['fromUserId']?.toString() ?? '';
      return fromUserId.isNotEmpty && !blockedUserIds.contains(fromUserId);
    }).toList();
    final likesCount = likes.length;
    final firstLikerId = likes.isNotEmpty
        ? likes.first.data['fromUserId']?.toString()
        : null;
    final firstLikerFromBatch = firstLikerId == null
        ? null
        : userById?[firstLikerId];

    if (likesCount == 0 && stripMatches.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          stripWhenEmptyText,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    if (firstLikerId != null &&
        firstLikerId.isNotEmpty &&
        firstLikerFromBatch == null) {
      final likerAsync =
          ref.watch(profilesByIdsProvider(profilesByIdsCacheKey([firstLikerId])));
      return likerAsync.when(
        loading: () => _buildNewConnectionsListView(
          stripMatches: stripMatches,
          currentUserId: currentUserId,
          userById: userById,
          likesCount: likesCount,
          firstLikerData: null,
        ),
        error: (error, stackTrace) => _buildNewConnectionsListView(
          stripMatches: stripMatches,
          currentUserId: currentUserId,
          userById: userById,
          likesCount: likesCount,
          firstLikerData: null,
        ),
        data: (likerById) => _buildNewConnectionsListView(
          stripMatches: stripMatches,
          currentUserId: currentUserId,
          userById: userById,
          likesCount: likesCount,
          firstLikerData: likerById[firstLikerId],
        ),
      );
    }

    return _buildNewConnectionsListView(
      stripMatches: stripMatches,
      currentUserId: currentUserId,
      userById: userById,
      likesCount: likesCount,
      firstLikerData: firstLikerFromBatch,
    );
  }

  Widget _buildNewConnectionsListView({
    required List<MatchEntry> stripMatches,
    required String currentUserId,
    required int likesCount,
    Map<String, dynamic>? firstLikerData,
    Map<String, Map<String, dynamic>>? userById,
  }) {
    final itemCount = 1 + stripMatches.length;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 20),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return LikesStripChip(
            likesCount: likesCount,
            userData: firstLikerData,
            onTap: _openLikedYouTab,
          );
        }

        final match = stripMatches[index - 1];
        final otherId = otherUserIdFromMatch(
          match.data,
          currentUserId,
        );
        if (otherId == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _MatchAvatarChip(
            matchData: match.data,
            currentUserId: currentUserId,
            userData: userById?[otherId],
            nameFilter: _searchController.text,
            isSearching: _isSearching,
            openedLocally: _openedMatchIds.contains(match.id),
            onTap: () => _openMatchChat(
              context,
              matchId: match.id,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
    );
  }

  /// Toolbar + optional “New Connections” row (hidden until first match).
  Widget _buildChatsHeader({
    required BuildContext context,
    required String currentUserId,
    required List<MatchEntry> stripMatches,
    required String stripWhenEmptyText,
    Map<String, Map<String, dynamic>>? userById,
    bool showNewConnectionsSection = true,
    Set<String> blockedUserIds = const {},
  }) {
    final unopenedStripCount = stripMatches
        .where(
          (m) =>
              !_openedMatchIds.contains(m.id) &&
              MatchUnread.isUnopenedNewConnection(
                m.data,
                currentUserId,
              ),
        )
        .length;

    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: SizedBox(
                  height: 36,
                  child: Row(
                  children: [
                    if (_isSearching)
                      IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 36,
                        ),
                        icon: const Icon(Icons.close, color: Colors.black87),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                          });
                        },
                      ),
                    Expanded(
                      child: _isSearching
                          ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: AppTypography.searchFieldInput(),
                              decoration: const InputDecoration(
                                hintText: 'Search by name',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            )
                          : const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Chats',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                    ),
                    if (!_isSearching)
                      IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 36,
                        ),
                        icon: const AppIcon(
                          AppIcons.searchChat,
                          size: 28,
                          color: Colors.black87,
                        ),
                        onPressed: () => setState(() => _isSearching = true),
                      ),
                  ],
                ),
              ),
            ),
            ),
            if (showNewConnectionsSection)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 0, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitleWithCount(
                      text: 'New Connections',
                      count: unopenedStripCount,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 106,
                      child: _buildNewConnectionsStrip(
                        currentUserId: currentUserId,
                        stripMatches: stripMatches,
                        stripWhenEmptyText: stripWhenEmptyText,
                        userById: userById,
                        blockedUserIds: blockedUserIds,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnectionsEmptyScreen({
    required BuildContext context,
    required String currentUserId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildChatsHeader(
          context: context,
          currentUserId: currentUserId,
          stripMatches: const [],
          stripWhenEmptyText: '',
          showNewConnectionsSection: false,
        ),
        Expanded(
          child: _buildMessagesEmptyState(
            title: _emptyNoConnectionsTitle,
            message: _emptyNoConnectionsBody,
            illustrationAssetPath: AppIllustrations.noMessagesConnections,
            alignment: Alignment.center,
          ),
        ),
      ],
    );
  }

  List<MatchEntry> _matchesWithoutBlocked(
    List<MatchEntry> matches,
    String currentUserId,
    Set<String> blockedUserIds,
  ) {
    if (blockedUserIds.isEmpty) return matches;
    return matches
        .where((match) {
          final otherId = otherUserIdFromMatch(match.data, currentUserId);
          return otherId == null || !blockedUserIds.contains(otherId);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) {
      return const Scaffold(
        body: ChatListSkeleton(),
      );
    }

    final matchesAsync = ref.watch(matchesStreamProvider(currentUserId));
    final blockedUserIds =
        ref.watch(blockedUserIdsProvider(currentUserId)).value ?? const {};

    return Scaffold(
      backgroundColor: Colors.white,
      body: matchesAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChatsHeader(
              context: context,
              currentUserId: currentUserId,
              stripMatches: const [],
              stripWhenEmptyText: '',
              showNewConnectionsSection: false,
            ),
            _buildChatsListSectionHeader(),
            const Expanded(
              child: ChatListSkeleton(),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChatsHeader(
              context: context,
              currentUserId: currentUserId,
              stripMatches: const [],
              stripWhenEmptyText: '',
              showNewConnectionsSection: false,
            ),
            Expanded(
              child: Center(child: Text('Error: $error')),
            ),
          ],
        ),
        data: (raw) {
          final matches = _matchesWithoutBlocked(
            _sortedMatches(raw),
            currentUserId,
            blockedUserIds,
          );
          final chatMatches = matches
              .where((d) => _matchHasConversation(d.data))
              .toList();
          final stripMatches = _matchesAwaitingFirstMessage(matches);
          const stripHintNoMatches = 'No matches yet. Keep swiping!';
          const stripHintAllInChats =
              'Everyone you matched with is listed under Chats below.';
          final stripWhenEmptyText =
              matches.isEmpty ? stripHintNoMatches : stripHintAllInChats;

          if (matches.isEmpty) {
            return _buildNoConnectionsEmptyScreen(
              context: context,
              currentUserId: currentUserId,
            );
          }

          final idsKey = profilesByIdsCacheKey(
            _otherUserIdsFromMatches(matches, currentUserId),
          );
          final profilesAsync = ref.watch(profilesByIdsProvider(idsKey));

          return profilesAsync.when(
            loading: () {
              final filteredChatMatches = _filteredChatMatches(
                chatMatches,
                currentUserId,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildChatsHeader(
                    context: context,
                    currentUserId: currentUserId,
                    stripMatches: stripMatches,
                    stripWhenEmptyText: stripWhenEmptyText,
                    showNewConnectionsSection: true,
                    blockedUserIds: blockedUserIds,
                  ),
                  _buildChatsListSectionHeader(),
                  Expanded(
                    child: ChatListSkeleton(
                      itemCount: filteredChatMatches.length.clamp(6, 10),
                    ),
                  ),
                ],
              );
            },
            error: (error, stackTrace) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildChatsHeader(
                  context: context,
                  currentUserId: currentUserId,
                  stripMatches: stripMatches,
                  stripWhenEmptyText: stripWhenEmptyText,
                  showNewConnectionsSection: true,
                  blockedUserIds: blockedUserIds,
                ),
                Expanded(child: Center(child: Text('Error: $error'))),
              ],
            ),
            data: (userById) {
              final filteredChatMatches = _filteredChatMatches(
                chatMatches,
                currentUserId,
              );

              if (chatMatches.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildChatsHeader(
                      context: context,
                      currentUserId: currentUserId,
                      stripMatches: stripMatches,
                      stripWhenEmptyText: stripWhenEmptyText,
                      userById: userById,
                      showNewConnectionsSection: true,
                      blockedUserIds: blockedUserIds,
                    ),
                    _buildChatsListSectionHeader(),
                    Expanded(
                      child: _buildMessagesEmptyState(
                        title: _emptyMessagesWithMatchesTitle,
                        message: _emptyMessagesWithMatchesBody,
                        illustrationAssetPath:
                            AppIllustrations.noMessagesConnections,
                        alignment: stripMatches.isNotEmpty
                            ? Alignment.topCenter
                            : Alignment.center,
                        padding: stripMatches.isNotEmpty
                            ? const EdgeInsets.fromLTRB(50, 50, 50, 0)
                            : null,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildChatsHeader(
                    context: context,
                    currentUserId: currentUserId,
                    stripMatches: stripMatches,
                    stripWhenEmptyText: stripWhenEmptyText,
                    userById: userById,
                    showNewConnectionsSection: true,
                    blockedUserIds: blockedUserIds,
                  ),
                  _buildChatsListSectionHeader(),
                  Expanded(
                    child: filteredChatMatches.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 62,
                              ),
                              child: Text(
                                _messagesSort == ChatMessagesSort.mostRecent
                                    ? 'No messages yet'
                                    : 'No chats match this filter',
                                textAlign: TextAlign.center,
                                style: AppTypography.emptyStateBody(),
                              ),
                            ),
                          )
                        : CustomScrollView(
                            slivers: [
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final match = filteredChatMatches[index];
                                    final otherId = otherUserIdFromMatch(
                                      match.data,
                                      currentUserId,
                                    );
                                    return _ChatListTile(
                                      match: match,
                                      currentUserId: currentUserId,
                                      userData: otherId == null
                                          ? null
                                          : userById[otherId],
                                      searchQuery: _searchController.text,
                                      isSearching: _isSearching,
                                      openedLocally: _openedMatchIds
                                          .contains(match.id),
                                      onTap: () => _openMatchChat(
                                        context,
                                        matchId: match.id,
                                        currentUserId: currentUserId,
                                      ),
                                    );
                                  },
                                  childCount: filteredChatMatches.length,
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 24),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MatchAvatarChip extends StatelessWidget {
  const _MatchAvatarChip({
    required this.matchData,
    required this.currentUserId,
    required this.userData,
    required this.nameFilter,
    required this.isSearching,
    required this.openedLocally,
    required this.onTap,
  });

  final Map<String, dynamic> matchData;
  final String currentUserId;
  final Map<String, dynamic>? userData;
  final String nameFilter;
  final bool isSearching;
  final bool openedLocally;
  final VoidCallback onTap;

  static const double _avatarRadius = 36;

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const SizedBox(
        width: 72,
        height: 92,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final name = userData!['name']?.toString().trim() ?? 'User';
    if (isSearching && nameFilter.trim().isNotEmpty) {
      final q = nameFilter.trim().toLowerCase();
      if (!name.toLowerCase().contains(q)) {
        return const SizedBox.shrink();
      }
    }

    final firstName = firstNameFromUserData(userData);
    final showDot = !openedLocally &&
        MatchUnread.isUnopenedNewConnection(matchData, currentUserId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarUnreadDot(
                show: showDot,
                avatarRadius: _avatarRadius,
                child: ProfileAvatar(
                  userData: userData!,
                  radius: _avatarRadius,
                  backgroundColor: Colors.grey.shade300,
                  iconColor: Colors.grey.shade600,
                  iconSize: 38,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.match,
    required this.currentUserId,
    required this.userData,
    required this.searchQuery,
    required this.isSearching,
    required this.openedLocally,
    required this.onTap,
  });

  final MatchEntry match;
  final String currentUserId;
  final Map<String, dynamic>? userData;
  final String searchQuery;
  final bool isSearching;
  final bool openedLocally;
  final VoidCallback onTap;

  static const double _avatarRadius = 31;

  @override
  Widget build(BuildContext context) {
    final data = match.data;

    final lastMessage = data['lastMessage']?.toString().trim();
    final lastSender = data['lastMessageSenderId']?.toString();
    final hasLastMessage = lastMessage != null && lastMessage.isNotEmpty;
    final snippet = hasLastMessage
        ? lastMessage
        : 'Say hello — it\'s a match!';
    final isMyLastMessage =
        hasLastMessage && lastSender == currentUserId;
    final showUnreadDot = MatchUnread.showsMessageUnreadDot(
      data,
      currentUserId,
      openedLocally: openedLocally,
    );
    final yourMove = MatchUnread.isYourMoveThread(
      data,
      currentUserId,
      openedLocally: openedLocally,
    );
    final snippetColor =
        isMyLastMessage ? Colors.grey[700]! : Colors.black87;

    if (userData == null) {
      return const ChatListTileSkeleton();
    }

    final rowData = userData!;
    final name = rowData['name']?.toString().trim() ?? 'User';
    if (isSearching && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      if (!name.toLowerCase().contains(q)) {
        return const SizedBox.shrink();
      }
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AvatarUnreadDot(
                show: showUnreadDot,
                avatarRadius: _avatarRadius,
                child: ProfileAvatar(
                  userData: rowData,
                  radius: _avatarRadius,
                  backgroundColor: Colors.grey.shade200,
                  iconColor: Colors.grey.shade500,
                  iconSize: 31,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (yourMove) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Your move',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isMyLastMessage) ...[
                          const AppIcon(
                            AppIcons.reply,
                            width: 15,
                            height: 16,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            snippet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: snippetColor,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
