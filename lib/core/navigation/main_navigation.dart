import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/core/navigation/home_shell_providers.dart';
import 'package:christian_dating_app/core/navigation/nav_tab_badge.dart';
import 'package:christian_dating_app/core/theme/app_icons.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/discovery/data/discovery_repository.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/discovery/presentation/discovery_screen.dart';
import 'package:christian_dating_app/features/discovery/presentation/widgets/discovery_distance_filter_sheet.dart';
import 'package:christian_dating_app/features/discovery/presentation/widgets/discovery_mode_toggle.dart';
import 'package:christian_dating_app/features/discovery/presentation/widgets/discovery_premium_pill.dart';
import 'package:christian_dating_app/features/matches/presentation/nav_badge_providers.dart';
import 'package:christian_dating_app/features/settings/data/push_notification_service.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends ConsumerState<MainNavigation> {
  String _discoveryMode = kDiscoveryModeDating;

  int get _selectedIndex => widget.navigationShell.currentIndex;

  @override
  void initState() {
    super.initState();
    _loadDiscoveryMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeShellTabIndexProvider.notifier).setIndex(_selectedIndex);
      final push = ref.read(pushNotificationServiceProvider);
      push.handlePendingNotification();
      final uid = ref.read(currentUserIdProvider);
      if (uid != null) {
        push.syncTokenForUser(uid);
      }
    });
  }

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    if (ref.read(homeShellTabIndexProvider) != index) {
      ref.read(homeShellTabIndexProvider.notifier).setIndex(index);
    }
  }

  Future<void> _loadDiscoveryMode() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final mode =
        await ref.read(discoveryRepositoryProvider).fetchDiscoveryMode(uid);
    if (!mounted) return;

    setState(() => _discoveryMode = mode);
  }

  Future<void> _setDiscoveryMode(String mode) async {
    if (_discoveryMode == mode) return;

    setState(() => _discoveryMode = mode);

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    await ref.read(discoveryRepositoryProvider).saveDiscoveryMode(uid, mode);
    await discoveryScreenKey.currentState?.onDiscoveryModeChanged(mode);
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      discoveryScreenKey.currentState?.refreshUsers();
    }

    final isReselect = index == _selectedIndex;
    ref.read(homeShellTabIndexProvider.notifier).setIndex(index);
    widget.navigationShell.goBranch(
      index,
      initialLocation: !isReselect,
    );
  }

  Widget _navIcon({
    required String solidAsset,
    required String outlineAsset,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: AppIcon(
        selected ? solidAsset : outlineAsset,
        size: 24,
        colorMapper: selected
            ? const SelectedNavColorMapper()
            : const UnselectedNavColorMapper(),
      ),
    );
  }

  Widget _navIconWithBadge({
    required String solidAsset,
    required String outlineAsset,
    required bool selected,
    required int badgeCount,
  }) {
    return NavTabBadge(
      count: badgeCount,
      child: _navIcon(
        solidAsset: solidAsset,
        outlineAsset: outlineAsset,
        selected: selected,
      ),
    );
  }

  Widget _buildBottomNavigationBar(String uid) {
    final likedYouCount = ref.watch(likedYouCountProvider(uid));
    final unreadMessageThreads = ref.watch(unreadMessageThreadsProvider(uid));

    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: _navIcon(
              solidAsset: AppIcons.cardsSolid,
              outlineAsset: AppIcons.cardsOutline,
              selected: false,
            ),
            activeIcon: _navIcon(
              solidAsset: AppIcons.cardsSolid,
              outlineAsset: AppIcons.cardsOutline,
              selected: true,
            ),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: _navIconWithBadge(
              solidAsset: AppIcons.heartSolid,
              outlineAsset: AppIcons.heartOutline,
              selected: false,
              badgeCount: likedYouCount,
            ),
            activeIcon: _navIconWithBadge(
              solidAsset: AppIcons.heartSolid,
              outlineAsset: AppIcons.heartOutline,
              selected: true,
              badgeCount: likedYouCount,
            ),
            label: 'Liked you',
          ),
          BottomNavigationBarItem(
            icon: _navIconWithBadge(
              solidAsset: AppIcons.chatsSolid,
              outlineAsset: AppIcons.chatsOutline,
              selected: false,
              badgeCount: unreadMessageThreads,
            ),
            activeIcon: _navIconWithBadge(
              solidAsset: AppIcons.chatsSolid,
              outlineAsset: AppIcons.chatsOutline,
              selected: true,
              badgeCount: unreadMessageThreads,
            ),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: _navIcon(
              solidAsset: AppIcons.profileSolid,
              outlineAsset: AppIcons.profileOutline,
              selected: false,
            ),
            activeIcon: _navIcon(
              solidAsset: AppIcons.profileSolid,
              outlineAsset: AppIcons.profileOutline,
              selected: true,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _likedYouAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      toolbarHeight: 56,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
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
                    'Liked You',
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
                tooltip: 'Filters',
                icon: AppIcon(AppIcons.filterSolid, size: 28),
                onPressed: () {
                  // reserved for future filter sheet
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _discoveryAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      toolbarHeight: 56,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
        child: SizedBox(
          height: 40,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: const DiscoveryPremiumPill(),
              ),
              DiscoveryModeToggle(
                mode: _discoveryMode,
                onModeChanged: _setDiscoveryMode,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 40,
                      ),
                      tooltip: 'Undo',
                      icon: AppIcon(AppIcons.undoSolid, size: 26),
                      onPressed: () {
                        discoveryScreenKey.currentState?.undoLastPass();
                      },
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 40,
                      ),
                      tooltip: 'Filters',
                      icon: AppIcon(AppIcons.filterSolid, size: 28),
                      onPressed: () async {
                        final applied =
                            await showDiscoveryDistanceFilterSheet(context);
                        if (applied == true) {
                          discoveryScreenKey.currentState?.refreshUsers();
                        }
                        await _loadDiscoveryMode();
                      },
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

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: kSystemNavigationBarBackground,
      appBar: _selectedIndex == 0
          ? _discoveryAppBar()
          : _selectedIndex == 1
              ? _likedYouAppBar()
              : null,
      body: widget.navigationShell,
      bottomNavigationBar: uid == null
          ? null
          : ColoredBox(
              color: Colors.white,
              child: _buildBottomNavigationBar(uid),
            ),
    );
  }
}

/// Switches the main tab shell without reaching for [MainNavigationState].
void goHomeShellTab(BuildContext context, AppHomeTab tab) {
  final index = tab.index;
  ProviderScope.containerOf(context)
      .read(homeShellTabIndexProvider.notifier)
      .setIndex(index);
  context.go(switch (tab) {
    AppHomeTab.discover => AppRoutes.homeDiscover,
    AppHomeTab.likedYou => AppRoutes.homeLikedYou,
    AppHomeTab.chats => AppRoutes.homeChats,
    AppHomeTab.profile => AppRoutes.homeProfile,
  });
}

enum AppHomeTab {
  discover,
  likedYou,
  chats,
  profile,
}
