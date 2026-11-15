# Implementation report — 2026-11-14-release-cleanup-01

Status: **Cleanup complete locally; checks and local release artifact pass.**
No commit, push, tag or publication was performed.

## Removed tracing

- Removed command-table dumping, per-command registration lines and addon load
  timing from startup. Removed the timing-only `debugprofilestop` state and its
  English/French string.
- Removed EventManager registration, dispatch and callback-success chatter and
  its unused independent debug-mode state. Callback exceptions still report an
  error.
- Removed the action-bar per-slot macro/table dump and commented investigation
  debug blocks. Macro resolution and missing-macro errors are unchanged.
- Removed TalentManager operation-entry, class/spec, database-presence and
  saved-build-count checkpoints. The actionable import rejection state and
  verified scratch-cleanup message remain available in debug mode.
- Removed per-macro create/update success traces, TaskQueue completion chatter,
  and settings-found/not-found startup messages and their unused English/French
  strings. Existing macro/action/task errors and normal operation messages stay.
- Removed the temporary Copy preflight stage log and stage/reason return values.
  Copy still shows its localized read failure; the manager still preserves
  context-aware snapshot, stale-check, restoration and write-verification
  behavior. Failure-path tests continue to verify the saved sets and live state.

## Retained useful diagnostics and behavior

`Log.lua`, `/ruil debug`, `/ruil validate`, talent status, click-casting status,
command exception reporting, task/callback error reporting, binding failure and
restore messages, talent import rejection context, and scratch cleanup
verification remain. No restore, binding context, UI, data-schema or successful
operation behavior was changed in this cleanup.

Regression tests confirm debug-enabled startup emits only the normal greetings,
event dispatch produces no registration/success chatter while callback errors
remain visible, and Copy preflight errors remain visible in the UI without
temporary debug tracing.

## Checks and local artifact

- `lua tests/run.lua` — **PASS**, 183 tests, 0 failures, stock Lua 5.1.5.
- `python tools/package_release.py --check` — **PASS**, 28 files, interface
  120105, TOC order and filename case valid.
- `git diff --check` — **PASS**; Git printed existing LF-to-CRLF working-copy
  notices only.
- `python tools/package_release.py` — **PASS**, built and verified
  `dist/Ruilhenn-retail-12.1.5.zip` with 28 files.
- Inspected the ZIP member list: it contains the TOC, runtime Lua modules,
  English/French catalogs, class macro files, icon, Readme and changelog.
  `AGENTS.md`, `RETAIL-API-REVIEW.md`, docs, tests, tools, build output and other
  developer-only files are excluded.

The TOC currently declares version **0.4.0**. This task did not assign a new
intended release version; confirm whether 0.4.0 is the release target before
creating a commit/tag or publishing.

## Remaining in-game verification

User reports the requested in-game smoke check **passed**: opening, refreshing
and navigating the browser with debug off and on produced no investigative
chatter, and Copy account bindings remained unaffected on the test setup. This
is user-reported client verification; the Lua mocks and ZIP checks do not
independently verify client rendering or native binding writes.

Implementation is local and uncommitted. Pre-existing unrelated changes in the
shared worktree were preserved.

## Release version selection — 2026-11-15

The user selected **0.5.0**, noting the shared Ruilhenn UI is an important new
feature since the 0.4.0 release. `Ruilhenn.toc` now declares 0.5.0 and the
changelog's accumulated Unreleased changes are headed `v0.5.0`. After the
version update, `lua tests/run.lua` passed (183 tests), package validation
passed (28 files/interface 120105), `git diff --check` passed, and
`python tools/package_release.py` rebuilt and verified the 28-file local ZIP at
that time. The artifact TOC was read back and confirmed as version 0.5.0. Git
operations and publication remain a separate handoff; none were performed.

## GitHub workflow archive audit — 2026-11-15

`.github/workflows/release.yml` triggers on any pushed tag (`**`) and invokes
`BigWigsMods/packager@v2.3.1` with credentials configured for CurseForge,
WoWInterface, Wago and GitHub Releases. The Packager documentation says it
copies checkout files into its release directory and applies `.pkgmeta` ignore
patterns; it does not promise to select only TOC-referenced files. Consequently,
the ignore list is the safeguard against repository and development content.
See the [Packager README](https://github.com/BigWigsMods/packager) and its
[PackageMeta ignore guidance](https://github-wiki-see.page/m/BigWigsMods/packager/wiki/Preparing-the-PackageMeta-File).

The ignore list excludes `docs`, `tests`, `tools`, `.github`, developer
instructions/review, build output, and now root `Readme.md` / `CHANGELOG.md` and
local Codex metadata directories. The local builder was aligned to the same
game-use payload: the TOC, every file referenced by it, and the TOC icon only.
The rebuilt ZIP contains 26 files and no README, changelog, tests, docs, tools,
or development assets. The icon remains because the TOC references it.

Post-audit checks: `lua tests/run.lua` **PASS**, 183 tests;
`python tools/package_release.py --check` **PASS**, 26 files/interface 120105;
`git diff --check` **PASS**; `python tools/package_release.py` **PASS**, ZIP
rebuilt and inspected, 26 files with zero non-runtime entries. The ZIP's TOC
reports version 0.5.0. The GitHub workflow itself was not run because its tag
trigger would publish to configured distribution services; this audit checks
the workflow configuration and package rules without tagging or publishing.

## 0.5.0 workflow refresh — 2026-11-15

Updated `.github/workflows/release.yml` to use `actions/checkout@v7.0.1` and
`BigWigsMods/packager@v2.7.0`, the current releases checked for this handoff.
The workflow still triggers on any pushed tag and publishes through its
configured services. The addon TOC and changelog already identify version
0.5.0. Validation after the workflow update: Lua tests **PASS** (183/183),
local package validation **PASS** (26 runtime files, interface 120105), local
ZIP rebuild and content inspection **PASS** (no docs/tests/tools/release notes),
and `git diff --check` **PASS**. No tag was created as part of this audit.
