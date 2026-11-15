# Release diagnostic cleanup

Task ID: `2026-11-14-release-cleanup-01`.
Status: **Ready for implementation**.
Authorization: user confirms the binding investigation/fix works, considers the
addon ready for commit/push/release, and requests removal of remaining potential
development-specific traces. This request covers cleanup/preparation only;
the UI session does not perform runtime edits or publication.

## Outcome and source

Remove investigation-specific and noisy development instrumentation without
changing accepted functionality or useful failure reporting. Current source is
the broad uncommitted worktree based on `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`;
browser/store/docs are untracked and many other runtime/test files modified.
Inspect status and preserve unrelated work. Follow AGENTS.md and Lua role guide.

User acceptance supersedes earlier Copy failure/testing-pending dispositions;
it does not claim individual unreported scenario passes. Context-aware account
copy and prior UI changes must remain intact. Do not reopen deferred icon/hero
work or alter legacy slash binding scope as part of cleanup.

## Audited candidates

- TemplateBrowser.lua: temporary `Copy account bindings preflight failed at …`
  debug line. Remove its tracing-only plumbing/tests if genuinely unused, but
  retain failure information required by guards, correct branching and user errors.
- ActionBarsManager.lua: per-action `GetMacroInfoFromAction` DumpTable logging and
  commented-out investigative debug blocks.
- Main.lua: command-table dump and per-command registration chatter.
- EventManager.lua: per-event firing and per-callback execution/registration
  chatter. Remove development-volume tracing, retaining actual error handling.
- Review remaining runtime debug calls, notably TalentManager operation-entry/
  class-spec/database-presence checkpoints, for obsolete investigation remnants.
  Keep concise actionable rejection/cleanup reasons where still useful. Record
  the cleanup classification rather than deleting every Debug call blindly.

`Log.lua` prints implement ordinary message/error/warning/debug output; keep them.
Preserve `/ruil debug`, `/ruil validate`, talent status and click-casting status,
including their functional readback/diagnostic data. A variable containing the
word “diagnostic” is not automatically development instrumentation. No new trace
level, preference, logging framework or diagnostic UI is needed.

## Boundaries and acceptance

No changes to restore semantics, context-aware binding snapshots, class/spec/
combat/editor guards, source backups, confirmation text, appearance or data schema.
Retain ordinary error/warning/success messages. Do not suppress failures to make
normal play quieter. Debug-off output and debug-on output should avoid repeated
registration/event/table/texture dumps. No new permanent instrumentation.

Update response.md here with removed/retained categories and actual checks.
Do not edit request.md, review.md, prior developer response files, accepted UI
references or RETAIL-API-REVIEW.md. Keep developer-only docs/tests/feedback/tools
excluded from releases. Resolve scope of any remaining review findings in the
report, but do not silently implement unrelated behavior changes.

## Verification and release handoff

Run stock Lua 5.1 tests/run.lua, python tools/package_release.py --check and
git diff --check. Preserve meaningful functional regression tests; remove/adapt
only tests dedicated to deleted tracing. Build/verify the local release ZIP with
python tools/package_release.py and inspect its runtime-only file list.
Report the current TOC version and whether the intended release version still
needs assignment; do not invent a version/tag or publish a release in this task.

If actual-client tools are unavailable, ask the user for a short smoke check:
open/refresh/navigate with debug off/on, confirm no investigative chatter, and
confirm the previously working Copy action is unaffected on the user's test setup.
Do not claim this check from mocks. Report checks NOT RUN as appropriate.

No commit/push/tag/publication is performed as part of this cleanup request.
User's release-readiness decision is recorded; concrete Git/release operations
are a subsequent handoff after cleanup and artifact verification, preserving
the project instruction to exclude the user-owned API review from unrelated commits.
