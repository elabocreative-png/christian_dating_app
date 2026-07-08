import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/core/theme/app_illustrations.dart';
import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/core/services/block_service.dart';
import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/discovery/data/discovery_repository.dart';
import 'package:christian_dating_app/features/matches/domain/liked_you_filters.dart';
import 'package:christian_dating_app/features/matches/domain/match_entry.dart';
import 'package:christian_dating_app/features/matches/presentation/matches_providers.dart';
import 'package:christian_dating_app/features/profile/data/profile_repository.dart';
import 'package:christian_dating_app/core/models/profile_photo_urls.dart';
import 'package:christian_dating_app/core/widgets/user_profile_bottom_sheet.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/empty_state_illustration.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/liked_you_tab_pills.dart';
import 'package:christian_dating_app/core/widgets/profile_photo_placeholder.dart';
import 'package:christian_dating_app/features/matches/presentation/widgets/skeleton_loaders.dart';
import 'package:christian_dating_app/core/constants/denomination_options.dart';

/// Likes as a 2-column grid: full-bleed portrait image, name on top, denomination pill on bottom.
///
/// Likes that include a message appear under **Intros**; outgoing likes under **Sent**.
class LikedYouScreen extends ConsumerStatefulWidget {
  const LikedYouScreen({super.key, this.isActive = true});

  /// False while another main tab is selected; used to reset sub-tabs on return.
  final bool isActive;

  @override
  ConsumerState<LikedYouScreen> createState() => _LikedYouScreenState();
}

class _LikedYouScreenState extends ConsumerState<LikedYouScreen> {
  static const int _columns = 2;
  static const double _gridHPadding = 12;
  static const double _crossGap = 8;
  static const double _mainGap = 8;
  static const double _childAspectRatio = 0.72;

  LikedYouListTab _selectedTab = LikedYouListTab.likes;

  @override
  void didUpdateWidget(LikedYouScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      setState(() => _selectedTab = LikedYouListTab.likes);
    }
  }

  Widget _buildEmptyState({
    required String title,
    required String body,
  }) {
    return Center(
      child: Padding(
        padding: EmptyStateIllustrationLayout.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const EmptyStateIllustration(
              assetPath: AppIllustrations.noLikesYet,
            ),
            const SizedBox(height: EmptyStateIllustrationLayout.spacingBelow),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateTitle(),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikesGrid({
    required List<LikeEntry> likes,
    required String Function(Map<String, dynamic> data) profileUserIdFor,
    required void Function(
      BuildContext context,
      Map<String, dynamic> userData,
      String profileUserId,
      LikeEntry like,
    ) onOpenProfile,
  }) {
    if (likes.isEmpty) {
      return switch (_selectedTab) {
        LikedYouListTab.likes => _buildEmptyState(
            title: 'No likes yet',
            body: 'Likes will appear here as soon as you get them.',
          ),
        LikedYouListTab.intros => _buildEmptyState(
            title: 'No intros yet',
            body: 'Profile messages and comments will show up here.',
          ),
        LikedYouListTab.sent => _buildEmptyState(
            title: 'Nothing sent yet',
            body: 'Profiles you like on Discover will appear here.',
          ),
      };
    }

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      key: ValueKey(
        '${_selectedTab.name}:${likes.map((d) => d.id).join(',')}',
      ),
      future: ref.read(profileRepositoryProvider).fetchProfilesByIds(
        likes.map((d) => profileUserIdFor(d.data)),
      ),
      builder: (context, usersSnapshot) {
        if (!usersSnapshot.hasData) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              _gridHPadding,
              8,
              _gridHPadding,
              24,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              childAspectRatio: _childAspectRatio,
              crossAxisSpacing: _crossGap,
              mainAxisSpacing: _mainGap,
            ),
            itemCount: likes.length,
            itemBuilder: (context, index) => const LikedYouCardSkeleton(),
          );
        }

        final userById = usersSnapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            _gridHPadding,
            8,
            _gridHPadding,
            24,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns,
            childAspectRatio: _childAspectRatio,
            crossAxisSpacing: _crossGap,
            mainAxisSpacing: _mainGap,
          ),
          itemCount: likes.length,
          itemBuilder: (context, index) {
            final like = likes[index];
            final profileUserId = profileUserIdFor(like.data);

            if (profileUserId.isEmpty) {
              return const SizedBox.shrink();
            }

            final userData = userById[profileUserId];
            if (userData == null) {
              return const LikedYouCardSkeleton();
            }

            return _LikedUserCard(
              userData: userData,
              discoveryMode: like.data['discoveryMode']?.toString(),
              onTap: () => onOpenProfile(context, userData, profileUserId, like),
            );
          },
        );
      },
    );
  }

  Future<void> _openIncomingProfile(
    BuildContext context,
    Map<String, dynamic> userData,
    String profileUserId,
    LikeEntry like,
  ) async {
    final name = userData['name']?.toString().trim();
    final title = (name != null && name.isNotEmpty) ? name : 'Profile';
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final userWithDistance = await ref
        .read(discoveryRepositoryProvider)
        .enrichWithDistance(userData, viewerUid: uid);
    if (!context.mounted) return;
    showUserProfileBottomSheet(
      context,
      user: userWithDistance,
      profileUserId: profileUserId,
      title: title,
      incomingLikeDocumentId: like.id,
      likerUserId: profileUserId,
      blockSource: BlockSource.likedYou,
    );
  }

  Future<void> _openSentProfile(
    BuildContext context,
    Map<String, dynamic> userData,
    String profileUserId,
    LikeEntry like,
  ) async {
    final name = userData['name']?.toString().trim();
    final title = (name != null && name.isNotEmpty) ? name : 'Profile';
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final userWithDistance = await ref
        .read(discoveryRepositoryProvider)
        .enrichWithDistance(userData, viewerUid: uid);
    if (!context.mounted) return;
    showUserProfileBottomSheet(
      context,
      user: userWithDistance,
      profileUserId: profileUserId,
      title: title,
      sentProfileUserId: profileUserId,
      blockSource: BlockSource.likedYou,
    );
  }

  Widget _buildTabContent({
    required List<LikeEntry> incomingLikes,
    required List<LikeEntry> incomingIntros,
    required List<LikeEntry> sentLikes,
  }) {
    return switch (_selectedTab) {
      LikedYouListTab.likes => _buildLikesGrid(
          likes: incomingLikes,
          profileUserIdFor: (data) => data['fromUserId']?.toString() ?? '',
          onOpenProfile: _openIncomingProfile,
        ),
      LikedYouListTab.intros => _buildLikesGrid(
          likes: incomingIntros,
          profileUserIdFor: (data) => data['fromUserId']?.toString() ?? '',
          onOpenProfile: _openIncomingProfile,
        ),
      LikedYouListTab.sent => _buildLikesGrid(
          likes: sentLikes,
          profileUserIdFor: (data) => data['toUserId']?.toString() ?? '',
          onOpenProfile: _openSentProfile,
        ),
    };
  }

  Widget _buildLoadedContent({
    required String uid,
    required Set<String> blockedUserIds,
    required List<LikeEntry> incomingDocs,
    required List<LikeEntry> outgoingDocs,
    required List<MatchEntry> matchDocs,
  }) {
    final incomingLikes = likedYouVisibleIncomingLikes(incomingDocs)
        .where(
          (entry) => !blockedUserIds.contains(
            entry.data['fromUserId']?.toString(),
          ),
        )
        .toList();
    final incomingIntros = likedYouIncomingIntros(incomingDocs)
        .where(
          (entry) => !blockedUserIds.contains(
            entry.data['fromUserId']?.toString(),
          ),
        )
        .toList();
    final matchedUserIds = matchedUserIdsFromMatches(matchDocs, uid);
    final sentLikes = likedYouOutgoingUnmatchedLikes(
      outgoingDocs,
      matchedUserIds,
    ).where(
      (entry) => !blockedUserIds.contains(
        entry.data['toUserId']?.toString(),
      ),
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: LikedYouTabPills(
            selected: _selectedTab,
            likesCount: incomingLikes.length,
            introsCount: incomingIntros.length,
            sentCount: sentLikes.length,
            onChanged: (tab) => setState(() => _selectedTab = tab),
          ),
        ),
        Expanded(
          child: _buildTabContent(
            incomingLikes: incomingLikes,
            incomingIntros: incomingIntros,
            sentLikes: sentLikes,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);

    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final incomingAsync = ref.watch(incomingLikesProvider(uid));
    final outgoingAsync = ref.watch(outgoingLikesProvider(uid));
    final matchesAsync = ref.watch(matchesStreamProvider(uid));

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<Set<String>>(
        stream: BlockService.streamBlockedUserIds(),
        builder: (context, blockedSnapshot) {
          final blockedUserIds = blockedSnapshot.data ?? const {};

          if (incomingAsync.isLoading ||
              outgoingAsync.isLoading ||
              matchesAsync.isLoading) {
            return const LikedYouScreenSkeleton();
          }

          if (incomingAsync.hasError) {
            return Center(child: Text('Error: ${incomingAsync.error}'));
          }
          if (outgoingAsync.hasError) {
            return Center(child: Text('Error: ${outgoingAsync.error}'));
          }
          if (matchesAsync.hasError) {
            return Center(child: Text('Error: ${matchesAsync.error}'));
          }

          return _buildLoadedContent(
            uid: uid,
            blockedUserIds: blockedUserIds,
            incomingDocs: incomingAsync.value ?? const [],
            outgoingDocs: outgoingAsync.value ?? const [],
            matchDocs: matchesAsync.value ?? const [],
          );
        },
      ),
    );
  }
}

class _LikedUserCard extends StatelessWidget {
  const _LikedUserCard({
    required this.userData,
    required this.onTap,
    this.discoveryMode,
  });

  final Map<String, dynamic> userData;
  final VoidCallback onTap;
  final String? discoveryMode;

  @override
  Widget build(BuildContext context) {
    final photoUrl = ProfilePhotoUrls.photoAt(userData, index: 0);
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    final denomination =
        displayDenominationLabel(userData['denomination']);

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cardWidth = (MediaQuery.sizeOf(context).width - 40) / 2;

    final imageChild = hasPhoto
        ? NetworkProfileImage(
            url: photoUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gender: userData['gender']?.toString(),
            useGenderSilhouette: true,
            silhouetteStyle: GenderSilhouetteStyle.heroCard,
            iconSize: 48,
            cacheWidth: (cardWidth * dpr).round().clamp(240, 1080),
            filterQuality: FilterQuality.medium,
          )
        : GenderSilhouettePlaceholder(
            gender: userData['gender']?.toString(),
            style: GenderSilhouetteStyle.heroCard,
          );

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: imageChild),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 120,
              child: IgnorePointer(
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
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LikedUserNameAge(
                    userData: userData,
                    discoveryMode: discoveryMode,
                  ),
                  _LikedCardDenominationLine(text: denomination),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikedUserNameAge extends StatelessWidget {
  const _LikedUserNameAge({
    required this.userData,
    this.discoveryMode,
  });

  final Map<String, dynamic> userData;
  final String? discoveryMode;

  static const TextStyle _textStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    final name = (userData['name'] ?? 'User').toString().trim();
    final displayName = name.isEmpty ? 'User' : name;
    final age = userData['age'];
    final ageStr = age == null ? '' : age.toString();

    return Text.rich(
      TextSpan(
        style: _textStyle,
        children: [
          TextSpan(
            text: displayName,
            style: _textStyle.copyWith(
              fontFamily: AppTypography.manropeFamily,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (ageStr.isNotEmpty)
            TextSpan(
              text: ', $ageStr',
              style: _textStyle.copyWith(
                fontFamily: AppTypography.manropeFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _LikedUserModeBadge(discoveryMode: discoveryMode),
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _LikedUserModeBadge extends StatelessWidget {
  const _LikedUserModeBadge({this.discoveryMode});

  final String? discoveryMode;

  static const Color _datingBadgeColor = Color(0xFFED865E);

  @override
  Widget build(BuildContext context) {
    final isSocial = discoveryMode == kDiscoveryModeSocial;
    final iconAsset =
        isSocial ? AppIcons.handWaveSolid : AppIcons.heartSolid;
    final badgeColor = isSocial ? kBrandAccent : _datingBadgeColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badgeColor,
        boxShadow: const [],
      ),
      child: SizedBox(
        width: 21,
        height: 21,
        child: Center(
          child: AppIcon(
            iconAsset,
            size: isSocial ? 14 : 13,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _LikedCardDenominationLine extends StatelessWidget {
  const _LikedCardDenominationLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.church_outlined, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
