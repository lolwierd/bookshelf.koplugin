# Upstream Sync & Release Playbook

> **For the next agent (or me):** This is the step-by-step runbook for pulling
> new changes/releases from upstream into this fork and cutting a fork release.
> It is self-contained — you can do the whole job from this file alone.
> `AGENTS.md` has deeper per-file context if you need it; this file is the
> procedure and the gotchas.

**Fork:** `lolwierd/bookshelf.koplugin` · **Upstream:** `AndyHazz/bookshelf.koplugin`
**Default branch:** `master` · **Remotes:** `origin` → fork, `upstream` → AndyHazz

---

## TL;DR (the happy path)

```bash
git remote add upstream https://github.com/AndyHazz/bookshelf.koplugin  # once
git fetch upstream --tags
git log --oneline master..upstream/master        # what's new
git checkout master && git merge upstream/master # resolve conflicts (see §3)
# ... resolve, verify fork fixes (§4), run tests (§5) ...
# bump _meta.lua version to <upstreamversion>.1 and add a CHANGELOG.md entry (§6)
git commit && git push origin master             # (§7)
# release: trigger the Release action or push a v<version> tag (§8)
```

The two things that make a release usable on-device:
1. A GitHub **release** marked *latest* (not draft/prerelease).
2. A **`bookshelf.koplugin.zip` asset** attached to it — the in-app updater
   downloads that from `/releases/latest`. No zip = "no downloadable zip" on device.

Both are produced automatically by `.github/workflows/release.yml` (§8).

---

## 0. Why this fork exists

A handful of Kobo-specific / opinionated fixes that upstream has not adopted and
probably never will. They are re-applied on top of every upstream release. See
the full table in `AGENTS.md`; the short list you must protect during a merge:

| Fix | Where | One-line check |
|---|---|---|
| Screensaver host fallback | `main.lua` `_installScreensaverHostFallback` | `grep -c _installScreensaverHostFallback main.lua` ≥ 2 |
| `onRequestSuspend` handler | `lib/bookshelf_widget.lua` | `grep -c onRequestSuspend lib/bookshelf_widget.lua` ≥ 2 |
| Multiswipe sleep gesture | `lib/bookshelf_widget.lua` `handleEvent` | `grep -c multiswipe lib/bookshelf_widget.lua` ≥ 2 |
| Updater → fork URLs | `lib/bookshelf_updater.lua` | `grep -c lolwierd lib/bookshelf_updater.lua` ≥ 1 |
| `quote_of_day` FileManager nil-guard | `micromodules/quote_of_day.lua` | `grep -c FileManager micromodules/quote_of_day.lua` ≥ 2 |

Some earlier fork fixes were **retired** because upstream solved the same problem
better — do **not** reintroduce them (see §3.2).

---

## 1. Prep

```bash
# Add upstream if it isn't already a remote
git remote -v | grep -q upstream || \
  git remote add upstream https://github.com/AndyHazz/bookshelf.koplugin

git fetch upstream --tags
git fetch origin
```

If you're an agent on a designated feature branch (e.g. `claude/...`), do the
merge work there, then land on `master` at the end (see §7 for the branch-vs-
master rule in restricted sessions).

---

## 2. Assess what's new

```bash
git log --oneline master..upstream/master | head -60   # commits
git tag --sort=version:refname | tail -15               # new release tags
grep version _meta.lua                                  # our current base
```

Read upstream's release notes for the tags you're crossing — you'll summarise
them in the CHANGELOG (§6). Upstream releases **frequently** (multiple/week) and
features land in bursts, so a sync can span many minor versions.

---

## 3. Merge and resolve conflicts

```bash
git merge upstream/master
```

### 3.1 The resolution philosophy (this is the important part)

> **When upstream has independently solved a problem this fork also patched,
> prefer the *better* solution — usually upstream's — and delete the fork's
> version. But make sure the *problem* stays solved.** The user cares that the
> bug is fixed, not that their exact code survives. If the fork's version is
> genuinely better, keep it. When in doubt, read both, then decide with a reason.

Concretely, for each conflict:
1. Identify *what problem* each side is solving.
2. If they solve the **same** problem, keep the better one; verify the behaviour
   the fork wanted is still delivered by the version you keep.
3. If they're **orthogonal**, keep both.
4. Never blindly `--ours` or `--theirs` a whole file — read the hunks.

### 3.2 Known conflict hotspots (seen historically)

| File / area | What to do |
|---|---|
| `_meta.lua` `version` | Take upstream's version, then bump to `<upstream>.1` (§6). Keep `name = "bookshelf"` — it's load-bearing for disabled-plugin re-enable; never remove it. |
| `main.lua` `onBookMetadataChanged` | Prefer upstream's `type(prop_updated) == "string"` check over any `tostring(...)` workaround. |
| `main.lua` `onPathChanged` / reader-return | **Upstream's `_restoring_from_reader` flag (#204) supersedes the old fork `_suppressPathChangedFor` timer.** Keep upstream's; the timer is retired. `grep -c _restoring_from_reader main.lua` ≥ 4, and `grep -c _suppressPathChangedFor main.lua` = 0. |
| `lib/bookshelf_widget.lua` `handleEvent` FM touch-zone walk (#79) | **Upstream's shared `GestureZones.tryFMZones` supersedes the fork's inline walk** — behaviourally identical. Take upstream's call; drop the inline version. Keep the multiswipe/onRequestSuspend block *above* it (that's still fork-only). |
| `lib/bookshelf_widget.lua` book long-press menu | Upstream removed `_openBookMenu` (ButtonDialog) in favour of the tabbed `_showBookDetail`. If the conflict shows the fork keeping `_openBookMenu`, **delete it** — `on_book_hold` already routes to `_showBookDetail`, and that flow already nil-guards its `FileManager.instance` touches, so the fork's old book-detail nil-guard is no longer needed there. |
| Comments near `_wireFastFileBrowserTab` / `_setupReaderButtons` | Watch for orphaned merge-artifact comment fragments; both sides' canonical comment is fine, just don't leave a doubled/dangling block. |

After resolving, make sure no markers remain:
```bash
grep -rn '^<<<<<<<\|^=======$\|^>>>>>>>' --include=*.lua . || echo "clean"
```

---

## 4. Verify the fork fixes survived

Run the checks from §0. All must pass. Then confirm the retired fixes are gone
and upstream's replacements are present:

```bash
grep -c _restoring_from_reader main.lua   # ≥ 4 (upstream's PathChanged fix)
grep -c _suppressPathChangedFor main.lua  # 0  (retired fork timer)
grep -c 'tostring(prop_updated)' main.lua # 0  (use upstream's type() check)
grep -c AndyHazz lib/bookshelf_updater.lua # 0  (updater must point at the fork)
grep -c 'name = "bookshelf"' _meta.lua     # ≥ 1
```

---

## 5. Test

CI (`.github/workflows/ci.yml`) runs the real check on every push under
`lua5.4` + `luajit` + `msgfmt` — **that is the authoritative gate.** Locally:

```bash
# Install an interpreter if none (the container often has none):
which lua lua5.1 luajit || sudo apt-get install -y lua5.1
# Syntax-check the files you touched:
for f in main.lua lib/bookshelf_widget.lua _meta.lua; do lua -e "assert(loadfile('$f'))" && echo "ok $f"; done
# Full suite:
sh tests/run.sh
```

**Gotcha — environmental test failures:** On a C/POSIX-locale box with byte-based
Lua 5.1, a handful of UTF-8 suites (`_test_book_repository` rating glyph,
`_test_plugin_scan` PUA, `_test_text_safe`, `_test_tokens` numeric entities)
**fail on a clean upstream checkout too** — they are *not* regressions. Confirm
by running the same suites against `upstream/master` and checking the failing set
is identical. Trust CI over the local box for these.

---

## 6. Version bump + CHANGELOG

**Version numbering:** upstream `MAJOR.MINOR.PATCH` + fork `.N` revision.
e.g. upstream `v3.8.4` → fork `3.8.4.1`. Reset `.N` to `1` whenever *any* part of
the upstream base changes; increment `.N` for fork-only follow-up builds on the
same base.

1. Edit `_meta.lua`: `version = "<upstream>.<N>"`.
2. Add a section to `CHANGELOG.md`. **The release workflow extracts the section
   whose header exactly matches the version and uses it as the release body**, so
   the header format is load-bearing:
   ```markdown
   ## [3.8.4.1] - 2026-07-05
   ### Upstream changes pulled in
   - ...
   ### Fork fixes retained
   - ...
   ### Fork fixes superseded by upstream's (better) solution
   - ...
   ```
   The `_meta.lua` version and the CHANGELOG header must match — the workflow
   **hard-fails** if `_meta.lua`'s version has no matching release version.

---

## 7. Commit & push

```bash
git add -A && git commit -m "Merge upstream vX.Y.Z into fork; retain local fixes"   # + version/CHANGELOG
git push origin master
```

**Restricted-session note (Claude Code web/remote):** In these sessions the git
proxy allows **branch** pushes but **blocks tag pushes and release creation**
(HTTP 403 — "not permitted for this session type"). That's a platform limit, not
an auth problem, and retrying won't help. So:
- Push `master` normally (works).
- Do **not** try to `git push origin <tag>` or `POST /releases` from such a
  session — it will 403. Use the Actions release path in §8 instead (the runner
  has `contents: write` and is *not* subject to the session proxy).
- If you're on a designated feature branch, only push `master` after explicit
  user OK; a `--ff-only` merge from the feature branch is the clean way.

---

## 8. Release (the reliable way: GitHub Actions)

`.github/workflows/release.yml` does everything: verifies `_meta.lua` ↔ version,
builds the zip via `git archive` (respecting `.gitattributes` export-ignore),
extracts the CHANGELOG section, and publishes the release with the zip attached
(`softprops/action-gh-release`). It runs on the runner's token, so it works even
from a restricted session.

**Fire it one of two ways** (both need the code already on `master`, §7):

- **Trigger the workflow** (works from a restricted agent session via the GitHub
  Actions MCP `run_workflow`, or the Actions tab → "Release" → Run workflow):
  input `version` = `3.8.4.1` (leading `v` optional), ref = `master`.
- **Or push a tag** from an unrestricted/local session: `git tag v3.8.4.1 &&
  git push origin v3.8.4.1` — the `push: tags: v*` trigger cuts the release.

The workflow creates the `v<version>` tag itself when triggered by dispatch, so
you do **not** need to pre-create the tag.

### Verify the release landed
```bash
# via API (read-only, always allowed):
#   GET /repos/lolwierd/bookshelf.koplugin/releases/latest
# check: tag_name == v<version>, draft == false, and
#        assets[] contains bookshelf.koplugin.zip with state "uploaded".
```
Also confirm the CI run that fires on the new tag push is green (harmless second
check).

### Manual fallback (only from an unrestricted `gh`/local session)
```bash
git archive --format=zip --prefix=bookshelf.koplugin/ --output=bookshelf.koplugin.zip HEAD
gh release create v3.8.4.1 --repo lolwierd/bookshelf.koplugin \
  --title "v3.8.4.1 — Fork build" --notes-file <(sed -n '/## \[3.8.4.1\]/,/## \[/p' CHANGELOG.md)
gh release upload v3.8.4.1 bookshelf.koplugin.zip --clobber
```

---

## 9. What the release zip must / must not contain

Built by `git archive`, so `.gitattributes` `export-ignore` decides. Excluded:
`tests/`, `tools/`, `docs/`, `.github/`, `*.pot`, `.gitattributes`, `.gitignore`,
`AGENTS.md`, `CHANGELOG.md`. Result ≈ 2.2 MB of runtime files only (Lua, `locale/*.po`,
`assets/`, `fonts/`). If you add a new dev-only file, add it to `.gitattributes`.

---

## Quick reference — post-merge checklist

- [ ] No conflict markers anywhere (`grep -rn '^<<<<<<<' --include=*.lua .`)
- [ ] All 5 fork fixes present (§0 checks)
- [ ] Retired fixes gone, upstream replacements present (§4 checks)
- [ ] `name = "bookshelf"` still in `_meta.lua`
- [ ] `_meta.lua` version bumped to `<upstream>.<N>`
- [ ] `CHANGELOG.md` has a `## [<version>] - <date>` section
- [ ] Local syntax check + `tests/run.sh` (ignoring the known UTF-8/locale failures)
- [ ] `master` pushed; **CI green**
- [ ] Release cut via the workflow; `releases/latest` has the `.zip` asset
