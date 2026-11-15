# Ruilhenn

Ruilhenn is a World of Warcraft addon designed to streamline the management of your character's interface configuration. It provides tools to save, restore, and manage your action bars, key bindings, and macros, ensuring a consistent experience across specializations and sessions.

## Features

### 1. Action Bar Management
Never lose your spell placement again. Ruilhenn allows you to save your action bar layout (spells, items, and macros) specific to your current Class and Specialization.
- **Save**: Snapshots your current action bars.
- **Load**: Restores your action bars to the saved state for your current specialization.
- **Clear**: Quickly empty your action bars to start fresh.

### 2. Key Bindings Manager
Keep your control scheme intact.
- **Save**: Backs up your current key bindings.
- **Load**: Restores your key bindings from the saved profile.

### 3. Talent Manager
Share your builds across characters.
- **Save**: Saves all talent loadouts for your current specialization.
- **Load**: Imports saved talent loadouts to your current character (skips if a loadout with the same name exists).

### 4. Macro Management
Includes utilities to help generate and manage class-specific macros, reducing the manual effort of writing standard utility macros for every character.

### 5. Native Click-Casting Profiles
Save Blizzard's native click-casting bindings per class and specialization.
Restore the saved profile on another character of the same class/spec, with
macro indices resolved by name and account/character scope. Create the
referenced macros first; missing or ambiguous macros abort restoration.
Load replaces the entire native profile, including removing bindings absent
from the backup. Private settings belonging to other click-casting addons
are not included. Combat operations are refused, and restore success is
reported only after native readback matches. Restricted client writes may
be refused; check the reported error and current click-casting settings.
Spells not yet learned by the destination character are skipped with a
warning; the remaining bindings are restored and verified. The saved backup
keeps those spells so they can be restored after learning them.
Save or discard edits and close Blizzard's native click-casting window
before using these commands; reopening it refreshes its staged display.

## Usage

Type `/ruil` or `/ruilhenn` to access the addon.

### Template browser

`/ruil` (with no arguments) or `/ruil ui` opens the shared template browser.
You can also open it from **Settings → AddOns → Ruilhenn**.

The list shows only templates for your current character’s class. Select a
specialization, then Talents, Action bars, Key bindings or Click
casting. Inspect the saved contents and source before choosing **Save as
template** or **Load category**. Both actions ask for confirmation. Different
specializations can use different source characters: for example, Guardian
from one druid and Feral from another. Saving updates only the selected
category, and loading requires the matching active class/spec. Browsing
remains available during combat; save/load are disabled.

Overview shows how many of the four categories are saved and each category’s
own provenance. The active specialization is labeled separately from the
template being viewed. Click casting lists Input, Action and Availability,
with green/amber text statuses and available/skipped counts. Missing backups
offer a first-save action; saved-but-empty snapshots are identified separately.

Talent rows show whether a named loadout already exists. Select one to copy
its export or load it individually; otherwise Load imports all missing saved
loadouts without activating one. Action bar loading fills saved placements;
it does not clear empty saved slots. Click-casting loading replaces the native
profile and warns about skipped unlearned spells. Key-binding loading applies
saved keys to this character's own binding set and leaves character-specific
mode active, regardless of whether the source was saved from account or
character bindings. Assignments on imported keys may be reassigned; other
character keys are kept. Account bindings are not saved. **Copy account
bindings…** is a separate confirmed utility that replaces this character's set
with the actual current account bindings, removing character-only keys. It is a
one-time copy; later changes remain separate. The native key-binding editor
must be closed first. The legacy `/ruil bindings load` command keeps its
existing saved-scope behavior.

Action-bar restore skips missing macros, unlearned spells and unsupported
mount entries, keeps their current slots, and reports placed/skipped/failed
totals. Create any required named macros on the destination before retrying.
Talent imports wait for native creation/population; existing names stay
unchanged. Accepted imports are not retried automatically after a timeout.
Before importing, apply or discard pending edits in Blizzard’s talent window
and close that window. Its open editor can automatically select newly created
loadouts. Ruilhenn saves loadouts without activating them or resolving drafts
on the player’s behalf. An import can generate its own temporary staged
state. After the saved loadout is confirmed, Ruilhenn removes that scratch
state only when it still matches the active snapshot captured immediately
after the import call, with a clean config beforehand. It verifies the original active talents and new saved
loadout are preserved; uncertain cleanup stops the batch.

Each new save records its source character/realm and date. Existing backups
remain available with an unknown source until saved again. New key-binding
saves also create an independent class/spec snapshot; the old shared backup
remains available through `/ruil bindings load`. Unscoped backups are excluded
from the browser because their class/spec is unknown. Original slash save/load
commands remain usable.

When EllesmereUI and its third-party skinning component are enabled, the
browser uses the public Skinning API and follows the user's window theme.
Without it, a standalone window remains available. EUI can control Ruilhenn
skinning under Blizzard Skins+ → Window Skins → Third-Party Addons.

- `/ruil help` : List all available commands.
- `/ruil ui` : Open the shared class/spec template browser.
- `/ruil bars save` : Save action bars for the current spec.
- `/ruil bars load` : Restore action bars for the current spec.
- `/ruil bindings save` : Save current key bindings.
- `/ruil bindings load` : Restore saved key bindings.
- `/ruil clicks save` : Save native click-casting bindings for the current class/spec.
- `/ruil clicks load` : Replace the current native click-casting profile with its backup.
- `/ruil clicks status` : Show read-only differences for the last attempted restore.
- `/ruil talents save` : Save talent builds for the current spec.
- `/ruil talents load` : Import saved talent builds.
- `/ruil talents status` : Inspect client talent readiness and the last imported configuration without changing them.

## Why use Ruilhenn?

- **Multi-Spec Friendly**: Automatically handles different layouts for different specializations, so you don't have to manually drag spells around when switching roles.
- **Backup & Restore**: Acts as a safety net for your UI configuration. If your settings get reset or you move to a new PC, you can quickly restore your familiar setup.
- **Setup Speed**: Drastically reduces the time required to set up a new character or fix a broken UI.
