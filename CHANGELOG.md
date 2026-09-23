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

## [5.1.4.1] - 2026-09-23

Sync with upstream **v5.1.4** plus the five commits after it on `master`
(upstream releases v3.11.0–v5.1.4, 923 commits).

### Upstream changes pulled in
- **List view**: a full token-line list mode (per-chip, pinch to change rows,
  layout presets, progress bars, bulk-selection checkboxes), alongside covers
  and spines; the footer hold cycles covers -> list -> spines.
- **Spines and ornaments**: bookshelf spine view with face-out covers (next
  unread in series, recently added), shelf ornaments (SVG/PNG) and theming.
- **OPDS catalogs as chips**: SQLite-backed feed windows, read-ahead, catalog
  add/edit/delete, per-chip download folder, cover previews in the hero.
- **Kindle library** as a chip source; calibre custom columns and a second
  series stack from a Calibre series column.
- Shelf styles: collage / ribbon / pile folder tiles, per-kind display modes,
  per-chip and selected-chip colours, uppercase labels, cover shape and corner
  options.
- Reorganised plugin menu (4.0), a "go to home screen" Dispatcher action,
  adjustable in-reader launcher, a browsable cached changelog viewer, and a
  fresh-install default of four shelves and a real micro-module arrangement.
- Hot parking: a reader is kept alive under the shelf instead of being torn
  down, plus close-path perf work (issue 422) and night-mode panel repair.
- Russian and Slovak translations, plus translation rounds for every release.

### Fork fixes retained
- **Screensaver host fallback** for suspend while Bookshelf owns the home screen.
- **`onRequestSuspend` handler** while Bookshelf is the topmost widget.
- **Multiswipe sleep gesture**, now also reading the reader-side suspend binding
  from the parked ReaderUI when upstream's hot parking leaves no FileManager.
- **Updater fork URLs**, extended to upstream's new changelog viewer: its
  on-demand Refresh now fetches this fork's releases (the updater already seeds
  the same cache from the fork), instead of mixing in upstream's notes. The
  updater exports `REPO_SLUG` / `githubApi` for this; `tests/_test_updater.lua`
  expects the fork's zipball URL.
- `quote_of_day` FileManager nil-guard: already in upstream, nothing to carry.

## [3.10.9.1] - 2026-08-01

Sync with upstream **v3.10.9** (upstream releases v3.10.3–v3.10.9).

### Upstream changes pulled in
- Faster book closing from file-browser gestures and the quick menu, with
  canonical reader rotation restored when parking a book.
- True-aspect folder and series stack covers, smoother stack-card corners, and
  preserved shadows when opening selected covers.
- More reliable parked-reader file-manager routing and teardown handling,
  including the Exit KOReader path and current hero status on micro pages.
- New colour-panel dithering controls and cover-refresh hints for Kaleido
  devices, plus shelf-size limit feedback and pinch/zoom layout work.
- Fixes for settings shortcuts, Kobo virtual-library thumbnails, and file polls
  that could outlive the widget and wake the device.
- Refreshed translations, including Hungarian and European Portuguese, and
  translatable multi-author “and” / “et al.” joins.

### Fork fixes retained
- **Screensaver host fallback** for suspend while Bookshelf owns the home screen.
- **`onRequestSuspend` handler** while Bookshelf is the topmost widget.
- **Multiswipe sleep gesture** using reader-side suspend bindings.
- **Updater fork URLs** so stable and developer updates remain on this fork.
- Upstream’s lifecycle-tied `_restoring_from_reader` active-chip protection.

## [3.10.2.1] - 2026-07-12

Sync with upstream **v3.10.2** (98 commits since v3.8.4, spanning upstream
releases v3.8.5–v3.8.10, v3.9.0, and v3.10.0–v3.10.2).

### Upstream changes pulled in
- New **Cover** tab for finding and applying local or online covers, with
  ISBN-first matching, multiple sources, resolution ranking, deduplication, and
  bounded caches.
- Optional true-aspect cover rendering across the hero, collapsed, expanded,
  and title shelf layouts.
- Hot reader parking for faster book-to-shelf returns, including correct
  gesture forwarding, exit routing, rotation restoration, and transition paint.
- Configurable opening-cover and start-menu animations, plus chip-strip page
  animation and colour e-ink refresh improvements.
- New start-menu options for icon-only entries and scoped dividers; device Back
  now climbs one chip drill-down level; new chip-strip paging gesture actions.
- Fixes for newer KOReader updater compatibility, Exit KOReader gestures,
  Hardcover review fetching and ratings, deep-folder status filters, hero-swipe
  pagination, author parsing, series filtering/sorting, and PocketBook cover-tab
  pagination.
- Added Portuguese (Portugal) translation and refreshed existing translations.

### Fork fixes retained
- **Screensaver host fallback** for suspend while Bookshelf owns the home screen.
- **`onRequestSuspend` handler** while Bookshelf is the topmost widget.
- **Multiswipe sleep gesture** using reader-side suspend bindings.
- **Updater fork URLs** so stable and developer updates remain on this fork.
- Upstream's lifecycle-tied `_restoring_from_reader` active-chip protection.

### Fork fix superseded by upstream
- The `quote_of_day` `FileManager.instance` nil-guard is now present upstream;
  the upstream implementation is retained.

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

[Unreleased]: https://github.com/lolwierd/bookshelf.koplugin/compare/v3.10.2.1...HEAD
[3.10.2.1]: https://github.com/lolwierd/bookshelf.koplugin/releases/tag/v3.10.2.1
[3.8.4.1]: https://github.com/lolwierd/bookshelf.koplugin/releases/tag/v3.8.4.1
[3.5.3.1]: https://github.com/lolwierd/bookshelf.koplugin/releases/tag/v3.5.3.1
[3.2.2.1]: https://github.com/lolwierd/bookshelf.koplugin/releases/tag/v3.2.2.1
