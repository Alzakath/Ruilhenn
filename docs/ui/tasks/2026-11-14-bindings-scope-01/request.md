# Character-specific binding imports and account baseline copy

Task ID: `2026-11-14-bindings-scope-01`

Status: **Ready for implementation**.

Authorization: user agreed browser imports should default to character-specific
bindings, accepted a one-time account-to-character reset copy, and requested
updated Lua instructions. The user relays this request; it does not start an agent.

## Problem and intended outcome

Current browser imports save to the source snapshot's account/character binding
set. A class/spec template can therefore affect account-wide bindings. Import
through the browser must instead target only the destination character's own
set, leaving account bindings untouched. Provide a separate confirmed action
that replaces the character set with a copy of the current account baseline.

Authority: [binding scope decisions](../../../TEMPLATE-BROWSER.md#key-binding-scope-question--2026-11-14),
[UI-SPEC.md](../../../UI-SPEC.md), AGENTS.md and current player/feature documents.
Read the installed WoW skills and verify actual Retail binding APIs and state
semantics before implementation. Preserve existing manager ownership.

## Source and inspected implementation

HEAD: `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`. Browser/store are untracked;
managers, catalogs, tests, packaging and docs have extensive unrelated local work.
Use the live checkout, not HEAD alone. BindingsManager:Save records the active
set; scoped snapshots retain it. Load(profile) currently applies SetBinding for
saved keys, then SaveBindings(profile.bindingSet or current). Browser metadata
and confirmation currently describe that saved set as the destination.

Keep source scope in persisted snapshots as historical metadata; do not rewrite
it merely to redirect an operation. Separate source provenance from execution
target. This task supersedes the old browser behavior only. Legacy slash
`/ruil bindings load` retains its existing scope semantics in this task.

## Browser import behavior

- Browser Load always applies to **Character** in this pass, irrespective of
  source saved scope. No account-wide destination option or new preference.
- Leave the destination in character-specific binding mode after a successful
  import, including when it started in account mode. Never save the account set.
- Preserve existing per-key application semantics: apply captured assignments,
  do not turn template Load into clear-all replacement. Existing conflicts may
  be displaced; explain that effect. The copy-account action below is different.
- Retain exact class/spec compatibility, explicit confirmation, combat and stale
  snapshot guards. Browsing remains read-only; selecting/refreshing does not load
  account data or change live binding mode.
- Keep both key assignments, scoped/global backups and category provenance
  intact. No automatic source save, backup mutation or SavedVariables migration.
- Route through BindingsManager, with an explicit destination argument or
  bounded browser method as appropriate. Do not duplicate restore logic in UI.

## Copy account bindings action

Add a secondary **Copy account bindings…** / **Copier les raccourcis du compte…**
button in the Key bindings content guidance area, above the footer. Keep footer
Save/Refresh/Load anchors and navigation intact. This is a current-character
utility, not a selected-template operation. Keep it visible in saved, missing
and saved-empty Key bindings views; enable only for compatible active class/spec,
out of combat and valid operation context. Explain disabled reasons. It needs
no saved binding template. Do not add it to Overview or other categories.

After confirmation:

- Read the **actual account binding set**, not factory defaults, a template or
  whichever set happens to be active. Replace the character-specific set with an
  exact copy, including removal of prior character-only assignments.
- Save only the character set and leave character-specific mode active. Future
  account edits are not linked to this copy, and future character edits remain
  isolated. Account bindings and Ruilhenn source backups remain unchanged.
- Capture/revalidate current destination/context and the reviewed account baseline
  at execution. If it changed while confirmation was open, request fresh review;
  do not silently apply a different baseline. Capturing preview must not leave
  the player's live bindings/mode changed.

Verify native API behavior for inspecting/copying the non-active set and saving
the destination. Do not implement this by guessing that a final SaveBindings(2)
alone isolates all prior state changes. Respect the native binding editor's
pending edits: refuse while its editor is open, explain that it must be closed,
and do not commit/discard its draft on the user's behalf. Recheck before mutation.
If reliable read-only inspection of the baseline or preservation of current
state cannot be established, report the technical blocker before changing scope.

No persistent automatic undo/history feature is requested. On errors, report
partial/session changes honestly; do not claim success from pcall alone. Verify
final target mode/assignments and account preservation using supported reads;
avoid silently persisting a known partial result. Tests must cover failure paths.

## Copy and confirmation

Separate visible **Import destination: This character only** from optional
**Saved from: Account/Character bindings** provenance. Old “Target binding set”
text must not imply that source scope determines the destination anymore.

Template-load confirmation names source and destination, says it applies saved
keys to this character's own set, may replace assignments on imported keys,
preserves account bindings and leaves character-specific mode active.

Copy confirmation names the current destination and clearly states: replace all
its character-specific bindings with a one-time copy of account bindings; remove
character-only customizations; keep account bindings unchanged; subsequent edits
stay character-specific. Cancel performs no mutation. Use ordinary text, not
red failure styling for the action itself. Give both controls readable English/
French copy and retain non-color cues. Localize all new guidance/errors/results.

## Scope, references and exclusions

Expected: BindingsManager.lua, TemplateStore.lua dispatch/presentation,
TemplateBrowser.lua control/confirmation, English/French catalogs, meaningful
tests/fixtures, Readme and feature evidence, developer-owned response.md here.
Use existing browser screenshot geometry from
[identity comparison](../../feedback/2026-11-14-identity-01/observations.md).
No new mockup is necessary for this bounded secondary action; fit must be reviewed
in real captures. Do not redesign the binding list or icons as part of this task.

Preserve accepted colors/icons, Refresh preview, hierarchy, scrollbar fix and
removed diagnostics. No talent/bar/click restore changes, automatic spec loading,
whole-character profiles, new setting or account-write path. Do not change EUI,
request.md, review.md, design references or RETAIL-API-REVIEW.md. Preserve unrelated
work. Do not commit, push, spawn another agent or automate session communication.

## Observable acceptance criteria

1. Browser import of either account- or character-source template ends in
   character mode with imported keys applied; account assignments remain identical.
   Test starting in either account or character mode. Source snapshots are intact.
2. Copy-account produces an exact character-set copy of the account baseline,
   removes character-only keys, preserves account data and keeps character mode.
   It is available without a template and does not affect unrelated categories.
3. Preview, navigation and Cancel do not change assignments or mode. Combat,
   incompatible spec, editor-open, stale context/baseline and native API failures
   are guarded with truthful feedback and no false success.
4. Source scope and destination scope are distinct on screen and in confirmations.
   Both actions clearly explain their differing merge/replacement effects.
5. Existing two-key capture, scoped provenance, legacy backups and slash behavior
   remain compatible; other category managers and skin behavior are preserved.
6. English/French labels/guidance fit in saved/missing/empty states and at smaller
   scales; all actions remain reachable by mouse/keyboard/controller cursor with
   no new input capture/bindings. No overlap with export/footer or state notices.

## Validation and report

Run stock Lua 5.1 `tests/run.lua` and `python tools/package_release.py --check`.
Use meaningful fixtures modeling **two independent binding sets and active mode**,
not one shared map that could hide account overwrites. Cover all source/destination
scope combinations, exact copy versus template merge, conflicts, second keys,
guards, cancellation/staleness, failure/verification paths and legacy slash scope.
Document verified API semantics and limits with target/source evidence.

In-game checks on a controlled backed-up setup: inspect account bindings before
and after, verify character mode and imported/copy results, character-only key
removal for copy, reload persistence and native-editor refusal. Capture normal
and confirmation views in English/French, saved and missing template states,
with skin/UI-scale context. Do not run account-wide mutations merely to test.
Mark absent client evidence NOT RUN; mocks do not prove account isolation.

No product question blocks this bounded character-only scope. Optional account
import, undo history and icon refinements remain outside it. Native baseline
inspection/editor/mode preservation are technical dependencies, not license to
silently choose a different reset meaning. Report blockers/questions in response.md.
Include changed files, API evidence, checks and remaining user tests; update the
feature record's implementation evidence without rewriting accepted requirements.
