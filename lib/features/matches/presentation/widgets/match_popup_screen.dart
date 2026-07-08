import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/chat/data/chat_repository.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';
import 'package:christian_dating_app/core/navigation/app_navigator.dart';
import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/main_navigation.dart';
import 'package:christian_dating_app/core/models/profile_photo_urls.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/core/widgets/profile_photo_placeholder.dart';

/// Where the app should land after the match celebration is dismissed.
enum MatchPopupDismissDestination {
  discovery,
  likedYou,
}

/// Shows a Bumble-style full-screen match celebration.
Future<void> showMatchPopup(
  BuildContext context, {
  required String matchId,
  required String matchedUserId,
  MatchPopupDismissDestination dismissDestination =
      MatchPopupDismissDestination.discovery,
}) async {
  final currentUserId = ProviderScope.containerOf(context)
      .read(currentUserIdProvider);
  if (currentUserId == null) return;

  final profileRepo = ProviderScope.containerOf(context)
      .read(profileRepositoryProvider);
  final profiles = await Future.wait([
    profileRepo.fetchProfile(currentUserId),
    profileRepo.fetchProfile(matchedUserId),
  ]);

  if (!context.mounted) return;

  applyMatchSystemNavigationBar();
  try {
    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: kMatchPopupRouteName),
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            MatchPopupScreen(
          matchId: matchId,
          currentUser: profiles[0] ?? <String, dynamic>{},
          matchedUser: profiles[1] ?? <String, dynamic>{},
          dismissDestination: dismissDestination,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  } finally {
    restoreAppSystemNavigationBar();
  }
}

class MatchPopupScreen extends ConsumerStatefulWidget {
  const MatchPopupScreen({
    super.key,
    required this.matchId,
    required this.currentUser,
    required this.matchedUser,
    this.dismissDestination = MatchPopupDismissDestination.discovery,
  });

  final String matchId;
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> matchedUser;
  final MatchPopupDismissDestination dismissDestination;

  @override
  ConsumerState<MatchPopupScreen> createState() => _MatchPopupScreenState();
}

class _MatchPopupScreenState extends ConsumerState<MatchPopupScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final Animation<double> _contentScale;
  late final Animation<double> _contentOpacity;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _sending = false;
  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _contentScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _controller.forward();
    _messageController.addListener(_onMessageChanged);
    _messageFocusNode.addListener(_onMessageFocusChanged);
  }

  void _onMessageFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onMessageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final keyboardInset = view.viewInsets.bottom / view.devicePixelRatio;
    if (keyboardInset == _lastKeyboardInset) return;

    final wasKeyboardUp = _lastKeyboardInset > 0;
    final isKeyboardUp = keyboardInset > 0;
    _lastKeyboardInset = keyboardInset;

    if (wasKeyboardUp && !isKeyboardUp && _messageFocusNode.hasFocus) {
      _messageFocusNode.unfocus();
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onMessageChanged);
    _messageFocusNode.removeListener(_onMessageFocusChanged);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get _matchedName {
    final name = widget.matchedUser['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'them' : name;
  }

  void _navigateAfterDismiss() {
    Navigator.of(context, rootNavigator: true).pop();
    switch (widget.dismissDestination) {
      case MatchPopupDismissDestination.likedYou:
        mainNavigationKey.currentState?.selectLikedYouTab();
      case MatchPopupDismissDestination.discovery:
        mainNavigationKey.currentState?.selectDiscoveryTab();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() => _sending = true);

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            matchId: widget.matchId,
            senderId: uid,
            text: text,
            likedContent: 'Match message',
          );

      if (!mounted) return;

      _navigateAfterDismiss();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
      setState(() => _sending = false);
    }
  }

  void _keepSwiping() {
    _navigateAfterDismiss();
  }

  Widget _buildMessageComposer({required bool showSend}) {
    const fieldRadius = 26.0;

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(fieldRadius),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              enabled: !_sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: AppTypography.chatComposerInput().copyWith(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Say something nice',
                hintStyle: AppTypography.regular(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
              ),
            ),
          ),
          if (showSend)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 6),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _sending ? null : _sendMessage,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _sending
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kBrandAccent,
                            ),
                          )
                        : Center(
                            child: AppIcon(
                              AppIcons.send,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCelebrationContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          FadeTransition(
            opacity: _contentOpacity,
            child: ScaleTransition(
              scale: _contentScale,
              child: Column(
                children: [
                  _MatchPhotoPair(
                    currentUser: widget.currentUser,
                    matchedUser: widget.matchedUser,
                    animation: _contentScale,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'You got a Match!',
                    textAlign: TextAlign.center,
                    style: AppTypography.timesNewRomanTitle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$_matchedName likes you, too. Take the first step and write a message.',
                      textAlign: TextAlign.center,
                      style: AppTypography.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardUp = keyboardInset > 0;
    final navBarInset = MediaQuery.viewPaddingOf(context).bottom;
    final showSend =
        keyboardUp && _messageController.text.trim().isNotEmpty;
    const transitionDuration = Duration(milliseconds: 260);
    // viewPadding (not padding) — edge-to-edge keeps padding.bottom at 0 on Android.
    final composerBottom = keyboardUp
        ? keyboardInset + 16
        : navBarInset + 24;

    return PopScope(
      canPop: !keyboardUp,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && keyboardUp) {
          _messageFocusNode.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: kMatchOrange,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: keyboardUp,
                  child: _buildCelebrationContent(),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: keyboardUp ? 1 : 0,
                    duration: transitionDuration,
                    curve: Curves.easeOut,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          color: kMatchOrange.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: _keepSwiping,
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
              AnimatedPositioned(
                duration: transitionDuration,
                curve: Curves.easeOutCubic,
                left: 28,
                right: 28,
                bottom: composerBottom,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (keyboardUp) ...[
                      Text(
                        'You matched with $_matchedName',
                        textAlign: TextAlign.center,
                        style: AppTypography.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    FadeTransition(
                      opacity: _contentOpacity,
                      child: _buildMessageComposer(showSend: showSend),
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

class _MatchPhotoPair extends StatelessWidget {
  const _MatchPhotoPair({
    required this.currentUser,
    required this.matchedUser,
    required this.animation,
  });

  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> matchedUser;
  final Animation<double> animation;

  static const double _cardWidth = 124;
  static const double _cardHeight = 156;
  static const double _overlap = 36;
  static const double _cardTilt = 0.20; // ~10° — tops fan outward, bottoms meet
  static const double _cornerRadius = 18;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight + 8,
      width: _cardWidth * 2 - _overlap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_cardTilt * animation.value,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: _MatchPhotoCard(
                user: currentUser,
                width: _cardWidth,
                height: _cardHeight,
                borderRadius: _cornerRadius,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _cardTilt * animation.value,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: _MatchPhotoCard(
                user: matchedUser,
                width: _cardWidth,
                height: _cardHeight,
                borderRadius: _cornerRadius,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon(
                  AppIcons.heartSolid,
                  size: 26,
                  color: kMatchOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchPhotoCard extends StatelessWidget {
  const _MatchPhotoCard({
    required this.user,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final Map<String, dynamic> user;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = ProfilePhotoUrls.photoAt(user);
    final gender = user['gender']?.toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null || url.isEmpty
            ? GenderSilhouettePlaceholder(
                gender: gender,
                style: GenderSilhouetteStyle.heroCard,
              )
            : Image.network(
                url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    GenderSilhouettePlaceholder(
                  gender: gender,
                  style: GenderSilhouetteStyle.heroCard,
                ),
              ),
      ),
    );
  }
}

