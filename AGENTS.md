# ChristMeets — agent guide

Flutter dating app (`christian_dating_app`). Feature-first layout under `lib/features/`,
shared code in `lib/core/`. Deeper rules live in `.cursor/rules/architecture.mdc` and
`.cursor/rules/flutter-standards.mdc`.

## Architecture (current)

Migration to feature-first repositories + Riverpod is **complete** for presentation
(no `FutureBuilder` / `StreamBuilder` / `cloud_firestore` in `presentation/`).

```
presentation/  →  Riverpod providers + widgets (no cloud_firestore)
domain/        →  pure logic, unit-testable (no Firebase imports)
data/          →  *Repository classes, legacy *Service writers, Firestore access
```

**Repositories** (prefer these for new reads/writes):

| Concern | Class | Provider |
|--------|--------|----------|
| Auth session / uid | `AuthRepository`, `auth_providers.dart` | `authRepositoryProvider`, `authStateProvider`, `currentUserIdProvider`, `profileCompleteProvider` |
| Profiles | `ProfileRepository`, `ProfileImageRepository`, `LocationService` | `profileRepositoryProvider`, `profileImageRepositoryProvider`, `locationServiceProvider`, `myProfileProvider`, `profilesByIdsProvider`, `fetchProfilesByIds` |
| Chat | `ChatRepository` | `chatRepositoryProvider`, `chatMessagesProvider`, `chatContextProvider` |
| Matches / likes | `MatchesRepository` | `matchesRepositoryProvider`, `matchesStreamProvider`, `incomingLikesProvider`, `outgoingLikesProvider` |
| Discovery | `DiscoveryRepository` | `discoveryRepositoryProvider`, `discoveryDeckProvider`, `enrichWithDistance` |
| Settings / blocks | `BlockRepository` | `blockRepositoryProvider`, `blockedUserIdsProvider`, `blockedRecordsProvider` |
| Settings / reports | `IssueReportRepository` | `issueReportRepositoryProvider` |
| Settings / push | `PushNotificationService` | `pushNotificationServiceProvider`, `goRouterProvider` |

**Routing (GoRouter — migration complete):**

All full-screen navigation uses `goRouterProvider` / `AppRoutes`. Modal bottom sheets
and dialogs still use `showModalBottomSheet` / `showDialog` with `Navigator.pop` on the
sheet/dialog context — that is intentional.

| Path | Screen |
|------|--------|
| `/loading` | Auth/profile gate spinner |
| `/login` | Sign in / sign up |
| `/onboarding` | Profile setup |
| `/home` | Redirects to `/home/discover` |
| `/home/discover` | Discovery tab |
| `/home/liked-you` | Liked You tab |
| `/home/chats` | Chats tab |
| `/home/profile` | Profile tab |
| `/chat/:matchId` | Chat thread (push deep links) |
| `/settings` + nested | Settings stack (`help`, `report`, `blocked`, `deactivate`, `terms`, `privacy`, `faq`, `faq/:index`) |
| `/profile/edit` + nested | Edit profile + pickers (`text`, `options`, `birthdate`, `height`, `prompt-answer`) |
| `/discovery/preferences` | Discovery filters |
| `/match-popup` | Match celebration (fade, `extra`: `MatchPopupRouteArgs`) |
| `/profile/photo?url=` | Fullscreen photo viewer |
| `/image/crop` | Gallery crop flow (`extra`: `ImageCropRouteArgs`) |

- `AppRoutes` — path constants in `core/navigation/app_routes.dart`
- `appRedirect()` / `appRedirectForState()` — auth gate (replaces old `AuthGate`); covered by `test/app_redirect_test.dart`
- Push deep links → `AppRoutes.chat(matchId)` via `PushNotificationService.openChat`
- Sub-route args — `core/navigation/profile_edit_route_args.dart`, `match_popup_route_args.dart`, `ImageCropRouteArgs` in `ios_style_image_crop_screen.dart`
- Static `.push()` helpers on picker screens call `context.push()` internally

**UI orchestration (presentation-only):**

- `features/matches/presentation/like_actions.dart` — `sendLikeWithUiFeedback` (match popup + snackbars after `MatchesRepository.sendLike`)
- `features/matches/presentation/match_read_providers.dart` — `matchReadStateProvider` (in-session read badges)
- `ProviderScope.containerOf(context).read(...)` in top-level helpers without `ref`

**Domain (pure, no Firestore):**

- `features/discovery/domain/` — deck filters, preferences helpers
- `features/matches/domain/` — `match_unread.dart`, `liked_you_filters.dart`, `match_entry.dart`, `match_id.dart`
- `features/profile/domain/` — `profile_image_upload_progress.dart`, `height_utils.dart`, `profile_completion.dart`
- `core/utils/firestore_value_utils.dart` — parse Timestamp-like values without importing `cloud_firestore` in domain/presentation

## Riverpod conventions

- `ConsumerWidget` / `ConsumerStatefulWidget` where widgets need `ref`
- `ref.watch(provider)` in `build`; `ref.read(repoProvider)` in callbacks
- `StreamProvider.autoDispose.family` for live Firestore streams keyed by uid/matchId
- `FutureProvider.autoDispose.family` for one-shot loads (e.g. discovery deck)
- `setState` only for local UI (animations, drag, text controllers)
- App wrapped in `ProviderScope` in `main.dart`

## Intentional Firestore locations

`cloud_firestore` belongs only in:

- `features/*/data/*` — repositories and feature services (incl. `location_service.dart`, `push_notification_service.dart`, `auth_repository.dart`)

**Not** in `presentation/`, `domain/`, or widgets (migration complete).

**Exceptions:**

- `FirebaseAuth` in onboarding deferred sign-up (`profile_setup_screen.dart`) and logout flows
- `core/utils/geo_utils.dart` — `GeoCoordinate`, distance helpers (no Firestore types)
- `features/profile/data/location_service.dart` — device GPS; stores `GeoCoordinate`, writes `GeoPoint` at Firestore boundary

## Verification

```bash
flutter analyze
flutter test
```

Keep both green when changing architecture or providers. CI runs the same checks on push/PR to `main` (`.github/workflows/flutter_ci.yml`).

Repository integration tests use `fake_cloud_firestore` (see `test/block_repository_test.dart`, `test/chat_repository_test.dart`, `test/discovery_repository_test.dart`, `test/issue_report_repository_test.dart`, `test/matches_repository_test.dart`, `test/profile_repository_test.dart`).

Widget tests: `test/auth_screen_test.dart`, `test/nav_tab_badge_test.dart`.

## Git

- Commits only when the user asks
- Push to `origin/main` may require approval
