# Post-generation code review — ChristMeets

Review **only files changed in the current git diff under `lib/`** (or files edited in this session that touch `lib/`).

Use project conventions:

- `docs/product_spec.md`
- `docs/ui_guidelines.md`
- `AGENTS.md`
- `.cursor/rules/architecture.mdc`
- `.cursor/rules/flutter-standards.mdc`
- `.cursor/rules/ui.mdc`

Check for:

- **Architecture violations** — feature-first layout, layering (`data` / `domain` / `presentation`), no cross-feature internals, `package:christian_dating_app/...` imports
- **Firebase misuse** — `cloud_firestore` and direct `FirebaseAuth` only in `data/` (see known exceptions in `AGENTS.md`)
- **Performance issues** — unnecessary rebuilds, missing `const`, heavy work in `build`, unbounded lists
- **Security issues** — secrets in source, unsafe user input, auth bypass, leaking PII in logs
- **Code duplication** — especially vs existing widgets, providers, or domain helpers
- **Naming consistency** — matches feature folders, providers, and repository patterns
- **Widget size** — screen and primary widget files should be ≤200 lines; flag larger files
- **Riverpod best practices** — `ref.watch` in `build`, `ref.read` in callbacks, provider placement, `autoDispose` where appropriate
- **UI guidelines** — theme/typography reuse, spacing, loading/empty/error states, shared widgets, composition (see `docs/ui_guidelines.md`)

## Output format

Group findings by severity:

- **Must fix** — breaks architecture, security, or correctness
- **Should fix** — meaningful quality or maintainability issue
- **Nice to have** — optional polish

For each finding: file path, brief issue, concrete suggestion.

Briefly note what looks good.

**Do not rewrite code unless a Must fix issue requires it.**
