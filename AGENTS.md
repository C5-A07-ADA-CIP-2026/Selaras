# Selaras

An iOS app built by a three-person team. Pages: **Resep** (recipes, the home tab), **Proyek** (projects, second tab), and **Riwayat** (history, opened from a button at the top right of Proyek).

## Team

| Area | Owner | Branch |
|------|-------|--------|
| Resep | Dina | `feat/resep` |
| Proyek | Hana | `feat/proyek` |
| Riwayat, and tests for Proyek | Fany | `feat/riwayat` |

## Architecture

- Use MVVM with one folder per layer: `Selaras/Views/<Feature>/<Feature>View.swift`, `Selaras/ViewModels/<Feature>ViewModel.swift` and `Selaras/Models/<Feature>Model.swift`. Each feature's owner fills these test-first.
- Persistence is SwiftData with one shared schema in `Selaras/Shared/SelarasSchema.swift`, which lists the entities `Resep` and `Proyek`. Resep saves recipes, Proyek picks a `Resep` and saves a `Proyek` snapshot, and Riwayat lists saved `Proyek`s.
- Tests mirror the layers: `SelarasTests/ViewModels/` and `SelarasTests/Models/`.
- Shared components and extensions go in `Selaras/Shared/`. Name files with the feature prefix and keep each feature's views in its own `Views/<Feature>/` folder to avoid merge conflicts.
- Use test-driven development with Swift Testing: write tests before implementation and cover changed behavior.
- Ask before adding dependencies; prefer first-party Apple frameworks.

## Git workflow

- Branches: `main` (default, released to TestFlight), `staging`, `dev` (integration). Feature work happens on `feat/resep`, `feat/proyek` and `feat/riwayat`, which branch from and merge back into `dev` through pull requests.
- Jira project: <https://mariabelenn2405.atlassian.net/browse/KAN>. Tickets look like `KAN-12`. If you need a ticket ID, ask the user if none was provided; if still not given, omit it.
- Name extra short-lived branches `<type>/<jira-ticket-id>-short-descriptive-name`.
- Use Conventional Commits: `type(scope): subject` (for example, `feat(resep): add recipe list`).
- Title PRs `<type>(JIRA-TICKET-ID): Short Descriptive Name`.
- Explain what changed and why in PR descriptions; include screenshots for UI changes.
- Do not add Claude (or any AI) as a co-author on commits or PRs.

## Tooling

- Run `brew bundle` once to install SwiftLint and SwiftFormat.
- Use XcodeBuildMCP for builds, tests, and simulator runs.
- Invoke the `hig-compliance` skill when writing or modifying user-facing UI. It includes the accessibility rules: Text Styles for Dynamic Type (never static font sizes) and color contrast.
- Local Claude hooks run SwiftFormat and SwiftLint autofix on changed Swift files, report warnings, and block errors.

## Completion gates

For all changes:

- The build succeeds (`build_sim` with XcodeBuildMCP, or `xcodebuild build`) with no errors.
- `swiftformat --lint --swift-version 6.0 --language-mode 6 .` passes.
- `swiftlint lint --strict` passes.
- Relevant tests pass after each change; the full test suite passes before completion.

For UI changes:

- Build and run on the iPhone 17 simulator with XcodeBuildMCP.
- Capture and inspect a screenshot and the `describe_ui` element tree.
- Tap and type through the key flow.
- Text uses Text Styles and stays readable at the largest accessibility text size (preview at `.dynamicTypeSize(.accessibility5)`).
- Text and icon colors meet contrast minimums (4.5:1, or 3:1 for large/bold text) in Light, Dark and Increase Contrast.
