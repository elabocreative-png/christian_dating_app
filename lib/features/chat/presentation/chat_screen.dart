import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/chat/domain/chat_context.dart';
import 'package:christian_dating_app/features/chat/domain/chat_message.dart';
import 'package:christian_dating_app/features/chat/presentation/chat_providers.dart';
import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/features/discovery/data/discovery_repository.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/core/widgets/profile_avatar.dart';
import 'package:christian_dating_app/core/widgets/user_profile_bottom_sheet.dart';
import 'package:christian_dating_app/core/widgets/app_dialog.dart';
import 'package:christian_dating_app/core/services/match_read_state.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;

  const ChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const Color _chatBubbleColor = kBrandAccent;
  static const Color _incomingBubbleColor = Color(0xFFF2F2F2);

  final messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isUnmatching = false;
  Future<ChatContext>? _chatContextFuture;

  @override
  void initState() {
    super.initState();
    messageController.addListener(() => setState(() {}));
    final uid = ref.read(currentUserIdProvider);
    if (uid != null) {
      _chatContextFuture = ref.read(chatRepositoryProvider).loadChatContext(
            matchId: widget.matchId,
            currentUserId: uid,
          );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _markMatchRead());
  }

  Future<void> _markMatchRead() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    ref.read(matchReadStateProvider.notifier).markRead(widget.matchId);
    await ref.read(chatRepositoryProvider).markChatOpened(
          matchId: widget.matchId,
          userId: uid,
        );
  }

  String _formatRelativeMatchTime(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
    if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    return _formatShortMatchDate(date);
  }

  String _formatShortMatchDate(DateTime date) {
    final year = date.year % 100;
    return '${date.month}/${date.day}/$year';
  }

  String _formatTimeOfDay(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _toggleMessageHeart(String messageId, bool currentlyLiked) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    try {
      await ref.read(chatRepositoryProvider).toggleMessageLike(
            matchId: widget.matchId,
            messageId: messageId,
            userId: uid,
            currentlyLiked: currentlyLiked,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save reaction: $e')),
        );
      }
    }
  }

  Widget _buildMessageTimestamp(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = weekdays[date.weekday - 1];
    final timeLabel = _formatTimeOfDay(date);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: AppTypography.manrope(
              fontSize: 13,
              color: Colors.black54,
            ),
            children: [
              TextSpan(
                text: dayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: ' $timeLabel',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChatHero(
    Map<String, dynamic> otherUser,
    DateTime? matchCreatedAt,
  ) {
    final name = otherUser['name']?.toString().trim();
    final displayName = (name == null || name.isEmpty) ? 'them' : name;
    final matchTime = matchCreatedAt == null
        ? ''
        : _formatRelativeMatchTime(matchCreatedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
              children: [
                const TextSpan(text: 'You matched with '),
                TextSpan(
                  text: displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (matchTime.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              matchTime,
              textAlign: TextAlign.center,
              style: AppTypography.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade500,
                height: 1.2,
              ),
            ),
          ],
          const SizedBox(height: 28),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openOtherUserProfile(
                context,
                Map<String, dynamic>.from(otherUser),
              ),
              customBorder: const CircleBorder(),
              child: ProfileAvatar(
                userData: otherUser,
                radius: 72,
                backgroundColor: Colors.grey[300],
                iconColor: Colors.white,
                iconSize: 72,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMatchHeader(
    Map<String, dynamic> otherUser,
    DateTime? matchCreatedAt,
  ) {
    final name = otherUser['name']?.toString().trim();
    final displayName = (name == null || name.isEmpty) ? 'them' : name;
    final datePart = matchCreatedAt == null
        ? ''
        : ' on ${_formatShortMatchDate(matchCreatedAt)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Center(
        child: Text(
          'You matched with $displayName$datePart',
          textAlign: TextAlign.center,
          style: AppTypography.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadOtherUser(String currentUserId) async {
    final chatContext = await ref.read(chatRepositoryProvider).loadChatContext(
          matchId: widget.matchId,
          currentUserId: currentUserId,
        );
    return chatContext.otherUser;
  }

  Future<void> _openOtherUserProfile(
    BuildContext context,
    Map<String, dynamic> otherUser,
  ) async {
    final name = otherUser['name']?.toString().trim() ?? '';
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final userWithDistance = await ref
        .read(discoveryRepositoryProvider)
        .enrichWithDistance(otherUser, viewerUid: uid);
    if (!context.mounted) return;
    showUserProfileBottomSheet(
      context,
      user: userWithDistance,
      profileUserId: otherUser['uid']?.toString(),
      title: name.isNotEmpty ? name : 'Profile',
      connectionMatchId: widget.matchId,
      connectionUserId: otherUser['uid']?.toString(),
      blockSource: BlockSource.messages,
      onConnectionDismissed: () {
        if (mounted) Navigator.of(context).pop();
      },
      onUserBlocked: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  Future<void> _confirmUnmatch(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Unmatch',
      message:
          'Are you sure you want to unmatch? You will no longer be able to '
          'message each other.',
      confirmLabel: 'Unmatch',
    );
    if (confirmed != true || !mounted) return;
    await _unmatch();
  }

  Future<void> _unmatch() async {
    if (_isUnmatching) return;
    setState(() => _isUnmatching = true);
    try {
      await ref.read(chatRepositoryProvider).unmatch(widget.matchId);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not unmatch: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUnmatching = false);
    }
  }

  void _report() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report coming soon')),
    );
  }

  Future<void> sendMessage() async {
    final uid = ref.read(currentUserIdProvider);
    if (messageController.text.trim().isEmpty) return;
    if (uid == null) return;

    final text = messageController.text.trim();

    await ref.read(chatRepositoryProvider).sendMessage(
          matchId: widget.matchId,
          senderId: uid,
          text: text,
        );

    messageController.clear();
  }

  @override
  void dispose() {
    _messageFocusNode.dispose();
    messageController.dispose();
    super.dispose();
  }

  Widget _buildChatAppBar(String currentUserId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadOtherUser(currentUserId),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;
        final name = otherUser?['name']?.toString().trim();
        final otherMap = otherUser ?? <String, dynamic>{};

        return AppBar(
          toolbarHeight: 56,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: const Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
          ),
          leading: AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: otherUser == null
                      ? null
                      : () {
                          _openOtherUserProfile(
                            context,
                            Map<String, dynamic>.from(otherUser),
                          );
                        },
                  customBorder: const CircleBorder(),
                  child: ProfileAvatar(
                    userData: otherMap,
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    iconColor: Colors.white,
                    iconSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (name == null || name.isEmpty) ? 'Chat' : name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              enabled: !_isUnmatching,
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                switch (value) {
                  case 'unmatch':
                    _confirmUnmatch(context);
                    break;
                  case 'report':
                    _report();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'unmatch',
                  child: Text('Unmatch'),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Text('Report'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required bool isMe,
    required String text,
    required String? likedContent,
    required Map<String, dynamic>? otherUser,
    required String messageId,
    required bool isLiked,
  }) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.68,
      ),
      decoration: BoxDecoration(
        color: isMe ? _chatBubbleColor : _incomingBubbleColor,
        borderRadius: isMe
            ? const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likedContent != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Liked: $likedContent',
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          if (text.isNotEmpty)
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
        ],
      ),
    );

    if (isMe) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (otherUser != null)
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 2),
            child: ProfileAvatar(
              userData: otherUser,
              radius: 14,
              backgroundColor: Colors.grey[300],
              iconColor: Colors.white,
              iconSize: 14,
            ),
          ),
        bubble,
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleMessageHeart(messageId, isLiked),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AppIcon(
                isLiked ? AppIcons.heartSolid : AppIcons.heartOutline,
                size: 22,
                color: isLiked ? Colors.red : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem({
    required ChatMessage msg,
    required String currentUserId,
    required Map<String, dynamic>? otherUser,
  }) {
    final isMe = msg.senderId == currentUserId;
    final text = msg.text;
    final likedContent = msg.likedContent;
    final messageDate = msg.createdAt;
    final isLiked = msg.isLikedBy(currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (messageDate != null) _buildMessageTimestamp(messageDate),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildMessageBubble(
            isMe: isMe,
            text: text,
            likedContent: likedContent,
            otherUser: otherUser,
            messageId: msg.id,
            isLiked: isLiked,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList({
    required List<ChatMessage> messages,
    required String currentUserId,
    required Map<String, dynamic>? otherUser,
    required DateTime? matchCreatedAt,
  }) {
    if (messages.isEmpty) {
      if (otherUser == null) return const SizedBox.shrink();
      return Center(
        child: _buildEmptyChatHero(otherUser, matchCreatedAt),
      );
    }

    final hasHeader = otherUser != null;
    final itemCount = messages.length + (hasHeader ? 1 : 0);

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasHeader && index == messages.length) {
          return _buildCompactMatchHeader(otherUser, matchCreatedAt);
        }

        final messageIndex = messages.length - 1 - index;
        return _buildMessageItem(
          msg: messages[messageIndex],
          currentUserId: currentUserId,
          otherUser: otherUser,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final hasText = messageController.text.trim().isNotEmpty;
    final sendColor = hasText ? kBrandAccent : const Color(0xFFD1D5DB);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE6E3E8)),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: messageController,
                  focusNode: _messageFocusNode,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (hasText) sendMessage();
                  },
                  style: AppTypography.chatComposerInput(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type a message',
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: sendColor,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                onTap: hasText ? sendMessage : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Center(
                    child: AppIcon(
                      AppIcons.send,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    final messagesAsync = ref.watch(chatMessagesProvider(widget.matchId));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildChatAppBar(currentUserId),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Could not load messages: $error'),
              ),
              data: (messages) {
                return FutureBuilder<ChatContext>(
                  future: _chatContextFuture,
                  builder: (context, contextSnapshot) {
                    if (contextSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final otherUser = contextSnapshot.data?.otherUser;
                    final matchCreatedAt =
                        contextSnapshot.data?.matchCreatedAt;

                    return _buildMessageList(
                      messages: messages,
                      currentUserId: currentUserId,
                      otherUser: otherUser,
                      matchCreatedAt: matchCreatedAt,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}