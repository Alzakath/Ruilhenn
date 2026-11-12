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

This opt-in run adds desired-behavior tests for existing defects. It **exits
nonzero while those defects remain**; failures are not swallowed or counted
as passing tests. Move each case into the normal suite when its fix lands.

| Area | Reproduced defect |
| --- | --- |
| Untracked | EventManager debug toggle calls nonexistent `Log:Info` |
| Stock Lua 5.1 | Event delivery fails without `table.unpack` |

The normal event-dispatch test explicitly supplies a sandbox-local
`table.unpack = unpack` alias to isolate dispatch behavior. The stock Lua
case does not supply that alias. Neither result certifies whether the
installed WoW build supplies this extension. Frame naming/protection, secure
execution, contextual binding semantics, network responses, spell availability,
actual rendering, and persistence across game reload/logout are not simulated.

Local results (2026-11-12, Lua 5.1.5): **87 normal tests passed**; **2
known-defect tests failed** in their intended behavior paths. Those counts
include the existing #12 regression file as one aggregate test; it retains
its individual assertions. `git diff --check` passed. GitHub Actions has not
results for subsequent deliveries are recorded in `docs/RETAIL-COMPATIBILITY.md`.

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
The manager waits for a matching `TRAIT_CONFIG_CREATED(configInfo)` combat
configuration, validates it, imports, then moves on. State is copied from the
backup, events/timers are cleaned up, and no completion is announced while
waiting. A timed-out creation can still arrive from the server; the error
asks users to inspect their loadouts before retrying.

Contracts: Retail `SharedTraitsDocumentation.lua` event payload and
`ClassTalentsDocumentation.lua` request return at source pin
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
