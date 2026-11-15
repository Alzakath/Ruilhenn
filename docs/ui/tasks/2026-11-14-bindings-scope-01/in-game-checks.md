# In-game verification — bindings scope

Task: `2026-11-14-bindings-scope-01`. Results: **NOT RUN** by reviewer.
Latest user result: **Copy preparation FAIL** with the generic binding-set read
error; see review.md. Pause confirmed copy/import tests until diagnosis. The user
also established Quick Keybind disables chat and closes Ruilhenn; skip simultaneous
Quick Keybind testing rather than forcing both windows visible.
Use the current corrected build after B01/B02 in review.md are addressed. Guard
and visual checks can begin earlier, but never confirm a mutation with a native
editor open. Do not use `/ruil bindings load`: that legacy command intentionally
retains the old saved-scope behavior and is outside this character-only test.

## Preparation

1. With WoW closed, preserve a copy of WTF (account/character binding files and
   Ruilhenn SavedVariables), then use a disposable/test character or setup you
   can restore. Saving Key bindings in Ruilhenn replaces that class/spec's shared
   snapshot, so do not overwrite an important source template just for this test.
2. Log in, choose the matching active spec, `/reload`, and record locale, build,
   UI scale and EUI state. In Blizzard's keybinding settings record account
   assignments for several familiar keys and any second assignments. Make no
   changes to the account set. Record whether character-specific bindings were
   initially enabled. `/dump GetCurrentBindingSet()` is read-only: 1=account,
   2=character. Use it after closing native settings when checking resulting mode.

## Guards first

3. Open Ruilhenn → Key bindings and Blizzard's normal keybinding settings.
   Refresh Ruilhenn if necessary. Save, Load and Copy should be disabled/refused
   with a close-editor reason. Repeat for native Quick Keybind mode, especially
   when entered before the normal bindings page was opened. Do not confirm an
   operation if an action remains available; report the guard failure instead.
   Close native settings/editor and Refresh: the reason must clear. This checks
   both actual editor detection and avoiding a stale hidden-child block.
4. Browse an inactive saved spec: no import/copy allowed. Return to active spec.
   Check combat disablement when practical, without setting up a risky encounter.
   A pending confirmation must close or refuse after spec/combat changes.

## Account copy: cancel, execute and isolate

5. In Blizzard settings enable character-specific bindings. Pick a nonessential
   key/chord after verifying it is unused in the account map. Give it a harmless
   character-only action, and optionally change a second harmless assignment so
   character/account sets are visibly different. Commit native edits and close
   the editor. Record these test keys and original assignments.
6. Open **Copy account bindings…**. Check confirmation names this character,
   says it replaces its set/removes character-only customizations, preserves
   account bindings and keeps future edits character-specific. Cancel. Check
   character mode and both sentinel assignments are unchanged. Browsing and
   Refresh must also leave them unchanged.
7. Open Copy again and confirm with the native editor closed. Check the success
   output, inspect the character-specific checkbox/mode, and compare assignments
   with the recorded account baseline. The character-only key must disappear;
   changed assignments and second keys must match account values. This should
   work even with no saved template (if such a state is already available).
8. Make one harmless character-only edit again, commit and close settings, then
   inspect account bindings through native settings without editing them. They
   must match the original account baseline. Return to character mode and verify
   the separate character edit remains. Do not edit account bindings to create
   a test discriminator. `/reload` and confirm character mode and edits persist.

## Template import: merge instead of exact copy

9. Prefer an existing disposable template. If preparing one, use a backed-up
   class/spec snapshot: in character mode assign two unused test chords to a
   harmless command, close native settings, and Save current key bindings in
   Ruilhenn with confirmation. This changes the shared snapshot; record its source.
   Then use native settings to change/reassign those chords and add a third
   character-only key that was absent from the template. Commit and close.
10. In Ruilhenn, inspect **Import destination: This character only** and source
    scope/identity. Open Load, cancel, and verify all three test keys and mode
    unchanged. Open Load again and confirm: both captured keys must return,
    their conflicting assignments must move as described, and the third unrelated
    character-only key must remain. Unlike Copy, this action merges saved keys.
11. Inspect account bindings without editing: baseline must remain unchanged.
    Return to character mode; `/reload` and verify imported keys persisted.
    Repeat with account mode initially active, and with an account-scoped source
    snapshot if one is already available safely. Each browser import must finish
    in character mode regardless of source scope. Do not overwrite valued shared
    templates solely to complete every combination; mark unavailable cases NOT RUN.

## Visual evidence and reporting

12. Capture Key bindings normal view, Copy confirmation and Load confirmation.
    Include missing-template view if available; check text/button fit and separation
    from footer. Repeat in French/smaller scale and standalone if available.
    Report pass/fail separately for: guards, Cancel, exact Copy, import merge,
    account preservation, character-mode persistence and visual fit. Include exact
    chat/errors and sentinel values before/after. A screenshot alone cannot prove
    every account assignment is unchanged; fixture tests provide the full-map
    comparison, while this checks actual-client behavior on recorded keys.

Stop if unexpected scope changes, binding loss or uncertain-restore messages
appear. Record mode, test key assignments and full output before retrying or
reloading. Do not try to repair the shared account set by importing the template.
