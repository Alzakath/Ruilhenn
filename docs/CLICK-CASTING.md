# Native click-casting profiles (#5)

Target: Retail 12.1.5. Source pin, resolved 2026-11-12:
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783).

User authorization: implement and validate locally; commit and push approved
after successful partial-restore runtime testing. Issue closure has not been
requested. #14–#19 are closed. The user reported the final
Retail checks successful; their diagnostic matched build 70783/interface
120105/enUS with no missing APIs or unresolved template spell metadata.

| Requirement | Acceptance | State |
| --- | --- | --- |
| REQ-CC-1 | Save native profiles by class and stable spec ID, preserving type/action/button/modifiers | Implemented; round-trip/isolation/deep-copy tests pass |
| REQ-CC-2 | Restore a whole profile explicitly, including removing bindings absent from the backup | Implemented; nonempty/empty replacement and order-independent readback tests pass |
| REQ-CC-3 | Remap macro indices by name and account/character scope; resolve duplicate names by body or fail before writing | Implemented; reindexing, scope, duplicate, missing/ambiguous and legacy-identity tests pass |
| REQ-CC-4 | Reject combat, unavailable APIs/spec, missing backups and malformed records; skip unlearned spells with a warning and verify the remaining profile | Implemented; error-path, no-write and partial restore tests pass |
| REQ-CC-5 | Verify setter outcome by readback; report restrictions/errors or mismatch without claiming success | Implemented; nil-return, silently blocked, throwing, failed readback and modified-input tests pass |
| REQ-CC-6 | English base/French strings, slash help, TOC loading, regression and packaging checks | Implemented; 118 Lua 5.1 tests and 26-file release artifact checks pass; independent linguistic review not run |
| REQ-CC-7 | Verify actual addon write permission, click behavior and persistence in Retail | User-reported save/load PASS on 2026-11-12; individual click behavior and persistence scenarios not separately reported |

## Interface and scope

- `/ruil clicks save` captures Blizzard's current native click-casting profile.
- `/ruil clicks load` replaces the current native profile for the current
  class/spec with its saved backup. No automatic restore on spec change.
- `/ruil clicks status` re-reads the current native profile and shows differences
  for the last attempted restore, without writing bindings again. The restore
  diagnostic stores only native type/action/button/modifier records, not macro
  bodies. Save/load refuse to run while Blizzard's click-casting editor is open.
- There is no new toggle or configurable preference requiring an options
  control; these are explicit actions following the existing bars/bindings
  command model. No visible panel is added. Mock-up/controller navigation is
  not applicable; existing keyboard/gamepad bindings are preserved.
- This does not import private EllesmereUI/Clique/other addon settings or
  guarantee that their frames use native click casting.
- Backups live in `RuilhennDB.clickCasting[class][specID]` with a schema version.
  An empty saved profile is distinct from no saved profile. Save/load never
  create/edit macros or cast spells. Missing/ambiguous macros abort restore.
- Restoring replaces the whole native profile, so new native bindings absent
  from the saved backup are removed if the setter applies the profile.

## Evidence

[ClickBindings API](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ClickBindingsDocumentation.lua)
declares `GetProfileInfo() -> ClickBindingInfo[]` and
`SetProfileByInfo(infoVec)` with **no declared return**. The setter is marked
`HasRestrictions`; a successful pcall alone is not a permitted-operation pass.
[Binding records and enums](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ClickBindingsConstantsDocumentation.lua)
define type, actionID, button and modifiers; macro action IDs are indices.
[Blizzard's Save button](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_ClickBindingUI/Blizzard_ClickBindingUI.lua#L337)
uses the setter. This establishes intended semantics, not third-party addon
permission. No UI load-on-demand dependency is needed for the declared C API.

## Checkpoint

Implementation and automated checks are complete locally. Commit and push
are now authorized; issue closure has not been requested. The pre-existing untracked API review is
untouched. The user reported successful in-game save/load on 2026-11-12;
see the follow-up runtime report below for the scope of that evidence.

## Actual-client acceptance

1. On a backed-up/disposable profile, `/reload` and `/ruil validate`. Confirm
   the three click-binding APIs are present. Presence is not write permission.
2. Configure a simple native spell click binding, press Blizzard's Save and
   close its editor, then run `/ruil clicks save`.
3. Change that binding in Blizzard's click-casting UI, press its Save button
   and close the editor, then run `/ruil clicks load`. Reopen the window and
   confirm the original binding actually returns and the
   command reports a verified restore. Record errors/restrictions verbatim.
4. Repeat with spell modifiers, target/context-menu interactions and a macro
   that has moved to another index within its original scope. Missing macros
   must abort before changing the profile. Test actual clicks on supported
   unit frames; other addons may use their own binding system.
5. Confirm class/spec isolation, combat refusal, and persistence through reload,
   clean logout/login and restart. Test empty-profile restoration only on a
   disposable setup; the client may impose defaults, which readback must not
   silently treat as an exact match.

Basic save/load has a user-reported actual-client pass. A blocked setter must remain an
explicit unsupported restore result; do not bypass client restrictions or
substitute a successful pcall/API presence check for operation evidence.

## First runtime report

The user reported a successful 5-binding save followed by readback mismatch
errors. They then clarified that the native editor had an added binding and
was waiting for Save. The original test instructions omitted explicitly
committing native edits. Blizzard maintains a separate data provider and
`pendingChanges` state; its Save button applies that draft then hides the
window. The implementation now refuses to compete with an open editor and
offers targeted read-only status diagnostics. This is not yet evidence that
closing the editor resolves the mismatch; repeat the test and inspect any
reported differences. No automatic write retry or UI-draft modification is
performed.

## Follow-up runtime report (2026-11-12)

After the editor guard and revised test instructions, the user reported:
"Ok I tested in game click-casting save/load is working".
Record basic native click-casting save/load as USER-REPORTED PASS. The earlier
mismatch is no longer reported as an active blocker. Exact binding changes,
macro reindexing, empty profiles, class/spec isolation, combat refusal,
actual clicks and reload/logout/restart persistence were not separately
described in this report; do not infer individual passes for those scenarios.
Commit, push and issue closure remain unauthorized.

## Cross-character failure (2026-11-12)

The user subsequently tested another character and reported a failed restore:
10 desired bindings, 9 current, with the profile changed from before the
write. The only reported difference was `RightButton modifiers=12`, desired
`type=1 action=1044`, absent from the current profile. Cross-character
acceptance remains unresolved; the earlier basic pass does not cover this
case. Investigation is checking spell availability on the destination
character and whether Blizzard's editor can save the same binding manually.

The user confirmed that the destination character is level 80 and lacks
Blessing of Freedom due to missing talents, and requested partial restoration.
Load now checks spell records using `C_SpellBook.IsSpellInSpellBook(id,
Enum.SpellBookSpellBank.Player, false)`, matching the pinned native editor's
known-spell check. Unlearned spells produce an English/French warning listing
their IDs; the remaining profile is written and verified, including when no
bindings remain. Backups retain all original records. Status compares against
the applicable restore request. Missing macros and genuine read/write errors
retain their existing failure handling. No automatic retry is added.

Validation: 118 stock Lua 5.1 tests pass, including mixed/all-missing spell
profiles, warning localization, status, backup preservation, restoration after
learning the spell and spellbook API failures. The 26-file packaging check
passes.

### Partial restore runtime acceptance (2026-11-12)

USER-REPORTED PASS on the level-80 destination character. The user confirmed
the expected result and supplied the output: one unlearned spell binding
(1044) skipped with a warning that the backup is unchanged, followed by
"Restored and verified 9 native click-casting bindings."
This resolves the reported cross-character failure for missing talents.
Other individually unreported runtime scenarios remain unverified. The user
subsequently authorized commit and push. Issue closure has not been requested.
