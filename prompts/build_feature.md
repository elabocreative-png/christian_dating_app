# Build feature — ChristMeets

You are the lead Flutter engineer for this repo.

Read and follow:

- @docs/product_spec.md
- @docs/ui_guidelines.md
- @AGENTS.md
- @.cursor/rules/architecture.mdc
- @.cursor/rules/flutter-standards.mdc
- @.cursor/rules/ui.mdc

Build the **requested feature** using:

- **Riverpod** — `ConsumerWidget` / `ConsumerStatefulWidget`; providers in `presentation/*_providers.dart`
- **GoRouter** — `AppRoutes` + `core/navigation/app_router.dart`
- **Firebase** — Auth and Firestore only in `features/*/data/` repositories
- **Feature-first architecture** — `data/` · optional `domain/` · `presentation/`
- **Concrete repository classes** — no repository interfaces, entities, or use cases unless the user explicitly requests a migration

## Before writing code

Post a short plan covering:

1. **Implementation plan** — data → domain (if needed) → providers → presentation → routes
2. **Folder structure** — paths under `lib/features/<name>/` or extensions to an existing feature
3. **Files to create or modify** — explicit list with one-line purpose each
4. **Reuse** — existing repositories, providers, widgets, and domain helpers you will extend instead of duplicating

Wait for user confirmation on the plan if the feature is large or ambiguous. For small, clear requests, proceed after posting the plan.

## Implementation requirements

- **Production-ready** — no TODO stubs for core paths; handle edge cases
- **Loading, empty, and error states** on every user-facing screen or major async section
- **Widget size** — keep screen and primary widget files ≤200 lines; extract to `presentation/widgets/`
- **No Firestore in presentation or domain** — parse timestamps via `core/utils/firestore_value_utils.dart`
- **Imports** — `package:christian_dating_app/...` only; no cross-folder relative imports
- **Do not introduce** patterns listed under “Planned — do NOT introduce unsolicited” in `flutter-standards.mdc`
- **Scope** — implement only what was requested; do not refactor unrelated code

## Routing

- Add path constants to `core/navigation/app_routes.dart`
- Register routes in `core/navigation/app_router.dart`
- Use `context.push` / `context.go` for full-screen navigation
- Modal sheets and dialogs may use `showModalBottomSheet` / `showDialog` with `Navigator.pop` on the overlay context

## Testing and verification

Before finishing:

```bash
flutter analyze
flutter test
```

Add repository or widget tests for non-trivial behavior (follow patterns in `test/`).

## After implementation

Summarize what was built, which routes/providers were added, and any assumptions made vs `docs/product_spec.md`.

The Cursor **stop hook** may auto-trigger `@prompts/review_code.md` when `lib/` changes — ensure the diff is review-ready.
