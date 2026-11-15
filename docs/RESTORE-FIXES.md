# Cross-character restore runtime follow-up — 2026-11-13

Target: Retail 12.1.5.70783 / interface 120105; source pin
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`.

## Report and diagnosis

The user reported one talent import followed by four rejected explicit
creation requests; bars failed on missing macros, mounts and a racial spell
but still printed "Actionbars loaded". Native click casting restored nine
bindings while skipping one unlearned spell, as intended.

The user subsequently confirmed native manual loadout creation is available:
`C_ClassTalents.CanCreateNewConfig()` returned true and
`#C_ClassTalents.GetConfigIDsBySpecID()` returned 2. This does not support a
full-loadout-list diagnosis. The exact transient client state at the earlier
failures was not captured.

Pinned Blizzard_ClassTalentImportExport.lua calls ImportLoadout using its
current config as the decoding source, then OnTraitConfigCreateStarted.
Blizzard_ClassTalentsFrame.lua waits for TRAIT_CONFIG_CREATED and, when
needed, IsConfigPopulated / TRAIT_CONFIG_UPDATED before finishing creation.
It gates new/import actions with CanCreateNewConfig. Ruilhenn previously
requested an empty config first, then called ImportLoadout from its creation
event and immediately attempted another RequestNewConfig. That diverged
from the native import-creates-loadout lifecycle.

## Changes and acceptance

| ID | Change | Local evidence |
| --- | --- | --- |
| REQ-RF-1 | Let ImportLoadout request missing loadouts directly using active config ID; no preliminary RequestNewConfig | Argument-order and serial lifecycle tests |
| REQ-RF-2 | Wait for matching newly created/populated result; bounded readiness waits; keep existing named loadouts; no automatic retry of accepted imports | Created/updated, readiness, existing-name, timeout, stale/duplicate and cancellation cases |
| REQ-RF-3 | Apply shared-bar setting to the new ID; handle rejected setting without leaving a stuck waiter or reporting full success | Flag ID and restricted-setting tests |
| REQ-RF-4 | Skip absent named macros, unsupported mounts and unlearned spells in bars; preserve their current slots and full backup | Partial restore and backup-preservation test |
| REQ-RF-5 | Report actual placed/skipped/failed totals, counting placement failures | Rejected placement and partial-result tests; English/French key/format parity |

Readiness polling only checks permission before sending an import, every
0.25 seconds for up to approximately 10 seconds. Accepted imports are not
resubmitted. Creation/population waits time out after 15 seconds; a late
server result can still exist, so inspect the native list before retrying.
Cancellation cannot recall an already accepted native request. No automatic
deletion, activation or modification of an existing named loadout is added.

Bar spell availability includes overrides, so a learned overriding spell can
qualify. Missing macros are not recreated or copied automatically. Mounts
remain unsupported and now count as skipped rather than generating a second
placement error. Complete and partial summaries replace unconditional success.
No snapshot migration or new UI preference is introduced.

## Verification / checkpoint

144 stock Lua 5.1 tests pass; the 28-file release check and ZIP build/verification
also pass. Actual-client verification of these manager changes is NOT RUN.
All changes remain local/uncommitted. The pre-existing API review is untouched.

Next: `/reload`, then restore the remaining missing talent builds. Verify
one server-confirmed import at a time, no duplicate preliminary empty loads,
existing names unchanged, and actual exported talents. Check the native list
for leftovers from earlier attempts before deciding whether to remove any
manually. Restore bars and confirm the placed/skipped/failed summary, with
skipped slots preserved. Do not resave the destination over the source backup
merely to test restoration. The UI handoff's visual acceptance remains separate.

## Repeat runtime report

The user reported the new talent flow kept one existing loadout, confirmed
creation of `test dps`, then received generic native import rejections for
three further builds. This is partial improvement, not full talent acceptance.
They suggested the destination's lower level than the level-90 source as a
cause. The decoder preserves the entire saved build; it does not prune ranks
for a lower-level character. Insufficient points/prerequisites are plausible,
but generic native rejection and the one-success-then-fail pattern do not
prove that cause. A standalone native import of a failing build has been
requested to distinguish build availability from batch timing.

The repeated action-bar result was 42 placed, 14 skipped, 0 failed. Skips
identified missing macros, unlearned spells and unsupported mounts. This
confirms the new partial-result reporting in game; the report does not
separately verify every placement or persistence. No source backup was
rewritten or lower-level talent selection invented to address this report.

## Native import and pending Apply Changes follow-up

The user then supplied a level-90 export and Blizzard's different re-export
after native import on the destination, with no native error. They also
observed that the first Ruilhenn import leaves the talent UI waiting for
Apply Changes. Thus a blanket level-based refusal is not established. The
different strings alone do not identify which nodes were adjusted; the
saved source is not rewritten or pruned by the addon.

Pinned Blizzard_ClassTalentsFrame.lua registers its config creation handlers
on OnShow and unregisters them on OnHide. OnTraitConfigCreateFinished calls
SetSelectedSavedConfigID with autoApply=true. An open native talent tab can
therefore select/stage a newly imported configuration independently of
Ruilhenn's batch. ConfigHasStagedChanges is a public read-only staged-state
check; it does not commit or discard anything.

Ruilhenn now refuses an import while PlayerSpellsFrame.TalentsFrame is shown
or the active config has staged changes, explains the required manual
resolution, and rechecks between requests/results. The browser disables
talent Load with the same reason while keeping inspection available. The
addon does not press Apply, discard drafts or activate a loadout. Completion
copy explicitly describes a saved, non-activated loadout. Four regression
cases cover an open editor, staged state after closing, editor opening during
a batch and the browser's disabled reason. Latest suite: 148 passing Lua 5.1
tests. Native closed-editor batch acceptance still requires a user retest.

Next: resolve existing native pending edits intentionally (apply or discard),
close the native talent window, then run Ruilhenn talent Load again. Existing
names stay unchanged. Inspect imported loadouts afterward and compare their
talent selections; do not assume a lower-level re-export must byte-match the
level-90 source. Report any remaining rejection from the closed-editor test.

## Staged-state guard correction

The closed-editor repeat reached "Waiting for creation" then the guard
reported a user draft, but opening the native editor showed no pending
changes. That guard conflated a post-request client flag with a pre-existing
user draft. It is not valid evidence of a visible Apply Changes operation.

The batch now confirms a matching populated saved result even when a staged
flag appears during its accepted request. Before another import, it waits
for the flag to clear using the existing bounded readiness checks. Persistent
flags stop further requests and emit neutral diagnostics, without pressing
Apply or calling rollback. Pre-existing staged state still blocks a new
restore, with wording that distinguishes the API flag from a visible draft.

`/ruil talents status` reads the active config's staged flag, editor visibility
and creation readiness, plus the last imported saved config's staged and
populated flags when available in this session. No export, selection or game
setting is changed by status. Tests cover transient post-import staging,
persistent staging with diagnostics, and confirming a final populated result.
Latest suite: 151 passing stock Lua 5.1 tests. Retest the closed-editor batch;
if it stops, provide both status lines before reloading. The exact runtime
source/duration of the staged flag remains unverified.

## Persistent active-config staging and guarded scratch cleanup

The next runtime report confirmed active config 58953232 remained staged,
while newly saved config 103752596 was populated and unstaged; the native
talent editor was closed and CanCreateNewConfig remained true. The bounded
wait alone did not resolve it. This establishes that the saved result and
active staged state must be handled separately; it does not grant permission
to roll back an arbitrary pre-existing draft.

Before sending an import, Ruilhenn now captures the active config ID and its
export only after verifying no staged changes exist. After confirming the
new saved config, any cleanup is conditional on all of the following:

- Same active config and spec, no combat and no native talent editor.
- New saved config is different from the active config, populated and unstaged.
- The active staged export exactly matches the actual newly saved export,
  rather than assuming it matches the higher-level source string.

Only in that context does Ruilhenn call the public
`C_Traits.RollbackConfig(activeID)` to remove this import's temporary staging.
It verifies the staged flag cleared, the original active export was restored,
and the new saved export stayed unchanged before continuing. There is no
commit or activation. A mismatch, rejection or failed verification stops the
batch with diagnostics; pre-existing drafts never reach import or rollback.
The earlier statement that no rollback is ever performed is superseded only
for this tightly checked import scratch state, not for the player's drafts.

Source: pinned SharedTraitsDocumentation.lua declares RollbackConfig(configID)
returning success, and native TalentFrameBase/ClassTalents rollback paths
use it for staged changes. Runtime operation and exact export equivalence
still need the user's next test. No retry or deletion of accepted saved
loadouts is introduced. The repeated GetConfigMap debug trace was removed.

157 stock Lua 5.1 tests pass, including original-active and saved-result
preservation, mismatched/unrelated staging, pre-existing drafts, missing
baseline, saved-result staging and rollback rejection. Next: `/reload`,
retry with the native talent window closed, and inspect whether multiple
missing loadouts complete while the originally active talents stay unchanged.
If cleanup refuses or fails, share both `/ruil talents status` lines before
reloading. Changes are local/uncommitted and game verification remains pending.

## Active/saved export comparison correction

The next report refused cleanup. Read-only exports for active config 58953232
and saved config 103752786 were both available and different. Thus comparing
the active and saved configurations for equality is not a valid universal
ownership test. It does not establish that the imported saved result is bad.

That particular criterion above is superseded: capture the clean active
baseline before the request, then capture the same active configuration's
staged export immediately on the accepted ImportLoadout call's return, before
another frame/user action can intervene. At saved-result confirmation, cleanup
requires the active export to still equal that request-boundary snapshot.
The saved export is checked independently for preservation across rollback;
it is allowed to differ from active scratch. Missing synchronous capture or
interleaved active changes still stop without rollback. Synchronous created
events defer confirmation until the request-boundary capture is complete.

Status now includes a specific cleanup reason code after refusal, distinguishing
missing synchronous snapshot, an interleaved export change, unavailable saved
export and other context changes. Three additional regression cases cover
different active/saved exports, delayed/unowned staging and synchronous
created-event handling. Latest suite: 160 stock Lua 5.1 tests pass. Native
operation with this correction still awaits the next closed-editor retest.

## Creation-callback continuation

The next user report confirmed scratch cleanup for `test dps` and successful
saved creation of `mm+ Templar`, followed by generic rejections for the two
remaining builds. This confirms improvement, not complete batch acceptance.
The later status had staged=false and canCreate=true; editor open=true at
status time does not prove it was open during the rejected requests.

Code inspection showed the next ImportLoadout was still sent directly from
TRAIT_CONFIG_CREATED/UPDATED processing, including after native rollback.
Continuation now uses a zero-delay C_Timer.NewTimer callback so that event
dispatch can finish first. Rejected requests also yield before moving to the
next build, rather than issuing several native calls in the same stack.
There is no automatic retry of accepted or rejected requests and no longer
arbitrary delay. Context guards are rechecked on the timer callback.

Two regression cases prohibit import re-entry during a config-created event
and verify combat/spec/editor changes between completion and continuation.
Rejected imports now include current staged/readiness/editor values in debug
output. Latest suite: 162 passing stock Lua 5.1 tests. Whether callback timing
fully explains the remaining native rejections is still a hypothesis requiring
the next runtime test. Existing successful named loadouts will be kept.

## Deferred-request retest

The user reported three existing names kept, `mm+ LightSmith` saved with
verified scratch cleanup, and the subsequent `Raid LightSmith` import rejected.
At rejection, active config 58953232 was unstaged, creation was allowed and
the native editor was closed. Last saved config 103752920 was populated and
unstaged. A zero-delay continuation therefore did not resolve the remaining
failure. Do not mark the batch restore passed or infer a documented throttle.

Requested discriminator: select `Raid LightSmith` and load it individually as
the first request, with the native editor closed. Success would point to a
batch/context issue; failure would require examining that particular build
and its native import result. Local installed ClassCodex and RaiderIO import
implementations were inspected read-only; neither establishes a verified
bulk-import cooldown to use here. No further timing workaround was added
while this test is pending. Automated result remains 162 passing tests.

## Individual-load button state

The user could not run the individual `Raid LightSmith` test because Load
selected talent stayed greyed out. Inspection found that browser Refresh
could capture the manager's busy state, while StopRestore did not update the
browser and selecting a talent row only changed the button caption. This
could leave a completed batch's disabled state cached in the UI.

Action-state refresh is now separate from content refresh. Talent manager
start/stop notifies it, and row selection recomputes current availability
without clearing the selection/export. Combat, exact class/spec, staged state,
native editor and actual manager-busy guards remain enforced, with a current
visible reason. Two tests cover end-of-restore enablement and selected-load
dispatch, and stale UI state versus real blocking conditions. The full suite
has 164 passing tests. Native individual-build diagnosis remains pending;
retry that test after reloading this UI fix.

## Native editor visibility correction

The user reported native-editor-open=true while the native window was
actually closed. The guard incorrectly used TalentsFrame:IsShown(), which
reports the child's own shown state even when PlayerSpellsFrame is hidden.
It now uses IsVisible(), accounting for hidden ancestors. Earlier true
diagnostics based on IsShown must not be treated as proof the user left the
window open. The user was correct to report this discrepancy.

The UI fixture now models effective parent visibility. A regression case
keeps the talent child shown, hides its parent, verifies Load is enabled,
then shows the parent and verifies the live guard disables Load. This restored
the user's ability to run an individual import test.

## Intermittent synchronous import rejection

The user subsequently reported that the same valid five-build batch needed
several complete manual retries: each attempt imported a different subset,
while native `ImportLoadout` synchronously rejected the remaining requests
even though `can create=true`, the editor was closed, and earlier requests had
completed with verified scratch cleanup. Repeating the batch eventually saved
all five; a later run kept all five unchanged. This demonstrates intermittent
rejection, but does not establish its underlying client cause.

The restore now retries only a synchronously rejected/throwing `ImportLoadout`
request, at most twice after the initial attempt, with one then two seconds of
delay. It retries the same build, rechecks current state before each attempt,
and reports the retry. It never retries an accepted asynchronous request, so
it cannot intentionally duplicate a pending loadout. Exhausted requests count
as failed and restoration proceeds. Regression tests cover transient recovery
and bounded exhaustion. Latest local suite: 166 Lua 5.1 tests pass; Retail
package validation passes. In-game confirmation of the retry behavior remains
pending.

### Session checkpoint — 2026-11-13

Resumption snapshot: branch `main` is at `3e5dfaa` and matches
`origin/main`; the worktree still contains the previously reported uncommitted
runtime, UI, localization, test and packaging changes. No UI task request or
new in-game result has appeared since the previous checkpoint.

The user's latest supplied run history confirms eventual completion after
several manual `/ruil talents load` attempts: attempts progressively saved the
missing builds, and later runs kept all five unchanged. Those logs do not show
the new automatic retry message, so they are evidence of eventual manual
recovery only; they do not verify the retry-enabled build or explain the
client's synchronous rejections. No cause is established.

Completed locally: direct native import lifecycle, saved-result verification
and guarded scratch cleanup, deferred request continuation, current Load-button
state refresh and effective native-editor visibility, plus bounded retries for
synchronous rejection. Recorded automated results remain 166 passing stock
Lua 5.1 tests and a passing Retail package check; neither check was rerun for
this checkpoint. The working tree is uncommitted and contains other authorized
UI, restoration, localization and test work; preserve it. `RETAIL-API-REVIEW.md`
is user-owned and untouched.

Outstanding: test the retry-enabled addon after `/reload` on the affected
character and confirm whether a rejected build logs a retry and then succeeds
or reaches the bounded failure summary. If it still fails, capture the full
retry/result sequence and current `/ruil talents status`; do not infer a
throttle or add more timing changes without that evidence. No task request or
implementation `response.md` exists for this follow-up; it remains tracked in
this feature record.
