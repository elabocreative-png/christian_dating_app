import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_illustrations.dart';
import 'app_typography.dart';
import 'block_source.dart';
import 'discovery_preferences.dart';
import 'discovery_users_service.dart';
import 'package:christian_dating_app/features/matches/data/like_result.dart';
import 'package:christian_dating_app/features/matches/data/likes_service.dart';
import 'widgets/discovery_helper_hint_overlay.dart';
import 'widgets/hero_inline_snack_bar.dart';
import 'widgets/discovery_radar_loading.dart';
import 'widgets/discovery_preferences_screen.dart';
import 'widgets/discovery_swipe_stamp_overlay.dart';
import 'widgets/user_profile_discovery_card.dart';
import 'widgets/app_dialog.dart';

/// Refreshes discovery after distance filter changes from [MainNavigation].
final GlobalKey<DiscoveryScreenState> discoveryScreenKey =
    GlobalKey<DiscoveryScreenState>();

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  DiscoveryScreenState createState() => DiscoveryScreenState();
}

/// Saved swipe position per discovery mode (dating / social).
class _ModeDeckSnapshot {
  const _ModeDeckSnapshot({
    required this.mode,
    required this.userIds,
    required this.currentIndex,
    required this.userCount,
    required this.deckExhausted,
    required this.passedUserIds,
    required this.skippedReviewUserIds,
    required this.reviewingSkipped,
  });

  final String mode;
  final Set<String> userIds;
  final int currentIndex;
  final int userCount;
  final bool deckExhausted;
  final List<String> passedUserIds;
  final List<String> skippedReviewUserIds;
  final bool reviewingSkipped;
}

//Swipe animation code from https://github.com/CodemagicApps/bumble_flutter_clone/blob/main/lib/screens/discovery_screen.dart

class DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  static const double _swipeCommitThreshold = 120;
  static const double _swipeVelocityCommit = 700;
  static const Duration _swipeAwayDuration = Duration(milliseconds: 140);
  static const Duration _snapBackDuration = Duration(milliseconds: 220);
  static const double _backCardScaleMin = 0.92;
  static const double _backCardScaleMax = 1.0;
  static const double _backCardLiftMax = 14;
  static const EdgeInsets _cardStackPadding = EdgeInsets.only(
    left: 10,
    right: 10,
    top: 6,
    bottom: 6,
  );

  late Future<List<NearbyUser>> usersFuture;

  double dragX = 0;
  double dragY = 0;
  int currentIndex = 0;
  bool _swipeAnimating = false;
  AnimationController? _dragAnimationController;

  final List<String> _passedUserIds = [];

  /// Passed profile user ids left to show after "Review skipped profiles".
  List<String> _skippedReviewUserIds = [];
  bool _reviewingSkipped = false;
  int _usersCount = 0;

  String _activeDiscoveryMode = kDiscoveryModeDating;
  List<NearbyUser>? _lastFetchedUsers;
  /// Local deck after removing liked profiles before the next fetch completes.
  List<NearbyUser>? _deckOverride;
  /// Which mode produced [_lastFetchedUsers] (avoids saving dating deck as social).
  String? _lastFetchedUsersMode;
  final Map<String, _ModeDeckSnapshot> _deckByMode = {};

  DiscoveryHintStep? _activeHintStep;
  bool _hintsResolved = false;
  Map<String, dynamic> _viewerProfile = {};

  bool _showAlreadyLikedBanner = false;
  Timer? _alreadyLikedBannerTimer;

  double _hintDragX = 0;
  double _hintDragY = 0;
  bool _hintSwipeAnimating = false;
  AnimationController? _hintDragAnimationController;

  /// 0 → resting stack, 1 → front card at swipe commit threshold.
  double get _swipeProgress =>
      (dragX.abs() / _swipeCommitThreshold).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    usersFuture = _initialUsersLoad();
    _resolveDiscoveryHints();
  }

  Future<void> _resolveDiscoveryHints() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _hintsResolved = true);
      return;
    }

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;

    final data = doc.data() ?? <String, dynamic>{};
    final hintsComplete = data['discoveryHintsComplete'];
    setState(() {
      _viewerProfile = data;
      _activeHintStep =
          hintsComplete == false ? DiscoveryHintStep.message : null;
      _hintsResolved = true;
    });
  }

  Widget _buildDiscoveryLoading() {
    return DiscoveryRadarLoading(userData: _viewerProfile);
  }

  Future<void> _completeDiscoveryHints() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'discoveryHintsComplete': true},
        SetOptions(merge: true),
      );
    }
    if (mounted) setState(() => _activeHintStep = null);
  }

  void _advanceToSwipeHint() {
    if (_activeHintStep != DiscoveryHintStep.message) return;
    setState(() {
      _activeHintStep = DiscoveryHintStep.swipeChoice;
      _hintDragX = 0;
      _hintDragY = 0;
    });
  }

  Future<String> _readDiscoveryModeFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return kDiscoveryModeDating;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['discoveryMode']?.toString() == kDiscoveryModeSocial
        ? kDiscoveryModeSocial
        : kDiscoveryModeDating;
  }

  Future<List<NearbyUser>> _initialUsersLoad() async {
    _activeDiscoveryMode = await _readDiscoveryModeFromFirestore();
    return DiscoveryUsersService.fetchNearbyUsers();
  }

  void _persistDeckForMode(String mode) {
    final users = _lastFetchedUsers;
    if (users == null || _lastFetchedUsersMode != mode) return;
    _deckByMode[mode] = _ModeDeckSnapshot(
      mode: mode,
      userIds: users.map((u) => u.id).toSet(),
      currentIndex: currentIndex,
      userCount: users.length,
      deckExhausted: currentIndex >= users.length,
      passedUserIds: List<String>.from(_passedUserIds),
      skippedReviewUserIds: List<String>.from(_skippedReviewUserIds),
      reviewingSkipped: _reviewingSkipped,
    );
  }

  void _applyDeck({
    required List<NearbyUser> users,
    required int index,
    List<String>? passedUserIds,
    List<String>? skippedReviewUserIds,
    bool reviewingSkipped = false,
  }) {
    setState(() {
      _deckOverride = null;
      _lastFetchedUsers = users;
      _lastFetchedUsersMode = _activeDiscoveryMode;
      usersFuture = Future.value(users);
      currentIndex = index;
      dragX = 0;
      dragY = 0;
      _passedUserIds
        ..clear()
        ..addAll(passedUserIds ?? const []);
      _skippedReviewUserIds =
          List<String>.from(skippedReviewUserIds ?? const []);
      _reviewingSkipped = reviewingSkipped;
    });
  }

  void _restoreDeckForMode(String mode, _ModeDeckSnapshot? previous) {
    final users = _lastFetchedUsers ?? const <NearbyUser>[];

    final validPrevious = previous != null && previous.mode == mode
        ? previous
        : null;

    if (validPrevious == null) {
      _applyDeck(users: users, index: 0);
      return;
    }

    final freshIds = users.map((u) => u.id).toSet();
    final hasNewUsers = freshIds.difference(validPrevious.userIds).isNotEmpty;

    if (hasNewUsers) {
      _deckByMode.remove(mode);
      _applyDeck(users: users, index: 0);
      return;
    }

    if (validPrevious.deckExhausted) {
      _applyDeck(
        users: users,
        index: users.length,
        passedUserIds: validPrevious.passedUserIds,
        skippedReviewUserIds: validPrevious.skippedReviewUserIds,
      );
      return;
    }

    _applyDeck(
      users: users,
      index: validPrevious.currentIndex.clamp(0, users.length),
      passedUserIds: validPrevious.passedUserIds,
      skippedReviewUserIds: validPrevious.skippedReviewUserIds,
      reviewingSkipped: validPrevious.reviewingSkipped,
    );
  }

  /// Called after Firestore [discoveryMode] is updated (dating ↔ social toggle).
  Future<void> onDiscoveryModeChanged(String newMode) async {
    if (newMode == _activeDiscoveryMode) return;

    _persistDeckForMode(_activeDiscoveryMode);
    final previous = _deckByMode[newMode];
    _activeDiscoveryMode = newMode;

    if (!mounted) return;

    // Drop stale index from the other mode so we never show its empty state here.
    final pending = DiscoveryUsersService.fetchNearbyUsers();
    setState(() {
      currentIndex = 0;
      dragX = 0;
      dragY = 0;
      _passedUserIds.clear();
      _skippedReviewUserIds = [];
      _reviewingSkipped = false;
      usersFuture = pending;
    });

    final users = await pending;
    if (!mounted) return;

    _lastFetchedUsers = users;
    _lastFetchedUsersMode = newMode;
    _restoreDeckForMode(newMode, previous);
  }

  @override
  void dispose() {
    _alreadyLikedBannerTimer?.cancel();
    _dragAnimationController?.dispose();
    _hintDragAnimationController?.dispose();
    super.dispose();
  }

  double _effectiveHintDragX(double releaseVelocityX) =>
      _hintDragX + releaseVelocityX * 0.2;

  Future<void> _animateHintDragX({
    required double from,
    required double to,
    required Duration duration,
    required Curve curve,
  }) async {
    _hintDragAnimationController?.dispose();
    final controller = AnimationController(vsync: this, duration: duration);
    _hintDragAnimationController = controller;

    final animation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );

    void listener() {
      if (mounted) setState(() => _hintDragX = animation.value);
    }

    animation.addListener(listener);
    try {
      await controller.forward();
    } finally {
      animation.removeListener(listener);
      controller.dispose();
      if (_hintDragAnimationController == controller) {
        _hintDragAnimationController = null;
      }
    }
  }

  Future<void> _snapHintBack() async {
    if (_hintSwipeAnimating) return;
    final start = _hintDragX;
    if (start == 0) return;

    _hintSwipeAnimating = true;
    try {
      await _animateHintDragX(
        from: start,
        to: 0,
        duration: _snapBackDuration,
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      setState(() {
        _hintDragX = 0;
        _hintDragY = 0;
      });
    } finally {
      if (mounted) setState(() => _hintSwipeAnimating = false);
    }
  }

  Future<void> _dismissHintWithSwipe({required bool toRight}) async {
    if (_hintSwipeAnimating ||
        _activeHintStep != DiscoveryHintStep.swipeChoice) {
      return;
    }
    _hintSwipeAnimating = true;

    final width = MediaQuery.sizeOf(context).width;
    final target = toRight ? width * 1.2 : -width * 1.2;
    final start = _hintDragX;

    try {
      await _animateHintDragX(
        from: start,
        to: target,
        duration: _swipeAwayDuration,
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      await _completeDiscoveryHints();
      if (!mounted) return;
      setState(() {
        _hintDragX = 0;
        _hintDragY = 0;
      });
    } finally {
      if (mounted) setState(() => _hintSwipeAnimating = false);
    }
  }

  /// Position plus release velocity (Bumble-style commit feel).
  double _effectiveDragX(double releaseVelocityX) =>
      dragX + releaseVelocityX * 0.2;

  Future<void> _animateDragX({
    required double from,
    required double to,
    required Duration duration,
    required Curve curve,
  }) async {
    _dragAnimationController?.dispose();
    final controller = AnimationController(vsync: this, duration: duration);
    _dragAnimationController = controller;

    final animation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );

    void listener() {
      if (mounted) setState(() => dragX = animation.value);
    }

    animation.addListener(listener);
    try {
      await controller.forward();
    } finally {
      animation.removeListener(listener);
      controller.dispose();
      if (_dragAnimationController == controller) {
        _dragAnimationController = null;
      }
    }
  }

  void refreshUsers() {
    _deckByMode.remove(_activeDiscoveryMode);
    setState(() {
      if (!_reviewingSkipped) {
        currentIndex = 0;
      }
      dragX = 0;
      dragY = 0;
      _reviewingSkipped = false;
      _skippedReviewUserIds = [];
      _lastFetchedUsers = null;
      _lastFetchedUsersMode = null;
      _deckOverride = null;
      usersFuture = DiscoveryUsersService.fetchNearbyUsers();
    });
  }

  List<NearbyUser> _activeUsers() =>
      _deckOverride ?? _lastFetchedUsers ?? const <NearbyUser>[];

  int? _indexForUserId(List<NearbyUser> users, String userId) {
    final index = users.indexWhere((user) => user.id == userId);
    return index >= 0 ? index : null;
  }

  int? _indexForNextSkippedReviewUser(List<NearbyUser> users) {
    while (_skippedReviewUserIds.isNotEmpty) {
      final index = _indexForUserId(users, _skippedReviewUserIds.first);
      if (index != null) return index;
      _skippedReviewUserIds.removeAt(0);
    }
    return null;
  }

  bool get _canReviewSkippedProfiles =>
      !_reviewingSkipped && _passedUserIds.isNotEmpty;

  void undoLastPass() => _undoLastPass();

  void nextCard() {
    if (_reviewingSkipped) {
      _finishCurrentSkippedReview(_activeUsers());
      return;
    }
    setState(() {
      currentIndex++;
      dragX = 0;
      dragY = 0;
    });
  }

  void _advanceAfterLike(String userId) {
    if (_reviewingSkipped) {
      _finishCurrentSkippedReview(_activeUsers());
      return;
    }
    _passedUserIds.clear();
    _removeUserFromDeck(userId);
  }

  void _removeUserFromDeck(String userId) {
    final users = _lastFetchedUsers;
    if (users == null) {
      nextCard();
      return;
    }

    final newUsers = users.where((user) => user.id != userId).toList();
    final newIndex = currentIndex.clamp(0, newUsers.length);

    setState(() {
      _deckOverride = newUsers;
      _lastFetchedUsers = newUsers;
      _usersCount = newUsers.length;
      currentIndex = newIndex;
      dragX = 0;
      dragY = 0;
    });
  }

  Future<void> _snapCardBack() async {
    if (_swipeAnimating) return;
    final start = dragX;
    if (start == 0) return;

    _swipeAnimating = true;
    try {
      await _animateDragX(
        from: start,
        to: 0,
        duration: _snapBackDuration,
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      setState(() {
        dragX = 0;
        dragY = 0;
      });
    } finally {
      if (mounted) setState(() => _swipeAnimating = false);
    }
  }

  Future<void> _completeSwipe({
    required List<NearbyUser> users,
    required bool toRight,
  }) async {
    if (_swipeAnimating) return;
    _swipeAnimating = true;

    final width = MediaQuery.sizeOf(context).width;
    final target = toRight ? width * 1.2 : -width * 1.2;
    final start = dragX;

    try {
      await _animateDragX(
        from: start,
        to: target,
        duration: _swipeAwayDuration,
        curve: Curves.easeOutCubic,
      );

      if (!mounted) return;

      if (toRight) {
        if (!_reviewingSkipped) {
          _passedUserIds.clear();
        }
        final result = await likeUser(
          users[currentIndex].id,
          'profile',
          'Swipe Like',
          '',
          '',
        );
        if (!mounted) return;
        if (result.alreadyLiked || result.errorMessage != null) {
          await _animateDragX(
            from: target,
            to: 0,
            duration: _snapBackDuration,
            curve: Curves.easeOutCubic,
          );
          if (!mounted) return;
          setState(() {
            dragX = 0;
            dragY = 0;
          });
          return;
        }
        if (_reviewingSkipped) {
          _finishCurrentSkippedReview(users);
        } else {
          _advanceAfterLike(users[currentIndex].id);
        }
      } else {
        _passCurrent(users: users);
      }
    } finally {
      if (mounted) setState(() => _swipeAnimating = false);
    }
  }

  Future<void> _swipeFromButton({
    required List<NearbyUser> users,
    required bool toRight,
  }) async {
    if (_swipeAnimating) return;
    setState(() {
      dragX = toRight
          ? _swipeCommitThreshold * 0.9
          : -_swipeCommitThreshold * 0.9;
    });
    await Future<void>.delayed(const Duration(milliseconds: 32));
    if (!mounted) return;
    await _completeSwipe(users: users, toRight: toRight);
  }

  void _passCurrent({required List<NearbyUser> users}) {
    final passedUserId = users[currentIndex].id;
    if (_reviewingSkipped) {
      _passedUserIds.add(passedUserId);
      _finishCurrentSkippedReview(users);
      return;
    }
    setState(() {
      _passedUserIds.add(passedUserId);
      currentIndex++;
      dragX = 0;
      dragY = 0;
    });
  }

  /// Moves to the next skipped profile, or back to the empty state.
  void _finishCurrentSkippedReview(List<NearbyUser> users) {
    final usersLength = users.length;
    if (_skippedReviewUserIds.isNotEmpty &&
        currentIndex < usersLength &&
        _skippedReviewUserIds.first == users[currentIndex].id) {
      _skippedReviewUserIds.removeAt(0);
    }
    final nextIndex = _indexForNextSkippedReviewUser(users);
    if (nextIndex == null) {
      setState(() {
        _reviewingSkipped = false;
        currentIndex = usersLength;
        dragX = 0;
        dragY = 0;
      });
      return;
    }
    setState(() {
      currentIndex = nextIndex;
      dragX = 0;
      dragY = 0;
    });
  }

  void _undoLastPass() {
    if (_passedUserIds.isEmpty || _swipeAnimating) return;
    final users = _activeUsers();
    if (users.isEmpty) return;
    final userId = _passedUserIds.removeLast();
    final previous = _indexForUserId(users, userId);
    if (previous == null) return;
    setState(() {
      currentIndex = previous;
      dragX = 0;
      dragY = 0;
    });
  }

  Future<void> _openDiscoveryFilters() async {
    final changed = await DiscoveryPreferencesScreen.push(context);
    if (changed == true && mounted) refreshUsers();
  }

  void _reviewSkippedProfiles(List<NearbyUser> users) {
    if (_passedUserIds.isEmpty || _swipeAnimating) return;
    final firstIndex = _firstDeckIndexForUserIds(_passedUserIds, users);
    if (firstIndex == null) return;

    setState(() {
      _reviewingSkipped = true;
      _skippedReviewUserIds = List<String>.from(_passedUserIds);
      _passedUserIds.clear();
      currentIndex = firstIndex;
      dragX = 0;
      dragY = 0;
    });
  }

  int? _firstDeckIndexForUserIds(
    List<String> userIds,
    List<NearbyUser> users,
  ) {
    for (final userId in userIds) {
      final index = _indexForUserId(users, userId);
      if (index != null) return index;
    }
    return null;
  }

  Future<void> _handleReviewSkippedProfiles(List<NearbyUser> users) async {
    if (!_canReviewSkippedProfiles || _swipeAnimating) return;

    if (users.isEmpty) {
      final fetched = await DiscoveryUsersService.fetchNearbyUsers();
      if (!mounted) return;
      setState(() {
        _deckOverride = null;
        _lastFetchedUsers = fetched;
        _lastFetchedUsersMode = _activeDiscoveryMode;
        _usersCount = fetched.length;
        usersFuture = Future.value(fetched);
        currentIndex = 0;
      });
      _reviewSkippedProfiles(fetched);
      return;
    }

    _reviewSkippedProfiles(users);
  }

  /// Next card behind the front during skipped review (not currentIndex + 1).
  int? _backCardIndexDuringSkippedReview(List<NearbyUser> users) {
    if (!_reviewingSkipped || _skippedReviewUserIds.length < 2) {
      return null;
    }
    return _indexForUserId(users, _skippedReviewUserIds[1]);
  }

  Widget _buildDiscoveryEmptyIllustration() {
    return SizedBox(
      width: 154,
      height: 160,
      child: SvgPicture.asset(
        AppIllustrations.noMoreUsers,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        allowDrawingOutsideViewBox: true,
      ),
    );
  }

  Widget _buildNoNearbyUsersState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildDiscoveryEmptyIllustration(),
            const SizedBox(height: 20),
            Text(
              'Youve seen everyone for now',
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateTitle(),
            ),
            const SizedBox(height: 10),
            Text(
              'Try changing your filters to get more reach so more people can match your criteria - or check back later!',
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateBody(),
            ),
            const SizedBox(height: 28),
            _buildDiscoveryEmptyActions(users: const []),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryEmptyActions({required List<NearbyUser> users}) {
    final canReviewSkipped = _canReviewSkippedProfiles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240,
          child: ElevatedButton(
            onPressed: _openDiscoveryFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            child: const Text('Change filters'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 240,
          child: OutlinedButton(
            onPressed: canReviewSkipped
                ? () => _handleReviewSkippedProfiles(users)
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              disabledForegroundColor: Colors.grey.shade400,
              side: BorderSide(
                color: canReviewSkipped
                    ? const Color(0xFFE0E0E4)
                    : Colors.grey.shade300,
              ),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            child: const Text('Review skipped profiles'),
          ),
        ),
      ],
    );
  }

  Widget _buildNoMoreUsersState(List<NearbyUser> users) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildDiscoveryEmptyIllustration(),
            const SizedBox(height: 20),
            Text(
              "You've seen everyone for now",
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateTitle(),
            ),
            const SizedBox(height: 10),
            Text(
              'Try changing your filters to get more reach so more people '
              'match your criteria - or check back later!',
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateBody(),
            ),

            const SizedBox(height: 28),
            _buildDiscoveryEmptyActions(users: users),
          ],
        ),
      ),
    );
  }

  Future<void> showProfileMessageDialog(String targetUserId) async {
    final message = await showAppTextPromptDialog(
      context,
      title: 'Send a message',
      hintText: 'Say something meaningful...',
    );
    if (message == null) return;
    final result = await likeUser(
      targetUserId,
      'profile',
      'Profile message',
      '',
      message,
    );
    if (!mounted || result.alreadyLiked) return;
    if (_reviewingSkipped) {
      _finishCurrentSkippedReview(_activeUsers());
    } else {
      _advanceAfterLike(targetUserId);
    }
  }

  Future<void> showLikeDialog(
    String targetUserId,
    String content,
    String answer,
  ) async {
    final message = await showAppTextPromptDialog(
      context,
      title: 'Send a message',
      hintText: 'Say something meaningful...',
    );
    if (message == null) return;
    final result = await likeUser(
      targetUserId,
      'prompt',
      content,
      answer,
      message,
    );
    if (!mounted || result.alreadyLiked || !result.liked) return;
    _advanceAfterLike(targetUserId);
  }

  void _showAlreadyLikedHeroSnackBar() {
    _alreadyLikedBannerTimer?.cancel();
    setState(() => _showAlreadyLikedBanner = true);
    _alreadyLikedBannerTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showAlreadyLikedBanner = false);
    });
  }

  Future<LikeResult> likeUser(
    String targetUserId,
    String type,
    String content,
    String answer,
    String message,
  ) async {
    final result = await LikesService.likeUser(
      context,
      targetUserId,
      type,
      content,
      answer,
      message,
      discoveryMode: _activeDiscoveryMode,
    );
    if (result.alreadyLiked && mounted) {
      _showAlreadyLikedHeroSnackBar();
    }
    return result;
  }

  Widget _discoveryUserCard(
    Map<String, dynamic> user,
    String userId,
    BuildContext context, {
    bool heroActions = false,
    bool showAlreadyLikedBanner = false,
    required List<NearbyUser> users,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return UserProfileDiscoveryCard(
          key: ValueKey<String>(userId),
          user: user,
          profileUserId: userId,
          viewerProfile: _viewerProfile,
          mediaContext: context,
          cardHeight: constraints.maxHeight,
          isSocialMode: _activeDiscoveryMode == kDiscoveryModeSocial,
          heroOverlay: showAlreadyLikedBanner
              ? const HeroInlineSnackBar()
              : null,
          onPass: heroActions
              ? () => _swipeFromButton(users: users, toRight: false)
              : null,
          onRewind: heroActions ? _undoLastPass : null,
          onLike: heroActions
              ? () => _swipeFromButton(users: users, toRight: true)
              : null,
          onIntroduce:
              heroActions ? () => showProfileMessageDialog(userId) : null,
          onPromptFavorite: (prompt) {
            showLikeDialog(
              userId,
              prompt['question']?.toString() ?? '',
              prompt['answer']?.toString() ?? '',
            );
          },
          onExtraPhotoFavorite: () async {
            final result = await likeUser(
              userId,
              'photo',
              'Extra Photo',
              '',
              '',
            );
            if (!mounted || result.alreadyLiked || !result.liked) return;
            _advanceAfterLike(userId);
          },
          blockSource: BlockSource.discovery,
          onUserBlocked: () => _removeUserFromDeck(userId),
        );
      },
    );
  }

  Widget _frontCardStack({required List<NearbyUser> users}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _discoveryUserCard(
          users[currentIndex].profileData,
          users[currentIndex].id,
          context,
          heroActions: true,
          showAlreadyLikedBanner: _showAlreadyLikedBanner,
          users: users,
        ),
        if (_activeHintStep == null)
          DiscoverySwipeStampOverlay(
            dragX: dragX,
            commitThreshold: _swipeCommitThreshold,
            isSocialMode: _activeDiscoveryMode == kDiscoveryModeSocial,
          ),
      ],
    );
  }

  Widget _buildHintCardOverlay() {
    final hintRotation = _hintDragX * -0.002;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _activeHintStep == DiscoveryHintStep.message
          ? _advanceToSwipeHint
          : null,
      onPanUpdate: _activeHintStep == DiscoveryHintStep.swipeChoice
          ? (details) {
              if (_hintSwipeAnimating) return;
              setState(() {
                _hintDragX += details.delta.dx;
                _hintDragY = 0;
              });
            }
          : null,
      onPanEnd: _activeHintStep == DiscoveryHintStep.swipeChoice
          ? (details) {
              if (_hintSwipeAnimating) return;
              final vx = details.velocity.pixelsPerSecond.dx;
              final effective = _effectiveHintDragX(vx);

              final commitRight = effective > _swipeCommitThreshold ||
                  (_hintDragX > 0 && vx > _swipeVelocityCommit);
              final commitLeft = effective < -_swipeCommitThreshold ||
                  (_hintDragX < 0 && vx < -_swipeVelocityCommit);

              if (commitRight && !commitLeft) {
                _dismissHintWithSwipe(toRight: true);
              } else if (commitLeft && !commitRight) {
                _dismissHintWithSwipe(toRight: false);
              } else if (commitRight && commitLeft) {
                _dismissHintWithSwipe(toRight: _hintDragX >= 0);
              } else {
                _snapHintBack();
              }
            }
          : null,
      child: Transform.translate(
        offset: Offset(_hintDragX, _hintDragY),
        child: Transform.rotate(
          angle: hintRotation,
          alignment: Alignment.topCenter,
          child: SizedBox.expand(
            child: DiscoveryHelperHintOverlay(step: _activeHintStep!),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<NearbyUser>>(
          future: usersFuture,
          builder: (context, snapshot) {
            final authUser = FirebaseAuth.instance.currentUser;

            if (authUser == null) {
              return const SizedBox();
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return _buildDiscoveryLoading();
            }

            if (snapshot.hasError) {
              return Center(child: Text('Could not load users: ${snapshot.error}'));
            }

            final fetched = snapshot.data ?? [];
            final users = _deckOverride ?? fetched;
            if (_deckOverride == null) {
              _lastFetchedUsers = fetched;
              _lastFetchedUsersMode = _activeDiscoveryMode;
            } else {
              _lastFetchedUsers = users;
            }
            _usersCount = users.length;

            if (users.isEmpty) {
              return _buildNoNearbyUsersState();
            }

            if (currentIndex >= users.length) {
              return _buildNoMoreUsersState(users);
            }

            final swipeT = _swipeProgress;
            final backScale = _backCardScaleMin +
                (_backCardScaleMax - _backCardScaleMin) * swipeT;
            final backLift = _backCardLiftMax * (1 - swipeT);
            final frontRotation = dragX * -0.002; // Top pivot + inverted angle = Klim-style fan (bottom swings wider).
            final backIndex = _reviewingSkipped
                ? _backCardIndexDuringSkippedReview(users)
                : (currentIndex + 1 < users.length ? currentIndex + 1 : null);

            return Padding(
              padding: _cardStackPadding,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (backIndex != null)
                    Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: Offset(0, backLift),
                        child: Transform.scale(
                          scale: backScale,
                          alignment: Alignment.center,
                          child: _discoveryUserCard(
                            users[backIndex].profileData,
                            users[backIndex].id,
                            context,
                            heroActions: true,
                            users: users,
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onPanUpdate: (details) {
                      if (_swipeAnimating || _activeHintStep != null) return;
                      setState(() {
                        dragX += details.delta.dx;
                        dragY = 0;
                      });
                    },
                    onPanEnd: (details) {
                      if (_swipeAnimating || _activeHintStep != null) return;
                      final vx = details.velocity.pixelsPerSecond.dx;
                      final effective = _effectiveDragX(vx);

                      final commitRight = effective > _swipeCommitThreshold ||
                          (dragX > 0 && vx > _swipeVelocityCommit);
                      final commitLeft = effective < -_swipeCommitThreshold ||
                          (dragX < 0 && vx < -_swipeVelocityCommit);

                      if (commitRight && !commitLeft) {
                        _completeSwipe(users: users, toRight: true);
                      } else if (commitLeft && !commitRight) {
                        _completeSwipe(users: users, toRight: false);
                      } else if (commitRight && commitLeft) {
                        _completeSwipe(
                          users: users,
                          toRight: dragX >= 0,
                        );
                      } else {
                        _snapCardBack();
                      }
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: Offset(dragX, dragY),
                        child: Transform.rotate(
                          angle: frontRotation,
                          alignment: Alignment.topCenter, // Top pivot + inverted angle = Klim-style fan (bottom swings wider).
                          child: _frontCardStack(users: users),
                        ),
                      ),
                    ),
                  ),
                  if (_hintsResolved && _activeHintStep != null)
                    Positioned.fill(child: _buildHintCardOverlay()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
