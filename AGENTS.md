# AGENTS.md — Bookshelf KOReader Plugin (Fork)

## What is this?

This is a **personal fork** of [AndyHazz/bookshelf.koplugin](https://github.com/AndyHazz/bookshelf.koplugin), a KOReader plugin that provides a modern library home screen for e-readers (Kobo, Kindle, Android/Boox). The upstream repo is the canonical source. This fork carries local fixes that haven't been accepted upstream and likely never will be (they're Kobo-specific / opinionated behaviour changes).

**Fork:** `lolwierd/bookshelf.koplugin`  
**Upstream:** `AndyHazz/bookshelf.koplugin`  
**Remotes:** `origin` → fork, `upstream` → AndyHazz

## Custom fixes (the reason this fork exists)

These are applied on top of every upstream release. None of them exist upstream.

| # | Fix | Files | What it does |
|---|---|---|---|
| 1 | **Screensaver host fallback** | `main.lua` (`_installScreensaverHostFallback`) | When Bookshelf is the visible home and KOReader suspends, neither `ReaderUI.instance` nor `FileManager.instance` exists. Stock `Screensaver:setup` needs one — without it the suspend path can inhibit input without drawing a sleep screen. Provides a minimal fake `FileManager` just for setup, then restores original state. |
| 2 | **`onRequestSuspend` handler** | `lib/bookshelf_widget.lua` | Handles `RequestSuspend` events directly while BookshelfWidget is the topmost widget, calling `UIManager:suspend()`. Without this, suspend requests die because the widget consumes events but doesn't forward them. |
| 3 | **Multiswipe sleep gesture** | `lib/bookshelf_widget.lua` (`handleEvent`) | When a multiswipe gesture is detected and the reader has a multiswipe→suspend binding, Bookshelf honours it instead of forwarding it as FileManager navigation. Checks `fm.gestures.settings_data.data.gesture_reader` for the binding. |
| 5 | **Updater → fork URLs** | `lib/bookshelf_updater.lua` | All GitHub API and web URLs point to `lolwierd/bookshelf.koplugin` instead of `AndyHazz/bookshelf.koplugin`. Uses `REPO_SLUG` constant with `githubApi()` / `githubWeb()` helpers. |

> **Note (fix #4 retired in v3.8.4.1):** The fork's old `_suppressPathChangedFor`
> wall-clock window is gone. Upstream's `#204` `_restoring_from_reader` flag
> (`main.lua`: set in `onCloseDocument`, cleared when the shelf re-shows in
> `Bookshelf:show`) solves the *same* "active chip jumps to the wrong folder on
> reader return" problem more cleanly — it is lifecycle-tied rather than a 10s
> timer, and keeps `_overlay_open_path` dedup consistent. **Prefer upstream's;
> do not reintroduce the timer.** Verify it survives future merges:
> `grep -c '_restoring_from_reader' main.lua` should be `4+`.

### Fixes that upstream already has (better)
| Fix | Our version | Upstream version | Verdict |
|---|---|---|---|
| `onBookMetadataChanged` nil-safe | `tostring(prop_updated)` | `type(prop_updated) == "string"` check | **Use upstream's** — it correctly handles table props too |
| PathChanged suppression on reader return (was fork fix #4) | `_suppressPathChangedFor` 10s timer | `_restoring_from_reader` lifecycle flag (#204) | **Use upstream's** — retired the fork timer in v3.8.4.1 |
| FM touch-zone walk for menu open (#79) | inline walk in `handleEvent` | `GestureZones.tryFMZones` (shared module) | **Use upstream's** — byte-for-byte equivalent, shared with ReviewsModal |
| Book-detail `FileManager.instance` nil-crash (bonus fix) | nil-guard inside `_openBookMenu` ButtonDialog | new tabbed `_showBookDetail` with already-guarded FM touches, no direct `BookmarkBrowser` open | **Use upstream's** — `_openBookMenu` removed; the crash path no longer exists |

## Syncing with upstream

> **Doing a sync/release? Follow [`UPSTREAM_SYNC.md`](UPSTREAM_SYNC.md)** — the
> self-contained step-by-step playbook (fetch → merge/resolve → verify fixes →
> test → version+CHANGELOG → push → release via the Actions workflow). The
> summary below is kept for quick reference; the playbook is the source of truth.

### When to sync
- Upstream releases accumulate (they move fast — multiple releases per week)
- After a major upstream feature drop
- When upstream fixes a bug you've been living with

### How to sync

```bash
# 1. Fetch upstream
git fetch upstream --tags

# 2. Check what's new
git log --oneline master..upstream/master | head -30

# 3. Check if any of our fixes might collide
#    Look at upstream changes to: main.lua, lib/bookshelf_widget.lua, lib/bookshelf_updater.lua

# 4. Merge
git merge upstream/master

# 5. Resolve conflicts. Common conflict areas:
#    - _meta.lua version string (always use upstream + bump afterwards)
#    - main.lua onBookMetadataChanged (always prefer upstream's type() check)
#    - Comments near _wireFastFileBrowserTab / _setupReaderButtons

# 6. After merge, verify ALL 5 fixes are intact:
grep -c '_installScreensaverHostFallback' main.lua          # should return 2+
grep -c 'onRequestSuspend' lib/bookshelf_widget.lua         # should return 2+
grep -c 'multiswipe' lib/bookshelf_widget.lua               # should return 2+
grep -c '_restoring_from_reader' main.lua                   # should return 4+ (upstream's replacement for old fork fix #4)
grep -c 'lolwierd' lib/bookshelf_updater.lua                # should return 1+

# 7. Run tests
cd tests && bash run.sh
# Expected (properly-configured UTF-8 env): all suites pass, 1 skipped.
# NOTE: on a C/POSIX-locale box with byte-based Lua 5.1, a handful of UTF-8
# tests (book_repository rating glyph, plugin_scan PUA, text_safe, tokens
# numeric entities) fail on a CLEAN upstream checkout too — those are
# environmental, not regressions. Confirm by running the same suites against
# upstream/master and comparing the failing set is identical.

# 8. Bump version
#    Edit _meta.lua: version = "X.Y.Z.N" (upstream base + .N fork revision)
#    e.g. upstream v3.5.3 → fork v3.5.3.1

# 9. Commit version bump
git add _meta.lua && git commit -m "chore(release): bump version to X.Y.Z.N (fork build)"

# 10. Push
git push origin master

# 11. Tag + release
git tag -a vX.Y.Z.N -m "vX.Y.Z.N: Fork build based on upstream vX.Y.Z..."
git push origin vX.Y.Z.N

# 12. Build and upload release ZIP
git archive --format=zip --prefix=bookshelf.koplugin/ --output=/tmp/bookshelf.koplugin.zip HEAD
gh release create vX.Y.Z.N \
  --repo lolwierd/bookshelf.koplugin \
  --title "vX.Y.Z.N — Fork build based on upstream vX.Y.Z" \
  --notes "..."  # see RELEASE_NOTES_TEMPLATE below
gh release upload vX.Y.Z.N /tmp/bookshelf.koplugin.zip --clobber
```

### What to CHECK after every merge

1. **All 5 fork fixes are intact** (grep commands above)
2. **Tests pass** (`cd tests && bash run.sh`)
3. **No `AndyHazz` strings remain** in `lib/bookshelf_updater.lua`
4. **No lingering `tostring(prop_updated)`** in `main.lua` (use upstream's `type()` check)
5. **`_meta.lua` has `name = "bookshelf"`** — upstream added it back for disabled-plugin compat
6. **`_meta.lua` version is bumped** to fork-specific (e.g. `3.5.3.1`)
7. **Release ZIP is uploaded** as an asset (the updater checks `release.assets` for a `.zip`)
8. **No orphaned merge-artifact comments** — check around `_wireFastFileBrowserTab` / `_setupReaderButtons`

### RELEASE_NOTES_TEMPLATE

```markdown
Upstream vX.Y.Z merged with all fork fixes retained.

### Local fixes retained:
- **Screensaver host fallback** — prevent blank screen on suspend when neither FileManager nor ReaderUI is active
- **onRequestSuspend handler** — handle suspend requests directly while Bookshelf is the visible home
- **Multiswipe sleep gesture** — prefer reader-side multiswipe sleep bindings on Bookshelf
- **PathChanged suppression** — keep the active chip selected when returning from a book
- **Updater URLs** — update checks, branch installs, and release links target this fork

### Upstream changes since last sync:
(List key upstream features/fixes from their release notes)

### Validation:
- All test suites pass, 1 skipped (on-device only)
```

## Known bugs fixed in this fork (not in upstream)

1. **`FileManager.instance` nil crash in `quote_of_day.lua`** — When the BookmarkBrowser is opened from the in-reader launcher, `FileManager.instance` can be nil. Fixed with `pcall(require, ...)` + nil guard. (The sibling guard once lived in `bookshelf_widget.lua`'s old `_openBookMenu` book-detail path; that function was removed in v3.8.4.1 when upstream reworked book long-press into the tabbed `_showBookDetail` flow, whose FM touches are already nil-guarded — see the "Fixes that upstream already has" table.)
2. **Orphaned comment block in `main.lua`** — Merge artifact from `_wireFastFileBrowserTab` doc colliding with `_setupReaderButtons` docs. Cleaned.

## Project structure

```
bookshelf.koplugin/
├── _meta.lua              # Plugin manifest (name, version, description)
├── main.lua               # Entry point: init, event hooks, show/hide, menus, updater
├── lib/                   # 40+ core library modules (all Lua)
│   ├── bookshelf_widget.lua       # Main home screen UI (~11k lines)
│   ├── bookshelf_book_repository.lua  # Book data access
│   ├── bookshelf_start_menu.lua   # Start menu (v3.x)
│   ├── bookshelf_updater.lua      # In-app update mechanism ← fork URLs
│   ├── bookshelf_settings*.lua    # Settings UI + persistence
│   ├── bookshelf_hero_card.lua    # Hero card (focused book detail)
│   ├── bookshelf_chip_*.lua       # Chip/shelf bar, editor, model
│   ├── bookshelf_shelf_row.lua    # Book cover grid
│   ├── bookshelf_hardcover*.lua   # Hardcover.io integration
│   ├── bookshelf_start_menu_*.lua # Start menu model, editor, modules
│   ├── bookshelf_menu_host.lua    # Menu host for start menu items
│   ├── bookshelf_module_*.lua     # Micro-module picker, breaker, kit
│   └── ... (fonts, color, selection, sort, etc.)
├── micromodules/          # Drop-in micro-module plugins (v3.x)
│   ├── clock.lua, analogue_clock.lua, weather.lua
│   ├── reading_stats.lua, reading_goal.lua, reading_streak.lua
│   ├── quote_of_day.lua, random_unread.lua, trivia.lua
│   ├── on_this_day.lua, countdown.lua, daily_fun.lua
│   ├── shelf_size.lua, action.lua
│   └── README.md          # Module authoring guide
├── fonts/                 # Bundled open-license fonts
├── locale/                # Translations (.po/.pot for 9 languages)
├── assets/                # Logo images
├── tests/                 # 45 test suites + runner (run.sh)
├── tools/                 # gen_pinyin_table.py
└── AGENTS.md              # This file
```

## Testing

```bash
cd tests && bash run.sh
```

- 45 test suites covering (as of v3.8.4.1): author names, book repository, fonts, language, selection, chip editor, color, cover progress, DPAD cursor, hardcover, hardcover match, hero defaults, hero regions, pinyin, settings store, sort engine, stale sweep, tab model, text segments, tokens, start menu model, start menu modules, plugin scan, icon library, menu host, module breaker, module contract, module kit, fullscreen modules, hero modules, footer geometry, action exec, meta, micromodule store, text safe, dialog focus
- `_test_tall_screen.lua` is **skipped** — needs on-device widget measurements
- All tests must pass before pushing

## Version numbering

- Upstream uses `MAJOR.MINOR.PATCH` (e.g. `3.5.3`)
- Fork appends `.N` revision: `3.5.3.1`, `3.5.3.2`, etc.
- Each fork revision = one upstream sync + fixes re-verified
- Reset the `.N` counter when upstream bumps any part of their version (e.g. `3.5.4` → `3.5.4.1`)

## Important: release ZIPs

The in-app updater checks `GET /repos/:owner/:repo/releases/latest` for `assets` with a `.zip` extension. No asset = "no downloadable zip" error on device.

The ZIP is built with `git archive` which respects `.gitattributes` export-ignore rules:
- `tests/`, `tools/`, `docs/` are excluded
- `*.pot` files excluded
- `.gitattributes`, `.gitignore` excluded
- Result is ~2 MB

Always verify the asset is uploaded after creating a release:
```bash
gh release view vX.Y.Z.N --repo lolwierd/bookshelf.koplugin --json assets
```

## Upstream behaviour notes

- Upstream releases **very frequently** (multiple times per week during active development)
- Major features come in bursts: v3.0.0 (start menu), v3.4.x (full-screen micro-modules), v3.5.x (reader launcher, countdown, gesture actions)
- Upstream has NOT adopted any of our fixes and shows no sign of doing so
- Upstream's `onBookMetadataChanged` fix (type-check) is strictly better than our old `tostring()` workaround — always prefer theirs
- Upstream added `name = "bookshelf"` back to `_meta.lua` in v3.5.1 — this is load-bearing for disabled-plugin re-enable on stable KOReader releases. Never remove it.

## File-specific notes

### `main.lua`
- Each `Bookshelf` instance is a `WidgetContainer` registered both in FileManager and Reader contexts
- `is_doc_only = false` is required so `onCloseDocument` fires inside the Reader
- `_live_widget` tracks the singleton `BookshelfWidget` across instances
- `_safeShow` is the primary close-book→home path; `onCloseDocument` handles other exit paths
- `_installScreensaverHostFallback()` is called in `init()` — it wraps `Screensaver.setup` once globally
- `_suppressPathChangedFor(10)` is called in both `_safeShow` and `onCloseDocument`

### `lib/bookshelf_widget.lua`
- Largest file (~11k lines). Contains the main UI widget.
- `handleEvent` is the gesture dispatch hub — our multiswipe + suspend checks live here
- `onRequestSuspend` and `onSuspend`/`onResume` coexist — the former is called directly from `handleEvent`, the latter via KOReader's broadcast event system
- `onSuspend` → stops timers, flushes nav state. `onResume` → restarts timers, re-paints status

### `lib/bookshelf_updater.lua`
- `REPO_SLUG` must always be `"lolwierd/bookshelf.koplugin"`
- All URLs built via `githubApi()` and `githubWeb()` helpers
- `checkBackground()` uses `/releases/latest` (lightweight)
- `check()` uses `/releases` (full list for release notes)
- `installLatestStable()` downloads the ZIP asset and installs it

## Common issues

| Symptom | Cause | Fix |
|---|---|---|
| "Bookshelf is up to date" but it shouldn't be | No new GitHub release, or no ZIP asset | Create release + upload `git archive` ZIP |
| "No downloadable zip" | Release exists but no `.zip` asset | Upload the `bookshelf.koplugin.zip` asset |
| White screen on suspend from Bookshelf | Missing screensaver host fallback | Verify `_installScreensaverHostFallback` in `init()` |
| Chip jumps to wrong folder after closing book | PathChanged suppression not working | Verify `_suppressPathChangedFor(10)` calls in `_safeShow` and `onCloseDocument` |
| Multiswipe sleep doesn't work on Bookshelf | Fork fix missing | Verify multiswipe check in `handleEvent` (line ~486) |
| Crash opening bookmarks from in-reader | `FileManager.instance` nil | Fixed in quote_of_day.lua and bookshelf_widget.lua |
