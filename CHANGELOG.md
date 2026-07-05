# Changelog

All notable changes to this **fork** (`lolwierd/bookshelf.koplugin`) are recorded
here. The release workflow (`.github/workflows/release.yml`) reads the section
whose header matches the release version and uses it as the GitHub release body,
so keep each version's notes under a `## [X.Y.Z.N] - YYYY-MM-DD` header.

Format loosely follows [Keep a Changelog](https://keepachangelog.com/).
Versioning: `MAJOR.MINOR.PATCH` tracks the upstream base
([AndyHazz/bookshelf.koplugin](https://github.com/AndyHazz/bookshelf.koplugin));
the trailing `.N` is the fork revision, reset whenever the upstream base changes.

## [Unreleased]

_Nothing yet._

## [3.8.4.1] - 2026-07-05

Sync with upstream **v3.8.4** (124 commits since the previous base v3.5.3, spanning
upstream releases v3.6.0, v3.7.0, and v3.8.0–v3.8.4), with all fork fixes retained.

### Upstream changes pulled in
- Tabbed book-detail popup (Description / Reviews / Tags / Edit) with per-tab font
  zoom and gesture passthrough.
- New **Series** filter (standalone books vs books in a series).
- Page-turn wipe animation for shelf pagination.
- Compact Tags-tab sections with an always-available Edit button; D-pad/keyboard
  navigation for tag pills and edit buttons.
- Kobo source module and a dedicated pagination module.
- Fixes: brightness/warmth edge swipes in Bookshelf (#231), gesture events that
  could exit KOReader (#225), blurry book-detail cover preview (#228), "Go to
  letter" jump capped at 512 items (#229), and more.
- i18n: Japanese and Vietnamese added; zh_CN and others refreshed.

### Fork fixes retained
- **Screensaver host fallback** — no blank screen on suspend when neither
  FileManager nor ReaderUI is active.
- **`onRequestSuspend` handler** — suspend handled directly while Bookshelf is the
  visible home.
- **Multiswipe sleep gesture** — reader-side multiswipe→sleep bindings honoured on
  Bookshelf.
- **Updater → fork URLs** — update checks, branch installs, and release links point
  at this fork.
- **`quote_of_day` FileManager nil-guard** — no crash opening bookmarks from the
  in-reader launcher.

### Fork fixes superseded by upstream's (better) solution
- **Active chip preserved on reader return** — replaced the fork's 10s
  `_suppressPathChangedFor` timer with upstream's lifecycle-tied `#204`
  `_restoring_from_reader` flag.
- **FM touch-zone menu passthrough (#79)** — replaced the fork's inline walk with
  upstream's shared `GestureZones.tryFMZones` (behaviourally identical).
- **Book-detail `FileManager.instance` nil-crash** — the old `_openBookMenu`
  ButtonDialog was removed; upstream's tabbed `_showBookDetail` already nil-guards
  its FileManager touches, so the crash path no longer exists.

### Build
- `AGENTS.md` excluded from release zips (dev-only doc).
- Added this changelog and a `workflow_dispatch` release workflow.

## [3.5.3.1] - 2026-06-23

Sync with upstream **v3.5.3**, all fork fixes retained.

### Added (from upstream v3.5.x)
- Start menu with customizable actions, plugins, and Bookshelf shortcuts.
- Micro-modules: weather, clock, reading streak, countdown, daily fun, trivia,
  on-this-day, quote-of-day, random book, reading goal, reading stats.
- Opt-in in-reader launcher button, per-module settings, gesture actions, D-pad
  navigation, full-screen micro-module overlay.
- Rotation/white-screen fixes (Boox/Android); Hungarian + improved Chinese.

### Fixed (fork)
- Nil-guard `FileManager.instance` in BookmarkBrowser calls (quote_of_day,
  book-detail dialog) to prevent a crash from the in-reader launcher.

## [3.2.2.1] - 2026-06-14

Sync with upstream **v3.2.2** (v3.0.0–v3.2.2): Start Menu micromodules, rotation
fixes, Trivia module, cover sizing/cache fixes. All fork fixes retained.

## [2.4.6.x] - 2026-06-12

Initial fork builds on upstream **v2.4.6**, introducing the local fixes this fork
exists for: active-chip preservation on return, the screensaver host fallback,
direct `RequestSuspend` handling, the multiswipe sleep binding, and updater URLs
pointed at the fork.

[Unreleased]: https://github.com/lolwierd/bookshelf.koplugin/compare/v3.8.4.1...HEAD
[3.8.4.1]: https://github.com/lolwierd/bookshelf.koplugin/releases/tag/v3.8.4.1
[3.5.3.1]: https://github.com/lolwierd/bookshelf.koplugin/releases/tag/v3.5.3.1
[3.2.2.1]: https://github.com/lolwierd/bookshelf.koplugin/releases/tag/v3.2.2.1
