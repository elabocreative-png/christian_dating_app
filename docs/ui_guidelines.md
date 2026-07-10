# UI guidelines — ChristMeets

> Visual and presentation-layer conventions. Layering and Riverpod rules live in
> `.cursor/rules/flutter-standards.mdc` and `.cursor/rules/architecture.mdc`.

## Principles

- Keep UI **clean and minimal** — one primary action per section; avoid visual clutter.
- **Prefer composition** over deeply nested widgets or long `_build*` method chains.
- **Screens display data and trigger actions** — they do not query Firestore, filter decks, or encode business rules.
- **Every user-facing async surface** needs loading, empty, and error handling.

## Widget structure

- Screen files (`*_screen.dart`) and primary widgets: **≤200 lines**.
- Extract sections to `features/<name>/presentation/widgets/`.
- Use **`ConsumerWidget`** / **`ConsumerStatefulWidget`** when reading providers.
- **`setState`** only for local UI (drag, animations, text controllers, tab index).
- Prefer **`const`** constructors where values are compile-time constant.

### Composition pattern

```dart
@override
Widget build(BuildContext context) {
  final data = ref.watch(myFeatureProvider);
  return Scaffold(
    body: data.when(
      loading: () => const MyFeatureLoading(),
      error: (e, _) => MyFeatureError(message: e.toString()),
      data: (items) => items.isEmpty
          ? const MyFeatureEmpty()
          : MyFeatureContent(items: items),
    ),
  );
}
```

Split `MyFeatureLoading`, `MyFeatureEmpty`, `MyFeatureError`, and `MyFeatureContent` into separate widget files when non-trivial.

## Theme and typography

Global theme is configured in `lib/main.dart` (Material 3, white scaffold, Manrope).

| Source | Use for |
|--------|---------|
| `AppTypography` (`core/theme/app_typography.dart`) | All text — `emptyStateTitle()`, `emptyStateBody()`, `semiBold()`, field styles, etc. |
| `Theme.of(context).colorScheme` | Surfaces, primary, onSurface — prefer over hard-coded colors |
| `AppIcons` (`core/theme/app_icons.dart`) | Standard icon assets |
| `AppIllustrations` (`core/theme/app_illustrations.dart`) | Empty-state and marketing SVGs |

Avoid ad-hoc `TextStyle(fontSize: …)` unless matching an existing one-off screen. Do not introduce a second font family.

## Spacing defaults

Use consistent rhythm (match existing screens):

| Token | Typical use |
|-------|-------------|
| `16` | Screen horizontal padding, card padding, section insets |
| `12` | Chip/pill horizontal padding, grid gaps |
| `8` | Small gaps between related elements, grid cross-axis spacing |
| `4` | Tight spacing (title → subtitle in empty states) |
| `24` | Bottom list padding, larger section breaks |

Prefer `EdgeInsets.fromLTRB(16, …)` for screen bodies. Reuse layout constants from nearby widgets (e.g. `EmptyStateIllustrationLayout`) instead of inventing new sizes.

## Shared widgets — reuse before creating

| Widget | Location | When to use |
|--------|----------|-------------|
| `AppDialog` | `core/widgets/app_dialog.dart` | Confirmations, logout, destructive actions |
| `AppIcon` | `core/widgets/app_icon.dart` | Sized SVG/icon wrapper |
| `AppBackButton` | `core/widgets/app_back_button.dart` | Custom app bar back |
| `ProfilePhotoPlaceholder` | `core/widgets/profile_photo_placeholder.dart` | Missing profile photos |
| `ProfileAvatar` | `core/widgets/profile_avatar.dart` | Circular avatars |
| `VerifiedNameAge` | `core/widgets/verified_name_age.dart` | Name + age line |
| `EmptyStateIllustration` | `features/matches/presentation/widgets/empty_state_illustration.dart` | Empty tabs/lists |
| `AppSkeleton` / `SkeletonBox` | `features/matches/presentation/widgets/skeleton_loaders.dart` | Loading placeholders |
| `BlockReportSheet` | `core/widgets/block_report_sheet.dart` | Block/report from profiles |
| `showUserProfileBottomSheet` | `core/widgets/user_profile_bottom_sheet.dart` | Full profile preview |

Promote a widget to `core/widgets/` only when **two or more features** need it.

## Loading states

- **Lists/grids:** shimmer skeletons via `AppSkeleton` + `SkeletonBox` (see liked-you, match list).
- **Full screen / deck:** dedicated loading widget (e.g. `DiscoveryRadarLoading`).
- **Inline actions:** `CircularProgressIndicator` on buttons or small overlays — disable the action while loading.

Use `AsyncValue.when` / `ref.watch(...).when` from Riverpod providers rather than manual loading flags when data comes from providers.

## Empty states

Pattern used across Liked You, Chats, and Discovery:

1. Centered column, `mainAxisSize: MainAxisSize.min`
2. `EmptyStateIllustration` with asset from `AppIllustrations`
3. Title — `AppTypography.emptyStateTitle()`
4. Body — `AppTypography.emptyStateBody()`
5. Optional primary CTA (e.g. “Go to Discover”)

Copy should be short, friendly, and specific to the tab (not generic “No data”).

## Error states

- Show a clear message; avoid raw exception text in production UI when a friendly alternative exists.
- Offer **retry** when the user can fix it (network, permission denied).
- Log or surface technical detail only in debug-oriented flows (settings/report).

Handle errors at the provider/`AsyncValue` level when possible; the screen chooses the error widget.

## Dialogs and sheets

- **Full-screen routes:** GoRouter (`context.push` / `context.go`).
- **Confirmations / alerts:** `AppDialog` or `showDialog` + `Navigator.pop` on dialog context.
- **Filters / pickers / actions:** `showModalBottomSheet` + `Navigator.pop` on sheet context.

This matches the intentional exception documented in `AGENTS.md`.

## Anti-patterns

- Firestore or repository calls inside `build`
- Sorting, filtering, or match logic in widgets (belongs in `domain/` or providers)
- Copy-pasting empty-state layout instead of reusing `EmptyStateIllustration` + typography helpers
- Mega-widgets with 10+ `_build*` methods
- Hard-coded colors that duplicate `Theme.of(context)` or brand tokens from `main.dart`
- New skeleton/shimmer implementations when `AppSkeleton` exists

## References in the codebase

- Empty state: `liked_you_screen.dart` → `_buildEmptyState`
- Provider-driven loading/error: `liked_you_screen.dart` → `profilesAsync.when`
- Dialog styling: `app_dialog.dart`
- Typography helpers: `app_typography.dart`
