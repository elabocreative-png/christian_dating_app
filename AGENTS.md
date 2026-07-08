# ChristMeets — agent guide

Flutter dating app (`christian_dating_app`). Feature-first layout under `lib/features/`,
shared code in `lib/core/`. Deeper rules live in `.cursor/rules/architecture.mdc` and
`.cursor/rules/flutter-standards.mdc`.

## Architecture (current)

```
presentation/  →  Riverpod providers + widgets (no cloud_firestore)
domain/        →  pure logic, unit-testable (no Firebase imports)
data/          →  *Repository classes, legacy *Service writers, Firestore access
```

**Repositories** (prefer these for new reads/writes):

| Concern | Class | Provider |
|--------|--------|----------|
| Auth session / uid | `auth_providers.dart` | `authStateProvider`, `currentUserIdProvider`, `profileCompleteProvider` |
| Profiles | `ProfileRepository` | `profileRepositoryProvider`, `myProfileProvider`, `fetchProfilesByIds` |
| Chat | `ChatRepository` | `chatRepositoryProvider`, `chatMessagesProvider` |
| Matches / likes | `MatchesRepository` | `matchesRepositoryProvider`, `matchesStreamProvider`, `incomingLikesProvider`, `outgoingLikesProvider` |
| Discovery | `DiscoveryRepository` | `discoveryRepositoryProvider`, `discoveryDeckProvider`, `enrichWithDistance` |

**UI orchestration (presentation-only):**

- `features/matches/presentation/like_actions.dart` — `sendLikeWithUiFeedback` (match popup + snackbars after `MatchesRepository.sendLike`)
- `ProviderScope.containerOf(context).read(...)` in top-level helpers without `ref`

**Domain (pure, no Firestore):**

- `features/discovery/domain/` — deck filters, preferences helpers
- `features/matches/domain/` — `match_unread.dart`, `liked_you_filters.dart`, `match_entry.dart`
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

- `features/*/data/*` — repositories and feature services
- `core/services/` — `BlockService`, `LocationService`, `PushNotificationService`
- `features/auth/data/auth_service.dart`

**Not** in `presentation/`, `domain/`, or widgets (migration complete).

**Exceptions:**

- `FirebaseAuth` in onboarding deferred sign-up (`profile_setup_screen.dart`) and logout flows
- `core/utils/geo_utils.dart` — `GeoCoordinate`, distance helpers (no Firestore types)
- `LocationService` — device GPS; stores `GeoCoordinate`, writes `GeoPoint` at Firestore boundary

## Verification

```bash
flutter analyze
flutter test
```

Keep both green when changing architecture or providers.

## Git

- Commits only when the user asks
- Push to `origin/main` may require approval
