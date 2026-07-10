# ChristMeets — product spec

> **Audience:** Flutter engineers and AI agents building features for this app.  
> **Technical implementation:** See `AGENTS.md`, `.cursor/rules/architecture.mdc`,
> `.cursor/rules/flutter-standards.mdc`, and `docs/ui_guidelines.md`.

## Product summary

**ChristMeets** is a faith-centered dating and connection app for Christians. Users create a profile with photos, faith details, and prompts; discover nearby people; send likes (optionally with an intro message); match; and chat. Safety tooling (block, report) and account controls are first-class.

Package name: `christian_dating_app`. Primary navigation is a four-tab home shell: **Discover**, **Liked You**, **Chats**, **Profile**.

## Target users

- Christian adults (18+) seeking dating or platonic Christian community
- Users who expect faith-relevant profile fields (denomination, church, faith prompts)
- Mobile-first (iOS and Android via Flutter)

## Core user journeys

### 1. Sign up and onboarding

1. Sign in / sign up (`/login`)
2. Complete profile setup (`/onboarding`) — name, birthday (18+), gender, denomination, relationship intent, photos, prompts, location, notifications
3. Gate: incomplete profiles redirect to onboarding; complete profiles enter the home shell

### 2. Discovery

1. Browse a swipeable deck of nearby profiles (`/home/discover`)
2. Filter by distance, age, gender interest, and mode-specific preferences (`/discovery/preferences`)
3. Actions: pass, like, like with message (intro), favorite prompt/photo, block/report from profile card
4. Modes:
   - **Dating** — romantic intent; interested-in Men/Women
   - **Social** — platonic/community intent; broader interested-in options
5. Empty state when the deck is exhausted: *"You've seen everyone for now"*

### 3. Likes and matches

1. **Liked You** tab (`/home/liked-you`) — incoming likes (grid), intros (likes with messages), sent likes
2. Mutual like → **match** → match celebration popup (`/match-popup`) → chat available
3. **Chats** tab (`/home/chats`) — new connections strip + message list with unread indicators

### 4. Chat

1. Open thread from chats tab or push notification deep link (`/chat/:matchId`)
2. Send/receive messages; like individual messages; read state tracked in-session

### 5. Profile and settings

1. **Profile** tab (`/home/profile`) — view own profile, completion indicator, safety/plans tabs, edit entry
2. **Edit profile** (`/profile/edit` + nested pickers) — photos, basics, faith, prompts, location
3. **Settings** (`/settings`) — help, report issue, blocked users, deactivate account, legal (terms, privacy), FAQ

## Feature inventory (current)

| Area | Key capabilities |
|------|------------------|
| **Auth** | Email auth, session stream, profile-complete gate |
| **Onboarding** | Multi-step profile setup, faith declaration, photo grid |
| **Discovery** | Geo-based deck, swipe UX, preferences, distance filter, helper hints |
| **Matches / likes** | Send like, match detection, liked-you filters, match popup |
| **Chat** | Real-time messages, match threads, push deep links |
| **Profile** | Completion scoring, photo upload, prompts, height/birthdate pickers |
| **Settings** | Block/unblock, issue reports, FAQ, account deactivation, push notifications |

## Profile data (high level)

Profiles are stored as Firestore documents (map-shaped at repository boundaries). Important fields include:

- Identity: name, age/birthday, gender, photos
- Location: city, coordinates (via device GPS → GeoPoint at data layer)
- Faith: denomination, church, faith-related prompts
- Discovery: interested-in, age range, distance, discovery mode (dating/social)
- Engagement: prompts (question + answer), relationship intent / looking-for

Pure display and completion logic lives in `features/profile/domain/` (e.g. `profile_completion.dart`).

## Discovery rules

- Nearby users enriched with distance (`enrichWithDistance`)
- Deck filtered by preferences, blocks, and prior passes
- Dating vs social mode changes interested-in defaults and options
- Distance slider uses mile stops (20–60, Max)

## Safety and trust

- **Block** — blocked users hidden from discovery and interactions; managed in settings
- **Report** — issue report flow with repository-backed submission
- **Legal** — terms, privacy policy, FAQ content in settings
- Block/report accessible from profile views and discovery cards

## UX expectations for new features

Every user-facing screen or major widget should handle:

- **Loading** — skeleton or progress while data resolves
- **Empty** — helpful copy + illustration where appropriate (see existing empty states in discovery, chats, liked-you)
- **Error** — user-visible message; retry when sensible

Keep screen files ≤200 lines; extract sections to `presentation/widgets/`.

## Navigation model

- Full-screen routes: **GoRouter** (`AppRoutes`, `app_router.dart`)
- Main tabs: `StatefulShellRoute.indexedStack` under `/home/*`
- Modals: bottom sheets and dialogs may use `Navigator.pop` on overlay context (intentional)
- Auth redirect: `appRedirect()` sends unauthenticated users to login, incomplete profiles to onboarding

## Data and backend

- **Firebase Auth** — authentication
- **Cloud Firestore** — profiles, likes, matches, chats, blocks, reports
- **Push notifications** — chat deep links via `PushNotificationService`

All Firestore access goes through feature **repositories** in `features/*/data/`. Presentation uses **Riverpod** providers only.

## Non-goals (unless explicitly requested)

- Repository interfaces, entities, or use-case layers (single Firebase backend)
- Introducing alternative state management or routing libraries
- Web/desktop as primary targets
- Non-Christian or general-audience dating positioning

## Adding a new feature — checklist

1. Confirm which user journey and tab/route it belongs to
2. Decide feature folder: new `lib/features/<name>/` or extend an existing feature
3. Add repository methods + providers before UI
4. Register GoRouter paths in `AppRoutes` and `app_router.dart`
5. Handle loading / empty / error states
6. Add tests for non-trivial domain or widget behavior
7. Run `flutter analyze` and `flutter test`

For agent workflow, start with `@prompts/build_feature.md`. After implementation, the Cursor **stop hook** runs `@prompts/review_code.md` when `lib/` changes.

## Open product questions

Track decisions here as the product evolves:

- Premium / subscription behavior (UI placeholders exist; confirm scope before building billing)
- Verification badge rules
- Moderation workflow for reports

When building a feature that touches an open question, ask the user or document the assumption in the PR/commit message.
