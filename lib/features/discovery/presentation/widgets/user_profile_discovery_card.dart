import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/core/constants/church_attendance_options.dart';
import 'package:christian_dating_app/core/constants/denomination_options.dart';
import 'package:christian_dating_app/core/constants/tongues_options.dart';
import 'package:christian_dating_app/core/constants/faith_options.dart';
import 'package:christian_dating_app/core/utils/geo_utils.dart';
import 'package:christian_dating_app/core/constants/interest_options.dart';
import 'package:christian_dating_app/core/services/location_service.dart';
import 'package:christian_dating_app/core/constants/profile_about_options.dart';
import 'package:christian_dating_app/features/discovery/domain/profile_display_resolver.dart';
import 'package:christian_dating_app/core/constants/relationship_intent.dart';
import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/core/widgets/block_report_sheet.dart';
import 'package:christian_dating_app/core/widgets/profile_photo_placeholder.dart';
import 'package:christian_dating_app/widgets/profile_photo_viewer.dart';
import 'package:christian_dating_app/core/widgets/verified_name_age.dart';

/// Full-profile card matching [DiscoveryScreen] swipe card layout and styling:
/// hero, bio, church, basics, faith, photo, prompt, photo, prompt, interests, location.
class UserProfileDiscoveryCard extends StatefulWidget {
  const UserProfileDiscoveryCard({
    super.key,
    required this.user,
    required this.mediaContext,
    this.cardHeight,
    this.heroOverlay,
    this.onPass,
    this.onRewind,
    this.onLike,
    this.onIntroduce,
    this.onEdit,
    this.onPromptFavorite,
    this.onExtraPhotoFavorite,
    this.showOuterShadow = true,
    this.heroMargin,
    this.sectionHorizontalMargin = 0, //Info Card Horizontal Margin - User card
    this.showBlockReportLinks = true,
    this.showUnblockLink = false,
    this.showHeroTopActions = true,
    this.profileUserId,
    this.viewerProfile,
    this.isSocialMode = false,
    this.blockSource,
    this.onUserBlocked,
    this.onUserUnblocked,
  });

  final Map<String, dynamic> user;
  final BuildContext mediaContext;
  final double? cardHeight;
  final String? profileUserId;

  /// Logged-in user's profile; used to highlight matching pills on other profiles.
  final Map<String, dynamic>? viewerProfile;

  /// Optional overlay on hero (e.g. discovery like animation).
  final Widget? heroOverlay;

  /// Optional hero actions: Pass / Rewind / Like / Introduce.
  final VoidCallback? onPass;
  final VoidCallback? onRewind;
  final VoidCallback? onLike;
  final VoidCallback? onIntroduce;
  final VoidCallback? onEdit;

  final void Function(Map<String, dynamic> prompt)? onPromptFavorite;
  final VoidCallback? onExtraPhotoFavorite;

  /// Outer card drop shadow (off in [showUserProfileBottomSheet]).
  final bool showOuterShadow;

  /// Optional inset around the hero only (e.g. 2px in profile bottom sheets).
  final EdgeInsetsGeometry? heroMargin;

  /// Left/right inset for About, prompts, photos, and info sections (below hero).
  final double sectionHorizontalMargin;

  /// When false, hides Block / Report footer links (own profile preview).
  final bool showBlockReportLinks;

  /// When true, shows Unblock at the bottom instead of Block / Report.
  final bool showUnblockLink;

  /// When false, hides the hero distance row (own profile preview).
  final bool showHeroTopActions;

  /// When true, like actions use the wave icon instead of the heart.
  final bool isSocialMode;

  /// Where block should be attributed (discovery, messages, etc.).
  final BlockSource? blockSource;
  final VoidCallback? onUserBlocked;
  final VoidCallback? onUserUnblocked;

  @override
  State<UserProfileDiscoveryCard> createState() =>
      _UserProfileDiscoveryCardState();
}

class _UserProfileDiscoveryCardState extends State<UserProfileDiscoveryCard> {
  static const BorderRadius _heroPhotoBorderRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const Color _pillColor = Color(0xFFF2F2F2);
  static const Color _matchedPillColor = Color(0xFFF1E4DE);
  static const Color _heroChatColor = kBrandAccent;
  static const Color _cardFavoriteBorder = Color(0xFFE3E3E3);
  static const Color _promptQuoteColor = Color(0xFFB0ACA7);
  static const double _introButtonSize = 75;
  static const double _floatingActionButtonSize = 60;
  static const double _footerPassBookmarkSize = 60;
  static const double _heroLikeButtonSize = 40;
  /// Start hiding the floating intro this many px before the footer row enters view.
  static const double _floatingIntroHideLeadPx = 100;

  String get _likeActionIcon =>
      widget.isSocialMode ? AppIcons.handWaveSolid : AppIcons.heartSolid;

  final GlobalKey _cardViewportKey = GlobalKey();
  final GlobalKey _footerActionsKey = GlobalKey();
  final GlobalKey _heroNameKey = GlobalKey();
  bool _footerActionsInView = false;
  double? _scrollIndicatorTop;
  bool _scrollIndicatorLayoutScheduled = false;

  EdgeInsets get _sectionMargin => EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: widget.sectionHorizontalMargin,
        right: widget.sectionHorizontalMargin,
      );

  late final ScrollController _scrollController;
  bool _locationServicesEnabled = false;
  late ProfileDisplayValues _displayValues;
  Map<String, dynamic>? _viewerProfile;

  ProfileDisplayValues _resolveDisplayValues() {
    return ProfileDisplayResolver.resolve(
      user: widget.user,
      profileUserId: widget.profileUserId,
      locationServicesEnabled: _locationServicesEnabled,
    );
  }

  Future<void> _refreshLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final enabled =
        serviceEnabled && LocationService.isPermissionGranted(permission);
    if (!mounted || enabled == _locationServicesEnabled) return;
    setState(() {
      _locationServicesEnabled = enabled;
      _displayValues = _resolveDisplayValues();
    });
  }

  @override
  void initState() {
    super.initState();
    _viewerProfile = widget.viewerProfile;
    _displayValues = _resolveDisplayValues();
    _scrollController = ScrollController()..addListener(_onScroll);
    _refreshLocationAccess();
    _loadViewerProfileForMatching();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateFooterActionsVisibility();
        _scheduleScrollIndicatorLayout();
      }
    });
  }

  @override
  void didUpdateWidget(covariant UserProfileDiscoveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewerProfile != null &&
        widget.viewerProfile != oldWidget.viewerProfile) {
      _viewerProfile = widget.viewerProfile;
    }
    if (oldWidget.user != widget.user ||
        oldWidget.profileUserId != widget.profileUserId) {
      _displayValues = _resolveDisplayValues();
    }
    _scheduleScrollIndicatorLayout();
  }

  Future<void> _loadViewerProfileForMatching() async {
    if (_viewerProfile != null && _viewerProfile!.isNotEmpty) return;

    final viewerId = FirebaseAuth.instance.currentUser?.uid;
    if (viewerId == null) return;
    if (widget.profileUserId == viewerId) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(viewerId).get();
    if (!mounted) return;

    final data = doc.data();
    if (data == null || data.isEmpty) return;
    setState(() => _viewerProfile = data);
  }

  bool get _shouldHighlightMatches {
    final viewerId = FirebaseAuth.instance.currentUser?.uid;
    if (viewerId == null || _viewerProfile == null) return false;
    if (widget.profileUserId == viewerId) return false;
    return true;
  }

  Color _pillBackgroundColor({required bool matched}) {
    return matched ? _matchedPillColor : _pillColor;
  }

  bool _matchesChurchAttendance(String label) {
    if (!_shouldHighlightMatches) return false;
    final viewer = canonicalChurchAttendance(
      _viewerProfile!['churchAttendance']?.toString(),
    );
    return viewer != null && viewer == label;
  }

  bool _matchesDenomination(String label) {
    if (!_shouldHighlightMatches) return false;
    final viewer = displayDenominationLabel(_viewerProfile!['denomination']);
    return viewer == label;
  }

  bool _matchesTongues(String label) {
    if (!_shouldHighlightMatches) return false;
    if (!isPentecostalDenomination(_viewerProfile!['denomination']?.toString())) {
      return false;
    }
    final viewer = canonicalTongues(_viewerProfile!['speaksInTongues']?.toString());
    return viewer != null && viewer == label;
  }

  bool _matchesInterest(String label) {
    if (!_shouldHighlightMatches) return false;
    final raw = _viewerProfile!['interests'];
    if (raw is! List) return false;
    final canonical = canonicalInterestLabel(label);
    for (final item in raw) {
      if (canonicalInterestLabel(item?.toString() ?? '') == canonical) {
        return true;
      }
    }
    return false;
  }

  void _onScroll() {
    if (!mounted) return;
    _updateFooterActionsVisibility();
    if (_scrollController.hasClients && _scrollController.offset <= 1) {
      _scheduleScrollIndicatorLayout();
    }
  }

  void _scheduleScrollIndicatorLayout() {
    if (_scrollIndicatorLayoutScheduled) return;
    _scrollIndicatorLayoutScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollIndicatorLayoutScheduled = false;
      if (mounted) _updateScrollIndicatorLayout();
    });
  }

  void _updateScrollIndicatorLayout() {
    if (_scrollController.hasClients && _scrollController.offset > 1) {
      return;
    }

    final nameRo = _heroNameKey.currentContext?.findRenderObject();
    final cardRo = _cardViewportKey.currentContext?.findRenderObject();
    if (nameRo is! RenderBox || cardRo is! RenderBox) return;
    if (!nameRo.hasSize || !cardRo.hasSize) return;

    const slotHeight = 50.0;
    final nameBottom = nameRo.localToGlobal(
      Offset(0, nameRo.size.height),
      ancestor: cardRo,
    );
    final newTop = nameBottom.dy - slotHeight;
    if (_scrollIndicatorTop != newTop) {
      setState(() => _scrollIndicatorTop = newTop);
    }
  }

  void _updateFooterActionsVisibility() {
    final footerVisible = _computeFooterActionsInView();
    if (footerVisible != _footerActionsInView) {
      setState(() => _footerActionsInView = footerVisible);
    } else if (_scrollController.hasClients) {
      setState(() {});
    }
  }

  bool _computeFooterActionsInView() {
    final footerCtx = _footerActionsKey.currentContext;
    final viewportCtx = _cardViewportKey.currentContext;
    if (footerCtx == null || viewportCtx == null) return false;

    final footerBox = footerCtx.findRenderObject() as RenderBox?;
    final viewportBox = viewportCtx.findRenderObject() as RenderBox?;
    if (footerBox == null ||
        viewportBox == null ||
        !footerBox.hasSize ||
        !viewportBox.hasSize) {
      return false;
    }

    final footerTop = footerBox.localToGlobal(Offset.zero).dy;
    final viewportBottom =
        viewportBox.localToGlobal(Offset(0, viewportBox.size.height)).dy;

    return footerTop < viewportBottom + _floatingIntroHideLeadPx;
  }

  bool get _showDiscoveryFooterActions =>
      widget.onPass != null || widget.onIntroduce != null;

  bool get _showFloatingIntro =>
      widget.onIntroduce != null && !_footerActionsInView;

  bool get _showFloatingActionButton =>
      _showFloatingIntro || widget.onEdit != null;

  void _openBlockOrReport() {
    final targetId =
        widget.profileUserId ?? widget.user['uid']?.toString() ?? '';
    if (targetId.isEmpty || widget.blockSource == null) return;

    final name = widget.user['name']?.toString().trim();
    showBlockReportSheet(
      widget.mediaContext,
      blockedUserId: targetId,
      source: widget.blockSource!,
      displayName: name,
      onBlocked: widget.onUserBlocked,
    );
  }

  Future<void> _openUnblock() async {
    final targetId =
        widget.profileUserId ?? widget.user['uid']?.toString() ?? '';
    if (targetId.isEmpty) return;

    final name = widget.user['name']?.toString().trim();
    final ok = await confirmAndUnblockUser(
      widget.mediaContext,
      blockedUserId: targetId,
      displayName: name,
    );
    if (ok) widget.onUserUnblocked?.call();
  }

  List<String> _profilePhotoUrls() {
    final raw = widget.user['photos'];
    if (raw is! List) return const [];
    return raw
        .map((photo) => photo?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  void _openPhotoViewer(int index) {
    final urls = _profilePhotoUrls();
    if (index < 0 || index >= urls.length) return;
    showProfilePhotoViewer(context, url: urls[index]);
  }

  Widget _tappableProfilePhoto({
    required int photoIndex,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(photoIndex),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Short, thin scroll cue on the right (reference-style), not a full-height bar.
  Widget _buildScrollIndicator() {
    if (!_scrollController.hasClients) {
      return const SizedBox.shrink();
    }
    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    if (maxExtent <= 1) {
      return const SizedBox.shrink();
    }

    const rightInset = 5.0;
    const slotHeight = 50.0;
    const lineWidth = 3.0;

    final indicatorTop = _scrollIndicatorTop;
    if (indicatorTop == null) {
      _scheduleScrollIndicatorLayout();
      return const SizedBox.shrink();
    }

    final viewport = position.viewportDimension;
    final contentExtent = maxExtent + viewport;
    final thumbHeight = (slotHeight * (viewport / contentExtent))
        .clamp(8.0, slotHeight - 4);
    final t = maxExtent > 0
        ? (position.pixels / maxExtent).clamp(0.0, 1.0)
        : 0.0;
    final thumbTop = t * (slotHeight - thumbHeight);

    return Positioned(
      right: rightInset,
      top: indicatorTop,
      child: IgnorePointer(
        child: SizedBox(
          width: lineWidth + 20,
          height: slotHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: lineWidth,
                    height: slotHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.27),
                      borderRadius: BorderRadius.circular(lineWidth),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: thumbTop,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: lineWidth,
                    height: thumbHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 1),
                      borderRadius: BorderRadius.circular(lineWidth),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallbackHeight =
        MediaQuery.of(widget.mediaContext).size.height * 0.78;

    return LayoutBuilder(
      builder: (context, constraints) {
        final requestedHeight =
            (widget.cardHeight != null && widget.cardHeight! > 0)
                ? widget.cardHeight!
                : fallbackHeight;
        final height = constraints.hasBoundedHeight
            ? requestedHeight.clamp(0.0, constraints.maxHeight)
            : requestedHeight;

        return _buildCard(height: height);
      },
    );
  }

  Widget _buildCard({required double height}) {
    const bottomScrollPadding = 10.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.showOuterShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 0.4,
                  offset: const Offset(0, 0.2),
                ),
              ]
            : null,
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: const Color(0xFFF2F2F2),
          child: SizedBox(
            height: height,
            child: Stack(
              key: _cardViewportKey,
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  clipBehavior: Clip.hardEdge,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: widget.heroMargin ?? EdgeInsets.zero,
                        child: _buildHeroPhoto(height: height),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          SizedBox(height: 8),

                          _buildAboutMeSection(),
                          _buildChurchSection(),
                          _buildAboutMeDetailsSection(),
                          _buildFaithSection(),
                          _buildExtraPhotoAtIndex(1),
                          _buildPromptAtIndex(0),
                          _buildExtraPhotoAtIndex(2),
                          _buildPromptAtIndex(1),
                          _buildInterestsSection(),
                          _buildLocationSection(),
                          _buildProfileFooterActions(),

                          SizedBox(
                            height: _showFloatingActionButton
                                ? _floatingActionButtonSize + 16
                                : bottomScrollPadding,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildScrollIndicator(),
                if (widget.onIntroduce != null)
                  Positioned(
                    right: 16,
                    bottom: 18,
                    child: IgnorePointer(
                      ignoring: !_showFloatingIntro,
                      child: AnimatedOpacity(
                        opacity: _showFloatingIntro ? 1 : 0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                        child: _buildIntroCircleAction(
                          size: _floatingActionButtonSize,
                          onPressed: widget.onIntroduce,
                        ),
                      ),
                    ),
                  ),
                if (widget.onEdit != null)
                  Positioned(
                    right: 16,
                    bottom: 18,
                    child: _buildFooterCircleAction(
                      svgAsset: AppIcons.edit,
                      backgroundColor: _heroChatColor,
                      iconColor: Colors.white,
                      size: _floatingActionButtonSize,
                      iconSize: 28,
                      onPressed: widget.onEdit,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isNewHereUser() {
    final created = widget.user['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    }
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inDays <= 14;
  }

  TextStyle _heroNameStyle({required bool onPhoto}) {
    return TextStyle(
      color: onPhoto ? Colors.white : Colors.black87,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.05,
      fontFamily: AppTypography.manropeFamily,
    );
  }

  Widget _buildHeroDistancePill() {
    final km = _displayValues.heroDistanceKm;
    final distance = formatDistanceKmShort(km);
    final label =
        distance == 'Less than 1 km' ? 'Less than 1 km away' : '$distance away';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF202020).withValues(alpha: 0.0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            AppIcons.locationIcon,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewHereBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'New here',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeroBottomOverlay({
    required bool onPhoto,
    required String denominationLabel,
  }) {
    final nameStyle = _heroNameStyle(onPhoto: onPhoto);
    final detailColor = onPhoto ? Colors.white : Colors.black87;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isNewHereUser()) _buildNewHereBadge(),
              VerifiedNameAge(
                key: _heroNameKey,
                userData: widget.user,
                textStyle: nameStyle,
                iconSize: 26,
              ),
              _buildHeroDenominationLine(
                text: denominationLabel,
                color: detailColor,
              ),
              if (widget.showHeroTopActions) ...[
                const SizedBox(height: 2),
                _buildHeroDistancePill(),
              ],
            ],
          ),
          if (widget.onLike != null && widget.onIntroduce != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildHeroOutlineLikeButton(onPressed: widget.onLike),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutlineLikeButton({
    required VoidCallback? onPressed,
    double size = _heroLikeButtonSize,
  }) {
    const border = BorderSide(color: Colors.white, width: 1.2);

    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(side: border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(side: border),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: AppIcon(
              AppIcons.heartOutline,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFavoriteButton({
    required VoidCallback? onPressed,
    double size = _heroLikeButtonSize,
  }) => _buildOutlineLikeButton(onPressed: onPressed, size: size);

  Widget _buildPromptFavoriteButton({
    required VoidCallback? onPressed,
    double size = _heroLikeButtonSize,
  }) {
    const border = BorderSide(color: _cardFavoriteBorder, width: 1.2);

    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(side: border),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: AppIcon(
              AppIcons.heartOutline,
              size: size * 0.5,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroOutlineLikeButton({VoidCallback? onPressed}) =>
      _buildOutlineLikeButton(onPressed: onPressed);

  Widget _buildIntroCircleAction({
    required double size,
    VoidCallback? onPressed,
    double? iconSize,
  }) {
    const border = BorderSide(color: kBrandAccent, width: 1.2);

    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: border),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(side: border),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: AppIcon(
              AppIcons.introIconSolid,
              size: iconSize ?? size * 0.56,
              color: kBrandAccent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterCircleAction({
    required String svgAsset,
    required Color backgroundColor,
    required Color iconColor,
    required double size,
    VoidCallback? onPressed,
    double? iconSize,
    BorderSide? border,
  }) {
    final shape = border != null
        ? CircleBorder(side: border)
        : const CircleBorder();

    return Material(
      color: backgroundColor,
      shape: shape,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: shape,
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: AppIcon(
              svgAsset,
              size: iconSize ?? size * 0.56,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryFooterActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.onPass != null)
            _buildFooterCircleAction(
              svgAsset: AppIcons.closeSolid,
              backgroundColor: const Color(0xFF3C3C3C),
              iconColor: Colors.white,
              size: _footerPassBookmarkSize,
              onPressed: widget.onPass,
            ),
          if (widget.onIntroduce != null)
            _buildFooterCircleAction(
              svgAsset: AppIcons.introIconSolid,
              backgroundColor: kBrandAccent,
              iconColor: Colors.white,
              size: _introButtonSize,
              onPressed: widget.onIntroduce,
            ),
          if (widget.onLike != null && widget.onIntroduce == null)
            _buildFooterCircleAction(
              svgAsset: _likeActionIcon,
              backgroundColor: const Color(0xFF3C3C3C),
              iconColor: Colors.white,
              size: _footerPassBookmarkSize,
              onPressed: widget.onLike,
            )
          else if (widget.onLike != null)
            _buildFooterCircleAction(
              svgAsset: _likeActionIcon,
              backgroundColor: const Color(0xFF3C3C3C),
              iconColor: Colors.white,
              size: _footerPassBookmarkSize,
              onPressed: widget.onLike,
            ),
        ],
      ),
    );
  }

  Widget _buildHeroBottomGradient() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.62),
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeroOverlays({
    required bool onPhoto,
    required String denominationLabel,
  }) {
    return [
      if (onPhoto) _buildHeroBottomGradient(),
      _buildHeroBottomOverlay(
        onPhoto: onPhoto,
        denominationLabel: denominationLabel,
      ),
      if (widget.heroOverlay != null) widget.heroOverlay!,
    ];
  }

  bool _isFilled(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isNotEmpty;
  }

  Widget _buildFaithSection() {
    final label = _displayValues.faithLevel;
    final icon = _iconForFaithLevel(label);
    return _buildBasicsSectionCard(
      title: 'Faith level',
      items: [
        (icon: icon ?? Icons.volunteer_activism_outlined, label: label),
      ],
    );
  }

  IconData? _iconForLookingFor(String? value) {
    if (!isValidLookingFor(value)) return null;
    return Icons.search;
  }

  IconData? _iconForFaithLevel(String? value) {
    if (canonicalFaithLevel(value) == null) return null;
    return Icons.volunteer_activism_outlined;
  }

  Widget _buildChurchSection() {
    final churchName = widget.user['churchName']?.toString().trim() ?? '';
    final hasChurchName = churchName.isNotEmpty;
    final rawDenomination = widget.user['denomination']?.toString();
    final tonguesLabel = isPentecostalDenomination(rawDenomination)
        ? canonicalTongues(widget.user['speaksInTongues']?.toString())
        : null;

    return Container(
      width: double.infinity,
      margin: _sectionMargin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Church',
            style: AppTypography.infoCardTitle(),
          ),
          if (hasChurchName) ...[
            const SizedBox(height: 8),
            Text(
              churchName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: Colors.black87,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChurchPill(
                label: _displayValues.churchAttendance,
                emoji: '🪑',
                highlighted: _matchesChurchAttendance(_displayValues.churchAttendance),
              ),
              _buildChurchPill(
                label: _displayValues.denomination,
                emoji: '⛪',
                highlighted: _matchesDenomination(_displayValues.denomination),
              ),
              if (tonguesLabel != null)
                _buildChurchPill(
                  label: tonguesLabel,
                  emoji: '🗣️',
                  highlighted: _matchesTongues(tonguesLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChurchPill({
    required String label,
    required String emoji,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _pillBackgroundColor(matched: highlighted),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16, height: 1.1)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Gender, looking for, kids, body type, and lifestyle (below bio).
  Widget _buildAboutMeDetailsSection() {
    final lookingForLabel = _displayValues.lookingFor;
    final items = <({IconData icon, String label})>[
      (
        icon: genderDisplayIcon(_displayValues.gender),
        label: genderDisplayLabel(_displayValues.gender),
      ),
      (
        icon: _iconForLookingFor(lookingForLabel) ?? Icons.search,
        label: lookingForLabel,
      ),
    ];

    final smoking = widget.user['smoking']?.toString().trim();
    if (_isFilled(smoking)) {
      items.add((icon: Icons.smoke_free_outlined, label: smoking!));
    }
    final bodyTypeLabel = canonicalBodyType(widget.user['bodyType']?.toString());
    if (bodyTypeLabel != null) {
      items.add((icon: Icons.accessibility_new_outlined, label: bodyTypeLabel));
    }
    final exercise = widget.user['exercise']?.toString().trim();
    if (_isFilled(exercise)) {
      items.add((icon: Icons.fitness_center_outlined, label: exercise!));
    }
    final personalityLabel =
        canonicalPersonality(widget.user['personality']?.toString());
    if (personalityLabel != null) {
      items.add((icon: Icons.psychology_outlined, label: personalityLabel));
    }
    final kidsLabel = canonicalKids(widget.user['kids']?.toString());
    if (kidsLabel != null) {
      items.add((
        icon: Icons.child_care_outlined,
        label: kidsLabel == kKidsDontHaveKids ? 'No' : kidsLabel,
      ));
    }
    if (_isFilled(widget.user['alcohol'])) {
      items.add((
        icon: Icons.local_bar_outlined,
        label: widget.user['alcohol'].toString().trim(),
      ));
    }
    final tattoosLabel = canonicalTattoos(widget.user['tattoos']?.toString());
    if (tattoosLabel != null) {
      items.add((icon: Icons.brush_outlined, label: tattoosLabel));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return _buildBasicsSectionCard(
      title: 'My Basics',
      items: items,
    );
  }

  Widget _buildBasicsSectionCard({
    String? title,
    required List<({IconData icon, String label})> items,
  }) {
    final useTwoColumns = items.length >= 3;
    final splitAt = useTwoColumns ? (items.length + 1) ~/ 2 : items.length;
    final leftItems = items.sublist(0, splitAt);
    final rightItems =
        useTwoColumns ? items.sublist(splitAt) : const <({IconData icon, String label})>[];

    return Container(
      width: double.infinity,
      margin: _sectionMargin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: AppTypography.infoCardTitle(),
            ),
            const SizedBox(height: 10),
          ],
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildBasicsColumn(leftItems),
                ),
                if (rightItems.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFDAD5D5),
                    ),
                  ),
                  Expanded(
                    child: _buildBasicsColumn(rightItems),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicsColumn(List<({IconData icon, String label})> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildBasicsItemRow(
            icon: items[i].icon,
            label: items[i].label,
          ),
        ],
      ],
    );
  }

  Widget _buildBasicsItemRow({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.black87,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// Extra profile photo (index 0 is the hero).
  Widget _buildExtraPhotoAtIndex(int photoIndex) {
    if (photoIndex < 1) return const SizedBox.shrink();

    final photosRaw = widget.user['photos'];
    final photos = photosRaw is List ? photosRaw : const [];
    if (photoIndex >= photos.length) return const SizedBox.shrink();

    final url = photos[photoIndex]?.toString().trim() ?? '';
    if (url.isEmpty) return const SizedBox.shrink();

    return _buildPhotoCard(url, photoIndex: photoIndex);
  }

  /// Prompt card at [promptIndex] in `user.prompts`.
  Widget _buildPromptAtIndex(int promptIndex) {
    final promptsRaw = widget.user['prompts'];
    if (promptsRaw is! List || promptIndex >= promptsRaw.length) {
      return const SizedBox.shrink();
    }

    final raw = promptsRaw[promptIndex];
    if (raw is! Map) return const SizedBox.shrink();

    final prompt = Map<String, dynamic>.from(raw);
    final answer = prompt['answer']?.toString().trim() ?? '';
    if (answer.isEmpty) return const SizedBox.shrink();

    return _buildPromptCard(prompt);
  }

  Widget _buildHeroDenominationLine({
    required String text,
    required Color color,
  }) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⛪', style: TextStyle(fontSize: 15, height: 1.1, color: color)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final label = profileLocationPillLabel(
      widget.user,
      distanceKm: _displayValues.distanceKm,
    );
    if (label == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: _sectionMargin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My location',
            style: AppTypography.infoCardTitle(),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(
                AppIcons.locationIcon,
                size: 18,
                color: Colors.black87,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeSection() {
    final raw = widget.user['aboutMe']?.toString().trim() ?? '';
    if (raw.isEmpty) return const SizedBox.shrink();

    final bodyStyle = AppTypography.medium(
      fontSize: 15,
      height: 1.25,
      color: Colors.black87,
    );

    return Container(
      width: double.infinity,
      margin: _sectionMargin,
      padding: const EdgeInsets.only(
          left:16,
          top:16,
          right:16,
          bottom:16
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // BoxShadow(
          //   color: Colors.black.withValues(alpha: 0.1),
          //   blurRadius: 1.2,
          //   offset: const Offset(0, 0.1),
          // ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About me',
            style: AppTypography.infoCardTitle(),
          ),
          const SizedBox(height: 4),
          Text(raw, style: bodyStyle),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    final raw = widget.user['interests'];
    final labels = <String>[];
    if (raw is List) {
      for (final e in raw) {
        final t = e?.toString().trim() ?? '';
        if (t.isEmpty) continue;
        final c = canonicalInterestLabel(t);
        if (kInterestOptions.contains(c)) {
          labels.add(c);
        }
      }
    }

    if (labels.isEmpty) return const SizedBox.shrink();

    final chips = labels
        .map(
          (l) => _buildInfoChip(
            emoji: emojiForInterestLabel(l),
            label: l,
            highlighted: _matchesInterest(l),
          ),
        )
        .toList();

    return _buildInfoSectionCard(
      title: 'Interests',
      chips: chips,
    );
  }

  Widget _buildInfoSectionCard({
    required String title,
    required List<Widget> chips,
  }) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: _sectionMargin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // BoxShadow(
          //   color: Colors.black.withValues(alpha: 0.1),
          //   blurRadius: 1.2,
          //   offset: const Offset(0, 0.1),
          // ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.infoCardTitle(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String emoji,
    required String label,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _pillBackgroundColor(matched: highlighted),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16, height: 1.1)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPhoto({required double height}) {
    final photos = widget.user['photos'] ?? [];
    final denominationLabel = _displayValues.denomination;

    if (photos.isEmpty) {
      return ClipRRect(
        borderRadius: _heroPhotoBorderRadius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GenderSilhouettePlaceholder(
                gender: widget.user['gender']?.toString(),
                style: GenderSilhouetteStyle.heroCard,
              ),
              ..._buildHeroOverlays(
                onPhoto: true,
                denominationLabel: denominationLabel,
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: _heroPhotoBorderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _tappableProfilePhoto(
              photoIndex: 0,
              child: NetworkProfileImage(
                url: photos[0] as String,
                width: double.infinity,
                height: double.infinity,
                gender: widget.user['gender']?.toString(),
                useGenderSilhouette: true,
                silhouetteStyle: GenderSilhouetteStyle.heroCard,
                iconSize: 350,
              ),
            ),
            ..._buildHeroOverlays(
              onPhoto: true,
              denominationLabel: denominationLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFooterActions() {
    final hasDiscovery = _showDiscoveryFooterActions;
    final hasUnblock = widget.showUnblockLink;
    final hasModeration = widget.showBlockReportLinks && !hasUnblock;
    if (!hasDiscovery && !hasModeration && !hasUnblock) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 32,
        bottom: 24,
        left: widget.sectionHorizontalMargin,
        right: widget.sectionHorizontalMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasDiscovery) ...[
            KeyedSubtree(
              key: _footerActionsKey,
              child: _buildDiscoveryFooterActionRow(),
            ),
            if (hasModeration || hasUnblock) const SizedBox(height: 28),
          ],
          if (hasModeration)
            _buildProfileFooterLink(
              label: 'Block or Report',
              color: Colors.black87,
              onTap: _openBlockOrReport,
            )
          else if (hasUnblock)
            _buildProfileFooterLink(
              label: 'Unblock',
              color: Colors.black87,
              onTap: _openUnblock,
            ),
        ],
      ),
    );
  }

  Widget _buildProfileFooterLink({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptCard(Map<String, dynamic> prompt) {
    return Container(
      margin: _sectionMargin,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 56),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppIcon(
                      AppIcons.quoteMark,
                      width: 24,
                      height: 19,
                      color: _promptQuoteColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          prompt['question']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF565350),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 34, right: 34, bottom:4),
                  child: Text(
                    prompt['answer']?.toString() ?? '',
                    style: AppTypography.promptAnswer(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onPromptFavorite != null)
            Positioned(
              left: 14,
              bottom: 12,
              child: _buildPromptFavoriteButton(
                onPressed: () => widget.onPromptFavorite!(prompt),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCardBottomGradient() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 96,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.16),
                Colors.black.withValues(alpha: 0.42),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String photoUrl, {required int photoIndex}) {
    final showLike = widget.onExtraPhotoFavorite != null;

    return Container(
      margin: _sectionMargin,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _tappableProfilePhoto(
                    photoIndex: photoIndex,
                    child: NetworkProfileImage(
                      url: photoUrl,
                      width: double.infinity,
                      height: double.infinity,
                      gender: widget.user['gender']?.toString(),
                      useGenderSilhouette: true,
                    ),
                  ),
                  if (showLike) _buildPhotoCardBottomGradient(),
                ],
              ),
            ),
          ),
          if (showLike)
            Positioned(
              left: 14,
              bottom: 14,
              child: _buildCardFavoriteButton(
                onPressed: widget.onExtraPhotoFavorite,
              ),
            ),
        ],
      ),
    );
  }
}
