# Implementation report — 2026-11-14-bindings-scope-01

Status: **Implemented locally; automated checks pass; in-game verification pending.**

## Implementation

- Browser Key bindings imports route through `BindingsManager:Load(profile, 2)`.
  They load the saved character set, merge captured key assignments, verify the
  resulting map, persist only set 2, and verify its saved readback. Source
  `bindingSet` remains unchanged as provenance. The legacy slash command still
  calls `Load(profile)` with no destination and retains its previous scope path.
- The Key bindings content area shows **Copy account bindings…** independently
  of whether a template exists. Its confirmation states that it exactly replaces
  this character's set, removes character-only keys, leaves account bindings
  unchanged and keeps later changes isolated. Cancel is mutation-free.
- `ReadBindingSetPreservingLiveState` inspects either saved set by loading it,
  capturing the map, then reloading and restoring the exact previous live map.
  It never calls `SaveBindings`. Confirmation stores a fingerprint of the
  reviewed account map; acceptance checks context and rereads the baseline.
  Copy saves and validates only the character set, then rereads the account set
  to check it remains identical.
- Browser mutations are disabled/refused in combat, while the native keybinding
  editor is open, if binding APIs are unavailable, or when current class/spec,
  character, selection or reviewed account baseline has gone stale. Error paths
  attempt to restore the original live map and report uncertainty honestly.
- Added English/French strings, separate account/character-set fixtures and
  coverage for source/active-set combinations, read-only preview, exact copy,
  cancellation, stale baseline, editor guard, rejected writes, failed set reads
  and persistence failure. Updated Readme and the feature record.

Changed files for this task:

- `BindingsManager.lua`
- `TemplateStore.lua`
- `TemplateBrowser.lua`
- `l10n/enUS.lua`, `l10n/frFR.lua`
- `tests/AddonFixture.lua`, `tests/TemplateBrowserTest.lua`, `tests/README.md`
- `Readme.md`, `docs/TEMPLATE-BROWSER.md`
- this report

## Native API evidence and limits

The runtime model used here is: `LoadBindings(1)` reads the saved account map
into the live binding table; `LoadBindings(2)` reads the saved character map;
`GetBinding(index, true)` reads current assignments; `SetBinding(key, nil)`
unbinds a key and `SetBinding(key, command)` assigns it; `SaveBindings(2)` writes
the live map to the character set and selects it. `GetCurrentBindingSet()` reports
which saved scope is active based on the last save. Thus loading a different set
is a temporary live-map change; it is not a persistence operation. Account
baseline inspection is implemented as a read/restore transaction and performs
no save.

Evidence: Blizzard's Retail keybindings FrameXML resets with
`LoadBindings(Enum.BindingSet.Default)` followed by
`SaveBindings(GetCurrentBindingSet())`, commits edits with
`SaveBindings(GetCurrentBindingSet())`, and clears assignments with
`SetBinding(key, nil)`. See the pinned
[Blizzard keybindings source](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Keybindings.lua).
The public API references document the set numbers and return semantics for
[`LoadBindings`](https://warcraft.wiki.gg/wiki/API%3ALoadBindings),
[`GetCurrentBindingSet`](https://warcraft.wiki.gg/wiki/API_GetCurrentBindingSet),
[`GetBinding`](https://warcraft.wiki.gg/wiki/API%3AGetBinding),
[`SetBinding`](https://warcraft.wiki.gg/wiki/API_SetBinding) and
[`SaveBindings`](https://warcraft.wiki.gg/wiki/API_SaveBindings). The project's
pinned generated Retail declaration ledger does not include these legacy global
functions, so it does not independently establish their signatures. FrameXML
and API documentation agree on the read/load/mutate/save model; actual behavior
and account isolation still require the live-client checks below.

`pcall` is treated only as exception containment: successful completion is not
reported until live assignment readback and active-set checks match. The
character copy also rereads the account baseline after saving. The client does
not provide an atomic transaction across the two saved sets; if a native API
fails partway through, the addon attempts restoration and warns if state cannot
be verified. Blizzard's editor guard checks the exposed `KeyBindingFrame` and
`QuickKeybindFrame` visibility; the exact Retail editor lifecycle needs client
confirmation.

## Checks

- `lua tests/run.lua` — **PASS**, 181 tests, 0 failures.
- `python tools/package_release.py --check` — **PASS**, Retail artifact has 28
  files; interface version, TOC load order and case checks pass.
- `git diff --check` — **PASS**. Git printed existing LF-to-CRLF working-copy
  advisories for modified files; no whitespace errors were reported.
- No commit or push. Implementation is an uncommitted worktree change on top
  of source revision `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`; many unrelated
  pre-existing uncommitted files were preserved.

## Remaining in-game verification

On a controlled setup with account bindings recorded first:

1. Start in account mode and character mode in turn. Import a template saved
   from each source scope; confirm the character set receives the saved keys,
   account assignments stay unchanged, and the browser leaves character mode
   active. Confirm conflicting imported keys move as described.
2. In missing-template and saved-empty states, open **Copy account bindings…**.
   Cancel and verify no changes. Confirm it, verify exact account-to-character
   equality including removal of a character-only key, and verify account keys
   did not change. Make a later character edit and confirm account scope remains
   separate.
3. Reload the UI or relog and verify the character copy/import persists.
   Confirm `/ruil bindings load` still follows the old saved-scope behavior.
4. Open Blizzard's keybinding editor and verify save/import/copy are refused
   without changing its pending edits. Also verify combat and stale-confirmation
   feedback.
5. Review normal and confirmation views in English and French, with saved,
   missing and empty template states, and at reduced UI scale. Check footer
   anchors, notice placement, keyboard/controller-cursor reachability and EUI/
   standalone skinning.

The Lua fixtures do not simulate the real client's binding editor, account
storage, key conflicts across contextual bindings, persistence, taint or visual
layout. These remain **NOT RUN** in game.

## Resumption checkpoint — 2026-11-14

Completed: character-only browser import, exact account-to-character copy,
confirmation/context guards, English/French strings, independent binding-set
fixtures, developer documentation and the checks above. The working tree still
contains many unrelated uncommitted changes; none were discarded and nothing
was committed.

Outstanding: no product decision is blocking. The main technical question for
live verification is whether the exposed `KeyBindingFrame`/`QuickKeybindFrame`
visibility checks reliably detect the current Retail keybinding editor. Real
client account preservation, binding persistence, contextual key conflicts and
localized visual fit are also unverified.

Next action: perform the controlled in-game checklist above with account
bindings recorded beforehand, then update this report and `TEMPLATE-BROWSER.md`
with observed results. Until then, treat account isolation and editor refusal
as mock/API-backed implementation behavior, not as client-verified outcomes.

## Copy-read failure investigation — 2026-11-14

### Confirmed prerequisites and path

The copy action requires: the browser's Key bindings category; the currently
selected class/spec matching the player's active class/spec; out of combat; the
native keybinding editor not detected as open; the legacy binding APIs present;
and `GetCurrentBindingSet()` returning 1 or 2. It does **not** require a saved
binding template, a character-scoped source template, or character-specific mode
to be enabled beforehand. Source provenance is not consulted by the copy path.
The user may start from account or character mode; success saves the copied map
to the character set.

The capture's Copy button was enabled, then its click displayed the exact
`UI_BINDING_READ_FAILED` string in the inline notice instead of opening the
confirmation. In code, `ConfirmAccountBindingsCopy()` can produce that message
only after its category/compatibility/combat checks pass, the manager's
`OperationBlockReason()` returns no blocker, and
`ReadBindingSetPreservingLiveState(ACCOUNT_BINDINGS)` returns that error.
Thus this is a failure in Ruilhenn's pre-confirmation baseline read/capture
path, not evidence that a saved template or character mode was missing. The
screen does not show an editor/combat/API-unavailable prerequisite message.
The screenshot and current code cannot establish whether the native editor was
actually closed, because detection itself is still an unverified client check.

### Exact cause and limits

The exact failing substage is **not identifiable from the captured message**.
`UI_BINDING_READ_FAILED` currently conflates:

- failure to snapshot the current live map before loading anything;
- an exception from `LoadBindings(1)` (if restoration succeeds afterward);
- failure to enumerate the loaded account map; or
- an invalid/duplicate-key result rejected by `captureBindings()`.

The last case is concrete code behavior: `captureBindings()` rejects a key
reported for two different commands. It also treats `GetNumBindings` errors or
invalid counts, `GetBinding` exceptions, and non-string command values as the
same generic read error. This could explain the screenshot, but no returned
rows, duplicate-key evidence, or stage marker was captured; it is therefore a
hypothesis, not the confirmed cause. The user-visible “No saved binding set was
written” clause is true for this pre-confirmation path, but does not tell the
player what failed or what setup to change.

The guarded read path itself never calls `SaveBindings`. If the initial live-map
snapshot fails, no temporary set load has started. If the account load or
account capture fails and this generic error is returned, the code attempts to
reload the prior set and reapply/verify the captured live map; when that restore
fails it returns the distinct `UI_BINDING_STATE_RESTORE_FAILED` message instead.
This is the code's stated recovery path, not proof that Retail observers saw no
transient `UPDATE_BINDINGS` events or that the client's live state was unaffected.
No account or live binding mutation was performed for this investigation.

`captureBindings()` calls `GetBinding(index, true)`, packs all return positions,
and treats positions 3 onward as key strings, consistent with the legacy
`command, category, ...key` return shape recorded in the earlier API evidence.
The pinned local declaration set does not document these legacy globals, and
the available primary FrameXML examples do not define the global's complete
Retail return contract or contextual-binding behavior. It is not established
whether same-key/different-command rows are possible in the affected client.
`loadSet()` only treats a Lua exception as failure; no pinned local declaration
proves whether `LoadBindings` has a meaningful return value. Do not reinterpret
either behavior without client/source evidence.

### Why the action looked unexplained

The button is intentionally enabled without template data, but the Key bindings
detail currently describes only template import effects. It does not state that
Copy is a current-character utility, that either saved binding mode is accepted,
or that the editor must be closed. If preparation fails, the generic inline
read error replaces that context. This is a copy-prerequisite/help-copy gap
combined with a distinct internal baseline-read failure; telling the user only
to close the editor would misdiagnose this capture.

### Bounded correction proposal at investigation time

1. Add concise localized helper copy adjacent to Copy, visible with and without
   a saved template. Proposed English: “Requires the active specialization,
   out of combat, with Blizzard’s keybinding editor closed. No saved template
   is needed; works from either binding mode.” Proposed French: “Nécessite la
   spécialisation active, hors combat et l’éditeur de raccourcis Blizzard fermé.
   Aucun modèle n’est requis ; fonctionne dans les deux modes.” Keep current
   compatibility/combat/editor disabled reasons distinct.
2. Replace the generic copy-preparation text with an honest stage-neutral
   message. Proposed English: “Couldn’t read the account bindings, so Copy
   wasn’t started. No saved binding set was written. If this repeats, report
   this message.” Proposed French: “Impossible de lire les raccourcis du compte ;
   la copie n’a pas démarré. Aucun jeu sauvegardé n’a été écrit. Si le problème
   persiste, signalez ce message.” Do not tell users to change binding mode or
   create a template.
3. If a retest is needed, add one compact, temporary internal failure-stage
   discriminator at the manager's existing return points (initial snapshot,
   account load, account enumeration, live-state restore), with a reason such as
   API exception, invalid result or duplicate key. Do not dump binding rows or
   key contents. First reproduce the read failure with the editor closed and
   with both initial modes where already safe; use the discriminator to decide
   whether any algorithm change is justified. Remove temporary diagnostics once
   identified, and retain distinct user-facing prerequisite and restore-failure
   messages.

At the time of that investigation, no runtime, localization, test or saved-data
change had been made. The bounded diagnostic follow-up below implements the
proposed stage discriminator and localized clarity copy without changing copy
semantics.

### Targeted diagnostic follow-up — 2026-11-14

Added a third, non-user-facing stage result to the baseline reader. The stages
are `live-snapshot`, `account-load`, `account-map-read`, `duplicate-key`, and
`live-state-restore`; read subreasons are limited to stable labels such as
`binding-count-exception`, `binding-row-invalid`, and `duplicate-key`. The
browser writes one compact line through the existing debug logger only when the
preflight fails. It includes no key names, binding rows or account contents and
adds no logging level. Turn on the existing debug mode with `/ruil debug` before
a safe retest; turn it off afterward with the same command.

The user-facing failure now says that the account bindings could not be read,
Copy did not start and no saved set was written. A localized helper says no
template is needed and either binding mode works. Combat, compatibility and
editor blockers continue to use their own existing actionable notices. English
and French catalogs remain key/placeholder matched.

The fixtures now inject count-read, row-read, account-load, duplicate-key and
restore failures. They assert the returned stage, no saved-set writes, and
original live map/mode restoration when the injected API permits restoration.
The restore-failure fixture confirms a distinct failure result and no persisted
account or character writes; by design, when the simulated native restore call
itself fails, the test cannot assert the live map was restored. That remains an
honest uncertain-state case, not a successful copy.

At the time this diagnostic was added, the captured user's exact inner failure
remained **unconfirmed** until a retest produced the new stage line. In
particular, duplicate-key rejection was only a candidate then. `loadSet` still treats a thrown
`LoadBindings` call as failure; this diagnostic cannot identify a client that
silently rejects the call without throwing. No primary source or local pinned
declaration found here establishes a meaningful `LoadBindings` return value.
Do not bypass this uncertainty or proceed to Copy confirmation if restoration
fails.

#### Follow-up checks

- `lua tests/run.lua` — **PASS**, 183 tests, 0 failures, using stock Lua 5.1.5.
- `python tools/package_release.py --check` — **PASS**, 28 files, interface
  120105, TOC load order and filename case valid.
- `git diff --check` — **PASS**; Git emitted existing LF-to-CRLF working-copy
  notices only.
- No in-game retest was performed; no binding set was loaded or saved by this
  development step. No commit or push.

### User retest result — duplicate key during live snapshot

The supplied debug line is `Copy account bindings preflight failed at
live-snapshot:duplicate-key.` This identifies the rejection stage: before the
account set is loaded and before Copy confirmation. `captureBindings()` found
one key string associated with different commands in the initial live
`GetBinding(index, true)` enumeration. The operation returned immediately, so
Ruilhenn did not reach `LoadBindings(1)`, `SetBinding` or `SaveBindings` in this
attempt. This is an internal snapshot-model rejection, not missing user setup;
there was no account or character saved-set write from this click.

The reason code does not establish why the client exposed that duplicate. It
could represent distinct binding contexts that the current flat key map cannot
distinguish, or a genuine same-context collision / unexpected legacy API
result. No key or command values were logged, and no client build or native
binding dump was supplied, so that distinction remains unknown. Do not remove
the duplicate guard or deduplicate silently: either could cause Copy to lose or
misapply bindings.

### Bounded correction proposal

Before changing copy behavior, add a minimal discriminator to the same safe
preflight log: whether the two rows resolve to distinct binding contexts, the
same context, or unknown context. Do not log key strings, command names or full
rows. If the current Retail client exposes action binding contexts, a bounded
copy-only follow-up can snapshot and apply keys by `(context, key)` while
preserving the existing saved-data schema and legacy slash behavior. Fail
closed if context cannot be resolved or faithfully restored. If rows resolve
to the same context, retain the rejection and investigate the client result;
do not invent overwrite precedence. No runtime correction is authorized or
implemented by this report.

The helper and error wording from the diagnostic follow-up remain appropriate:
the feature requires no saved template and this error says the account map
could not be read, so Copy did not start and no saved set was written. It should
not suggest changing binding mode or creating a template. The preflight failure
is nevertheless an internal limitation to report if it repeats.

This user-provided log is not a complete in-game safety check: it confirms the
failure occurred before Copy could mutate saved sets, but does not independently
show current binding assignments or whether the native editor was closed.
Further testing should stop before confirmation until the context discriminator
is available. B01/B02 remain open: optional Quick Keybind guard coverage and
source character identity in template-load confirmation.

### Accepted context-aware copy correction — 2026-11-14

The user accepted the bounded proposal. Account-set preview, live-state
preservation, character-copy application and post-save verification now use a
Retail context-aware snapshot keyed by `(binding context, key)`. The action's
context is obtained with `C_KeyBindings.GetBindingContextForAction`; keys are
cleared and applied with that context as the third argument to `SetBinding`.
The context is included in fingerprints, so identical keys in separate contexts
remain distinct through stale-baseline checks and readback verification. If
context lookup throws or the API is unavailable, preflight fails closed. Two
different commands using one key in the same context are still rejected; no
winner is chosen. No binding context was added to SavedVariables.

This mode is restricted to `ReadBindingSetPreservingLiveState` and
`CopyAccountBindings`. Browser template snapshots/imports keep their existing
flat schema, merge behavior and manager route. The legacy `/ruil bindings load`
path is unchanged. English/French user messages did not need new strings: the
existing read failure remains appropriate for an internal context-read error,
and the Copy helper/prerequisite wording remains unchanged.

Retail API evidence was checked at source commit
[`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`](https://github.com/Gethe/wow-ui-source/tree/297d7aaaa736f346b3e036f38ee088eaf7f8c07f)
(source snapshot for interface 120105): the generated declaration makes
`GetBindingContextForAction(action)` return a nullable `BindingContext`
([declaration](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/KeyBindingsDocumentation.lua#L46-L59)).
Blizzard's Settings keybinding listener passes this result to `GetBindingKey`
and passes it as the third `SetBinding` argument for clearing and applying
([native use](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Keybindings.lua#L95-L100),
[context-aware clear/set](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Keybindings.lua#L115-L130)).
This supports the implementation contract but is not proof that the user's
specific duplicate rows resolve to distinct contexts on their client.

Added regression coverage for the reported shape: the same key in two
different contexts survives read-only preview, live-map restoration, exact
character copy and verification. Same-context/different-command collisions
continue to fail, and a context lookup exception stops before set loading or
writes. Existing account/character isolation, cancellation, stale baseline,
failed writes and legacy template-import coverage remains in place.

#### Checks and remaining in-game verification

- `lua tests/run.lua` — **PASS**, 184 tests, 0 failures, stock Lua 5.1.5.
- `python tools/package_release.py --check` — **PASS**, 28 files, interface
  120105, TOC load order and filename case valid.
- `git diff --check` — **PASS**; Git emitted existing LF-to-CRLF working-copy
  notices only.
- Not verified in game: duplicate rows resolving to distinct contexts on the
  user's client, native `SetBinding` context behavior for account-to-character
  copy, preserved unsaved live assignments/mode, account isolation, destination
  persistence across reload, or editor-guard behavior. Do not test by accepting
  a copy until a backed-up controlled setup is available. The log identified a
  duplicate key at live snapshot, but did not report current mode/editor state.
- B01/B02 remain open: optional Quick Keybind guard coverage and source
  character identity in template-load confirmation.

Implementation remains local and uncommitted; no push was made.
