import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/features/profile/domain/profile_completion.dart';
import 'package:christian_dating_app/core/models/profile_photo_urls.dart';
import 'package:christian_dating_app/widgets/profile_photo_placeholder.dart';
import 'package:christian_dating_app/widgets/verified_name_age.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:christian_dating_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:christian_dating_app/settings_screen.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_plans_tab_content.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_safety_tab_content.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_tab_bar_delegate.dart';
import 'package:christian_dating_app/widgets/user_profile_bottom_sheet.dart';
import 'package:christian_dating_app/widgets/app_icon.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Color _profileTeal = Color(0xFF000000);
  static const Color _profileOrange = Color(0xFF000000);
  static const Color _editPillBg = Color(0xFFF2F2F2);
  static const double _tabContentGap = 16;

  late final TabController _tabController;

  User? user;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      loadUser();
    }
  }

  Future<void> loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return; // 🔥 safety

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!mounted) return;

    setState(() {
      userData = doc.data();
    });
  }

  void _showProfileBottomSheet(BuildContext context) {
    if (userData == null || FirebaseAuth.instance.currentUser == null) return;
    showUserProfileBottomSheet(
      context,
      user: userData!,
      profileUserId: FirebaseAuth.instance.currentUser?.uid,
      title: 'Me',
      onEdit: _openEditProfile,
    );
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const EditProfileScreen(),
      ),
    );
    if (mounted) await loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildProfileHeader(String? photoUrl) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AvatarWithCompletion(
              photoUrl: photoUrl,
              gender: userData!['gender']?.toString(),
              completion: profileCompletionFraction(userData!),
              onTap: () => _showProfileBottomSheet(context),
              progressColor: _profileTeal,
              badgeColor: _profileOrange,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VerifiedNameAge(
                    userData: userData!,
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _EditProfilePill(
                    isComplete: isProfileFullyComplete(userData!),
                    onTap: _openEditProfile,
                    backgroundColor: _editPillBg,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox();
    }

    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final photoUrl = ProfilePhotoUrls.photoAt(userData!);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 56,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: SizedBox(
            height: 36,
            width: double.infinity,
            child: Row(
              children: [
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 36,
                  ),
                  tooltip: 'Settings',
                  icon: const AppIcon(AppIcons.settings, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader(photoUrl)),
          SliverPersistentHeader(
            pinned: true,
            delegate: ProfileTabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
                indicatorColor: Colors.black87,
                indicatorWeight: 0.75,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Colors.grey.withValues(alpha: 0.08);
                  }
                  if (states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)) {
                    return Colors.grey.withValues(alpha: 0.04);
                  }
                  return Colors.transparent;
                }),
                tabs: const [
                  Tab(text: 'Plans'),
                  Tab(text: 'Safety'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                _tabContentGap,
                16,
                _tabContentGap + bottomInset,
              ),
              child: IndexedStack(
                index: _tabController.index,
                sizing: StackFit.loose,
                children: const [
                  ProfilePlansTabContent(),
                  ProfileSafetyTabContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithCompletion extends StatelessWidget {
  const _AvatarWithCompletion({
    required this.photoUrl,
    required this.gender,
    required this.completion,
    required this.onTap,
    required this.progressColor,
    required this.badgeColor,
  });

  final String? photoUrl;
  final String? gender;
  final double completion;
  final VoidCallback? onTap;
  final Color progressColor;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    const ringSize = 100.0;
    const stroke = 4.0;
    final clamped = completion.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final innerSize = ringSize - stroke * 2.8;

    const pillHPadding = 12.0;
    // ~7px per glyph at 12px w700 — keeps arc tie-in close to real pill width without TextPainter in build.
    final pillHalfWidth =
        (('$percent%'.length * 7.0) + pillHPadding * 2) / 2;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: ringSize,
        height: ringSize + 6,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(ringSize, ringSize),
                    painter: _ProfileCompletionRingPainter(
                      progress: clamped,
                      pillHalfWidth: pillHalfWidth,
                      strokeWidth: stroke,
                      trackColor: const Color(0xFFE8E8E8),
                      progressColor: progressColor,
                    ),
                  ),
                  ClipOval(
                    child: SizedBox(
                      width: innerSize,
                      height: innerSize,
                      child: photoUrl != null
                          ? NetworkProfileImage(
                              url: photoUrl!,
                              gender: gender,
                              useGenderSilhouette: true,
                              silhouetteStyle: GenderSilhouetteStyle.avatar,
                              fit: BoxFit.cover,
                              iconSize: 56,
                            )
                          : GenderSilhouettePlaceholder(
                              gender: gender,
                              style: GenderSilhouetteStyle.avatar,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      height: 1.1,
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
}

/// Full grey ring + black progress as a fraction of the full circumference
/// (starts at the pill’s left attachment, sweeps clockwise).
class _ProfileCompletionRingPainter extends CustomPainter {
  _ProfileCompletionRingPainter({
    required this.progress,
    required this.pillHalfWidth,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final double pillHalfWidth;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.shortestSide - strokeWidth) / 2;
    if (r <= 0) return;

    final a = (pillHalfWidth / r).clamp(0.0, 0.999);
    final thetaLeft = math.pi - math.acos(a);

    final arcRect = Rect.fromCircle(center: center, radius: r);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Full grey ring (always visible around the avatar).
    canvas.drawCircle(center, r, trackPaint);

    final p = progress.clamp(0.0, 1.0);
    if (p > 0) {
      // Visually match %: sweep this fraction of the full circle (clockwise),
      // starting at the ring point above the pill’s left edge.
      if (p >= 1.0) {
        canvas.drawCircle(center, r, progressPaint);
      } else {
        canvas.drawArc(
          arcRect,
          thetaLeft,
          2 * math.pi * p,
          false,
          progressPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileCompletionRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pillHalfWidth != pillHalfWidth ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _EditProfilePill extends StatelessWidget {
  const _EditProfilePill({
    required this.isComplete,
    required this.onTap,
    required this.backgroundColor,
  });

  final bool isComplete;
  final VoidCallback? onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final label = isComplete ? 'Edit Profile' : 'Complete profile';

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.edit, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
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
