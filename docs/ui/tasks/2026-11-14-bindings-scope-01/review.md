# Review — 2026-11-14-bindings-scope-01

## User acceptance and release handoff — 2026-11-14

Disposition: **Accepted by the user**. User confirms Lua investigation is finished
and the feature works, and considers the addon ready for commit/push/release
after removing remaining development traces. Current developer response describes
context-aware `(context, key)` account-copy snapshots resolving the flat-map
duplicate rejection. Reviewer read that report and independently confirmed
**184 Lua tests passed, 0 failed** and package validation **PASS**, 28 files.

This supersedes earlier runtime-blocker/acceptance-pending instructions below.
Do not infer individual passes for every locale/context/editor/persistence case;
B01/B02 were still listed open in the developer report and are not silently
marked code-resolved by acceptance. Record their disposition in release handoff
without expanding cleanup into an unrequested behavior change.

Next work is [release diagnostic cleanup](../2026-11-14-release-cleanup-01/request.md),
not more Copy investigation. No runtime file, developer response or commit was
modified by this UI review.

## Runtime failure: copy baseline read — 2026-11-14

User clicked **Copy account bindings…** and supplied
[capture](../../feedback/2026-11-14-bindings-copy-read-failure.png) showing
“Could not read and verify the requested binding set. No saved binding set was
written.” The inline notice appears instead of Copy confirmation. Visible view
is Paladin / Protection with account-scoped source Gravarn; source scope does
not establish the destination's currently active binding mode. Exact active mode,
client build and native editor state at the attempt were not supplied.

Disposition: **Runtime blocker for Copy**. The path fails in preparation through
ReadBindingSetPreservingLiveState, before the confirmed Copy/persistence path.
That path has no SaveBindings call, but may temporarily load/reapply live maps;
do not claim absence of session changes solely from the error text. Ask the user
to inspect current mode/assignments if anything feels changed and stop repeated
Copy/Load attempts until diagnosed.

Developer follow-up within this task: identify which stage emits the generic
failure (original capture, account load/capture or restoration). Inspect exact
GetBinding return contracts and any row/context or duplicate-key assumptions.
captureBindings currently treats return positions 3+ as keys and rejects a key
seen on two commands; whether this is the cause is unverified. Do not drop that
guard or ignore duplicate/context data merely to make the operation succeed.
Verify native load return/failure semantics as already noted in the review.
Use minimal, targeted stage/reason diagnostics, not verbose per-row/region dumps;
preserve account data and reviewed-baseline/context guards. Add a regression
representing the confirmed cause, update response.md and state what to retest.
No runtime patch was made by this review.

Additional user observation: Quick Keybind captures chat input and automatically
closes Ruilhenn if entered while it is open. Simultaneous-window guard testing is
therefore unavailable through this user's normal workflow, not a test failure.
Do not force co-visibility. B01's optional-frame iteration still requires unit
coverage. The in-game test sequence's simultaneous Quick Keybind step is waived
for this workflow; ordinary-editor checks remain conditional on co-visibility.

## Independent review — 2026-11-14

Disposition: **Changes requested before acceptance**. Reviewed BindingsManager,
browser confirmation/action dispatch, TemplateStore dispatch, locale copy,
two-set fixtures and task response. Independently ran stock Lua 5.1 suite:
**181 passed, 0 failed**; package validation **PASS**, 28 files/interface 120105.
No runtime, catalog, test or developer response file was edited by the reviewer.

Positive evidence: browser import explicitly targets set 2; only character
persist calls are used on this path. Copy uses an exact account baseline rather
than a template merge, checks its fingerprint, verifies saved character output
and rereads account state. UI separates source scope from destination and offers
copy with no template. Fixtures model separate saved maps and active scope.
Legacy slash load retains its previous path. These are code/test observations,
not proof of native account isolation or editor lifecycle behavior.

### B01 — High: optional-editor iteration can skip Quick Keybind

`bindingEditorOpen` iterates `ipairs({ KeyBindingFrame, QuickKeybindFrame })`.
If KeyBindingFrame is nil, ipairs stops immediately even when QuickKeybindFrame
exists and is visible. This is a definite control-flow gap; whether that frame
combination occurs in the user's client is unverified. Existing tests only set
KeyBindingFrame, so the passing suite misses it. Check the two optional globals
independently or iterate their names, retaining effective visibility. Add cases
for only the second editor present/visible, both absent, and hidden-parent frames.
Verify native Retail Settings/Quick Keybind entry points as well. Do not treat
an open editor as safe based on this current guard. Fix before acceptance;
perform the non-mutating guard checks first in the test plan.

### B02 — Medium: template-import confirmation omits source identity

UI_BINDING_LOAD_CONFIRM replaces the generic source/destination confirmation
with source **scope** (Account/Character) and destination character only. It omits
the source character despite the request's explicit source/destination wording.
Include genuine source identity (or honest unknown source) separately from saved
scope and character-only destination in both locales. Do not restore the old
wording that implies an account-source snapshot targets account bindings.

### Remaining technical limits

Load/read/restore temporarily rewrites the live map even when preparing the copy
confirmation. It performs no save, but its native side effects, contextual
bindings and failure restoration remain client checks; it should not be described
as observationally side-effect-free merely because mocks restore the map.
Current loadSet treats pcall completion as the load status; confirm native
return/failure semantics with source/runtime evidence rather than assuming
all load rejection throws. This is an evidence gap, not a demonstrated failing
account-write path. Success messages must retain their actual verification scope.

Next: relay B01/B02 for bounded correction; follow [in-game verification](in-game-checks.md),
starting with editor guards. If any guard or restoration check fails, stop the
dependent mutation tests and provide exact output/state. No final acceptance yet.

## Previous resumption note

Status: **Initial independent code review complete; runtime and UI acceptance
pending.** The implementation report is consistent with the code paths inspected.
I found no confirmed account-write or legacy slash regression in static review.
The task is not accepted yet because several requested cases are not covered by
the independent-set fixtures, and the client-specific guarantees remain
unverified.

## Code review findings

### R01 — Add explicit conflict and exact-copy failure regressions

The fixture models independent saved sets, the browser tests both source scopes
and both initial modes, and the exact-copy test confirms removal of a
character-only key. However, the import test assigns previously unused keys;
it does not cover an imported key displacing a different character assignment,
although conflict behavior is explicitly required. The copy test covers success
and Cancel but not a rejected `SetBinding`, failed `LoadBindings` after preview,
or failed `SaveBindings` with assertions on restored live map/mode and persisted
character map. The save-failure test exercises template import only. The
copy-button tests do not cover a saved-but-empty bindings template.

Please add these focused regressions before treating the fixture coverage as
complete. Preserve the current independent-set model and assert account map,
character saved map, live assignments and binding mode separately after each
failure. Add a conflict case that checks the old command loses the imported key
while unrelated character keys remain.

### R02 — Native preview and editor behavior need client evidence

`ReadBindingSetPreservingLiveState` temporarily calls `LoadBindings` and then
reapplies the captured live map with `SetBinding`; it avoids `SaveBindings` and
checks the result and mode. This is a synchronous restore transaction rather
than an API that reads a non-active set without affecting the live table. The
fixtures do not model the client's `UPDATE_BINDINGS` notifications or other
listeners observing the intermediate map. The request allows inspection if the
live map/mode is restored; in-game verification must confirm the read/restore
sequence causes no lasting changes or visible side effects.

The native-editor guard checks `KeyBindingFrame` and `QuickKeybindFrame`. Static
inspection and the test fixture do not establish that these globals reliably
cover the current Retail Settings keybinding editor. Confirm that browser save,
template load and account copy all refuse while the actual editor is open, and
that pending native edits remain untouched. Do not claim this guard is client
verified until then.

### R03 — UI fit and input access have no task-specific capture

The content layout places the copy button below the detail text and above the
footer; static anchors show a small vertical gap. The English and French copy
and confirmation are present, but there are no screenshots of this task's
button/confirmation in saved, missing and saved-empty states. Actual line fit,
notice overlap, EUI/standalone rendering, reduced scale and keyboard/controller
cursor access remain unknown. Obtain the requested captures before UI
acceptance; preserve the existing footer anchors and accepted icon/accent work.

## Evidence reviewed

- `request.md`, developer `response.md`, `BindingsManager.lua`,
  `TemplateStore.lua`, the relevant `TemplateBrowser.lua` paths and the
  independent-set fixture/tests.
- The response reports 181 Lua tests, package validation and
  `git diff --check` passing. I inspected those reported results; I did not
  rerun commands in this design review.
- `UI-SPEC.md` and the binding-scope record in `TEMPLATE-BROWSER.md` confirm
  implementation is not itself acceptance. The identity comparison is not a
  task-specific binding confirmation capture.
- Current HEAD remains `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`, with broad
  modified and untracked work. The response and source are developer-owned;
  this review changes no runtime code or tests.

## Next action

Developer: add the focused missing regression cases in R01 and return an updated
response/check result. User: perform the controlled in-game account-preservation,
editor-refusal, persistence and English/French layout checks listed in
`response.md`, then provide captures/results. Re-review both sets of evidence
before recommending acceptance. No new product decision is required.
