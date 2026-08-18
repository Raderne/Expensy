# Changelog

All notable changes to Expensy are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**This file is the source of the release notes shown inside the app.** `.github/workflows/publish.yml`
slices the section matching `frontend/pubspec.yaml`'s version and posts it as the GitHub release
body; the app renders that body through `SimpleMarkdown` in the update sheet and the What's New
sheet. A release with no matching section here fails rather than shipping an APK with empty notes.

So the formatting matters. `SimpleMarkdown` renders a deliberate subset:

| Syntax           | Renders as                          |
| ---------------- | ----------------------------------- |
| `### Added`      | section heading                      |
| `- item`         | bullet (`*` and `•` also work)       |
| `**bold**`       | bold inline                          |
| `` `code` ``     | inline code                          |
| `[text](url)`    | the text (the URL is dropped)        |

Use the standard Keep a Changelog headings — `### Added`, `### Changed`, `### Deprecated`,
`### Removed`, `### Fixed`, `### Security` — and keep every item a single `- ` bullet on one line.
Write for the person tapping "What's new", not for the commit log.

Releases before 1.7.0 predate this file; their notes were generated from commit messages and
remain on the [GitHub releases page](https://github.com/Raderne/Expensy/releases).

## [Unreleased]

## [1.7.0] - 2026-08-18

Large-screen and foldable support, built around the Galaxy Z Fold 7's inner display.

### Added

- Two-pane layout when the phone is unfolded: Home sits beside your transactions, Stats beside the matching list, and Profile opens each setting next to the list instead of navigating away.
- A navigation rail replaces the bottom bar on the unfolded screen, with the add button kept low so it stays in reach on an 8-inch display.
- Add Expense opens as a side panel when unfolded, so the list stays visible while you enter an expense.
- Tabletop support: half-fold the phone and the panes stack above and below the crease.
- Tapping a category in the Stats legend filters the transactions panel beside it.
- Profile highlights the row whose detail is currently open in the side panel.

### Changed

- Page margins adapt to the space available, and long content is centred rather than stretched edge to edge on wide screens.
- Bottom sheets are capped and centred on wide screens, and tapping the space beside a sheet now closes it.
- The category picker shows four tiles per row wherever there is room, in the Add Expense panel and the full category sheet alike.
- Sign-in, sign-up and password-reset forms are capped to a comfortable reading width on large screens.
- Recent activity is hidden on the Home panel when the full transactions list is already showing beside it.

### Fixed

- Starting an expense unfolded and then folding the phone no longer discards what you had entered — the entry continues full screen.
- The onboarding prompt and the Transactions title no longer overflow in a narrow window or at a large system font size.
- Navigation labels no longer burst out of the bar at the largest system font sizes.
- The category picker no longer flashes one frame at the wrong tile size when the layout changes.
