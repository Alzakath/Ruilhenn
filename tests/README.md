# Ruilhenn unit tests

Run from the addon root with stock **Lua 5.1**; no test dependencies or game
client are required:

```sh
lua tests/run.lua
```

The default suite includes the existing binding regression checks plus tests
for command parsing, configuration persistence, logging, task scheduling,
event subscriptions/dispatch, action snapshots and restoration, macro
creation/updates/templates, talent exports and guards, locale catalog
consistency, and addon loading through the actual TOC. GitHub Actions runs
this command on pushes to `main` and pull requests.

Each test loads production files in an isolated Lua environment. Minimal
WoW API mocks capture mutations without touching real bindings, macros,
talents or action bars. Frame updates are advanced explicitly, so deferred
execution, frame budgets and failures can be tested deterministically.
Tests are not included in the addon's TOC.

## Known defect reproductions

```sh
lua tests/run.lua --known-issues
```

All original known-defect reproductions now live in the normal regression
suites. This option is retained for compatibility and adds zero extra cases.
Event delivery uses stock Lua 5.1 `unpack` without an injected alias, and its
test preserves nil payload positions. Frame naming/protection, secure
execution, network delivery, actual rendering, spell availability and game
persistence are not certified by these mocks.

Local results (2026-11-13, Lua 5.1.5): **166 normal tests passed**, no remaining
opt-in defect cases, and `git diff --check` passed. The #12 file remains one
aggregate case containing its original assertions. Delivery and runtime
evidence are recorded in `docs/RETAIL-COMPATIBILITY.md`.

## Release and actual-client checks (#19)

```sh
python tools/package_release.py --check
python tools/package_release.py
```

The standard-library tool checks interface 120105, TOC references and exact
file-name case, initialization order, and SavedVariables metadata. It builds
and verifies a ZIP under `dist/` with exactly one `Ruilhenn/` root containing
the TOC-referenced runtime files and icon only. `.pkgmeta` excludes docs, tests,
tools, release notes and development metadata from the BigWigs release
workflow. The CI workflow runs the artifact check after the Lua suite.

`/ruil validate` records the actual client build/interface/locale, binding set,
macro limit, required API presence, fallback setting and unresolved template
spell metadata in `RuilhennDB.validation`. It does not modify bindings, bars,
macros, talents or CVars and explicitly does not mark feature tests passed.
Use `docs/RETAIL-VALIDATION.md` for the remaining actual-client checklist.

## Shared template browser

`TemplateBrowserTest.lua` covers legacy discovery without invented provenance,
current-class filtering and exact class/spec load compatibility, independent source characters and
binding snapshots, compatible/combat action dispatch, read-only missing-spell
inspection, lazy/late EUI skin registration, Settings discovery, explicit
confirmation, stale snapshots, spec/combat changes and selected talent export
and dispatch. `TalentAsyncTest.lua` also exercises the real manager's selected
loadout path through server creation and import events. `UIFixture.lua` is a
control/event harness only; it does not certify rendering, taint, controller
navigation or integration with the actual EUI engine. See
`docs/TEMPLATE-BROWSER.md` for pending in-game acceptance.

The handoff redesign adds state/interaction coverage for honest Overview
saved counts and independent provenance, first-save versus saved-empty
presentation, empty-profile load warnings, structured click fields and skip
summaries, active/selected spec distinction, neutral inactive availability,
unresolved-name placeholders and recycled icon/status/export cleanup. These
tests exercise controls and production presentation adapters, not pixels or
actual EUI rendering.

The hierarchy presentation pass adds derived all-present/mixed/all-available
talent summaries, inactive and empty handling, semantic font/accent roles
through late/theme skin updates, retained talent selection/export during a
theme refresh, and scrollbar show/hide state as content crosses the viewport.
It also checks row justification across Overview → Talents → Click casting
reuse, public scrollbar styling across early/late callbacks, and that enabled
EUI skinning fades only arrow-button textures while keeping
the buttons and thumb, and that disabled skinning preserves native arrow art.
These mocks do not verify label fit, native wheel/thumb input or actual EUI
scrollbar appearance.

Latest local result (2026-11-14, stock Lua 5.1.5):
`lua tests/run.lua` — **183 passed, 0 failed** after release diagnostic
cleanup.
The Retail package check passes with 26 runtime files; task-specific details are
in `docs/ui/tasks/2026-11-14-bindings-scope-01/response.md`.

## Native click-casting profiles (#5)

`ClickCastingTest.lua` plus the main slash-command integration case exercise
all supported record types/modifiers, class/spec isolation, empty and full
replacement, deep-copy persistence, macro reindexing/scope/ambiguity, missing
actions, malformed storage, combat, missing APIs and read/write restrictions.
The setter returns nil in the success mock, matching its declared contract;
native readback must match the original intended profile before success.
Mocks do not prove actual addon write permission. The source pin, requirement
matrix and pending live-client checks are in `docs/CLICK-CASTING.md`.

## Macro capacity (#15)

`MacroCapacityTest.lua` covers each of the 30 character slots, client-derived
limits, full storage with existing macros still editable, and rejected or
throwing create/edit calls. Errors have English/French catalog entries.
Current limits are source-verified in Retail's `MacroConstantsDocumentation.lua`
at commit `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`; in-game operation remains
separate from mocked regression coverage.

## Combat-safe clearing (#18)

`ActionBarClearTest.lua` verifies that combat requests do not touch slots,
cursor or pending restores; selected/all-bar clearing works; invalid bar
arguments are rejected before mutation; and blocked pickups are not counted
as cleared. The formerly missing invalid-bar message now has English/French
entries. Actual protected-operation behavior remains a client check in #19.

## Asynchronous item data (#17)

`ItemDataTest.lua` covers cached/deferred names, whole-batch waiting, duplicate
IDs/events, unrelated events, explicit failure, timeout, missing names,
throwing requests, combat/spec changes and superseded operations. Macros never
persist `UnknownItem`. Bars preflight the batch before placing any action.
The item pickup API is now `C_Item.PickupItem`; the legacy global is absent in
the fixture. Data loading uses `C_Item.RequestLoadItemDataByID` and the
`ITEM_DATA_LOAD_RESULT(itemID, success)` event, verified in Retail
`ItemDocumentation.lua` at the pinned source commit. Client cache timing and
actual protected operations remain untested here.

## Asynchronous talent restoration (#16)

`TalentAsyncTest.lua` covers multiple missing loadouts in order, duplicate
commands, unrelated/stale/duplicate server events, rejected and throwing
requests, combat/spec cancellation, timeout cleanup and late callbacks.
The manager calls native ImportLoadout with the active config as its decoding
source, then waits for a matching `TRAIT_CONFIG_CREATED(configInfo)` combat
configuration and populated state (`TRAIT_CONFIG_UPDATED` when necessary).
It does not pre-create an empty config. Existing names are kept unchanged;
shared-bar settings target the new ID only. Readiness waits send no import
until CanCreateNewConfig permits it. Events/timers are cleaned up; no import
completion is announced while waiting. Accepted requests are never retried
automatically, and a timed-out creation can still arrive from the server.
See `docs/RESTORE-FIXES.md` for the runtime report and pending client retest.

Native talent editor / pending Apply Changes guards also cover open-editor
refusal, staged changes remaining after closing, editor opening during a
batch, and a visible disabled Load reason while browsing/export remains usable.
The addon never commits or discards the player's staged edits automatically.
Import-generated scratch cleanup has separate guards: a clean pre-import
baseline, an active scratch export captured at the import-call boundary, and verified rollback preserving both
the original active export and newly saved result. Mismatches, unknown drafts,
failed rollback and altered post-cleanup exports stop without another import.
Active and saved exports may differ; the active export is compared with its
own request-boundary snapshot. Synchronous events defer confirmation until
that capture is ready; staged changes first appearing later are not assumed owned.
Further native import requests run from a deferred continuation, outside
creation/update/rollback event processing. Tests prohibit event-handler
re-entry and recheck context guards before the next request.

Contracts: Retail native ClassTalentImportExport/ClassTalentsFrame flow,
`SharedTraitsDocumentation.lua` events and `ClassTalentsDocumentation.lua` at source pin
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`. Native delivery and server timing
remain actual-client checks under #19.

## Retail API wrapper regression checks (#14)

Action bars now use `C_SpecializationInfo.GetSpecialization` and
`C_ActionBar.GetActionText`; talents use the namespaced specialization and
specialization-info functions. Every addon fixture omits the three deprecated
globals, so the full normal suite runs without those fallback wrappers.
`RetailAPITest.lua` adds explicit checks for spell/macro bar round trips,
macro names surviving changed macro indices, unavailable action text, and
talent save/import with a non-default specialization index and distinct spec
ID. The specialization-info mock preserves its tuple return contract.

Source evidence was rechecked on 2026-11-12 against live Retail commit
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783):
[specialization contracts](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpecializationInfoDocumentation.lua#L212),
[action-text contract](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ActionBarFrameDocumentation.lua#L244).
No new dependency, setting, visible UI, or localized message was introduced.

The #14 in-game checks remain not run for this change: on a backed-up test
profile with deprecated fallbacks disabled, reload and verify bar save/load
with a macro, then talent save/load on an existing matching loadout. Record
the client build and original fallback setting, and restore that setting
after testing. Unit mocks do not establish permitted operation in the game.
Delivery and automated validation are tracked in issue #14; actual-client
validation remains outstanding.

## Talent import regression checks (#13)

`TalentImportTest.lua` exercises a production decoder with independently
encoded bit streams. Coverage includes name/string argument order; granted,
partial, choice, hero-subtree and tiered-node ranks; export/save/import round
trips; zero-hash third-party strings; invalid alphabets and truncation; spec,
version and hash mismatches; invalid ranks/choices; trailing data; missing
node data; combat protection; API rejection details; and localized errors.
Invalid builds are rejected before creation, import, or shared-bar mutation.

The decoder uses C_Traits data and an addon-owned bit reader so it does not
load or manipulate the Blizzard talent UI. The TOC loads it before the
manager. No new user setting or interactive UI was introduced.

API and format evidence was rechecked on 2026-11-11 against live Retail
commit `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783):
[serialization and conversion](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_PlayerSpells/ClassTalents/Blizzard_ClassTalentImportExport.lua),
[base64 bit order and padding](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_SharedXMLBase/ExportUtil.lua),
[import contract](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ClassTalentsDocumentation.lua),
[trait lookups](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SharedTraitsDocumentation.lua).

In-game round trips and legal node combinations still need client validation;
the game remains responsible for rejecting combinations that violate talent
prerequisites. Asynchronous creation is covered by the #16 regression tests.
English/French messages have formatting coverage but no separate linguistic
or in-game review. On a disposable profile, save a build including hero and
choice talents, restore it, compare the resulting export, and verify that
invalid strings cause no loadout changes and that actual game errors appear.

## Binding backup regression checks

Issue: [#12](https://github.com/Alzakath/Ruilhenn/issues/12). Target: Retail.

Run from the addon root with a Lua 5.1 interpreter:

```sh
lua tests/BindingsManagerTest.lua
```

The test loads the production binding manager with mocked WoW APIs. It checks
two-key round trips, secondary-only and unbound commands, saved binding-set
selection, rejected and no-result assignments, incompatible backup rejection,
empty/missing backups, combat protection, and English/French error formatting
with an unknown-locale English fallback. No real bindings are modified.

New backups use `RuilhennDB.keyBindingsVersion = 1`. Unversioned backups cannot
recover the second key lost by the old return-value mapping, so loading them
is blocked before mutation. Configure the intended live bindings and run
`/ruil bindings save` to replace an old backup. Failed restores are not passed
to `SaveBindings`; successful assignments can still affect the current session.

API evidence was rechecked on 2026-11-11 against Retail source commit
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783):
[Blizzard keybindings implementation](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Keybindings.lua).
It confirms `GetBinding` return order and boolean failure handling for
`SetBinding`. No new API, settings option, or interactive UI was introduced.

Validated locally with stock Lua 5.1.5 and `git diff --check`. In-game checks,
saved binding persistence across reload/logout, contextual binding behavior,
and native error rendering remain untested. English/French text was exercised
in the mocked tests; it has not had separate linguistic or in-game review.

The template browser's binding-scope coverage uses separate saved account and
character maps plus an independently tracked active mode. It exercises all
source/active-set combinations, multiple-key capture, preserved account/source
data, read-only set inspection, exact account-to-character replacement,
cancellation, stale baseline, native-editor guard, rejected writes and save
failures. These mocks do not verify live client binding persistence or account
isolation; see `docs/ui/tasks/2026-11-14-bindings-scope-01/response.md` for API
evidence and remaining in-game checks.

Copy-account fixtures also model Retail binding contexts: identical keys in
different contexts remain independent during preview, live-state restoration,
exact character copy and readback; same-context collisions and failed context
lookups stop before writes. They exercise the declared/native-source call shape,
not the user's live contextual binding state.

Latest local result after context-aware copy support and release diagnostic
cleanup (2026-11-14, stock Lua 5.1.5): **183 tests passed, 0 failed**. The
Retail package check validates 26 files, interface 120105, TOC load order and
filename case.
